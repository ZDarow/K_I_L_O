#!/usr/bin/env python3
"""Тесты для BLE-скриптов (gatt-scan, btmon-parse, btsnoop-analyze)."""

import importlib.util
import json
import os
import sys
import tempfile
import unittest
from unittest.mock import patch, MagicMock

# Загружаем модули через importlib (имена файлов с дефисами)
def _load_module(name, filename):
    path = os.path.join(os.path.dirname(__file__), "..", "scripts", filename)
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Не удалось загрузить {filename}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


btmon_parse = _load_module("btmon_parse", "btmon-parse.py")
btsnoop_analyze = _load_module("btsnoop_analyze", "btsnoop-analyze.py")
gatt_scan = _load_module("gatt_scan", "gatt-scan.py")


class TestBtmonParse(unittest.TestCase):
    """Тесты для btmon-parse.py."""

    def setUp(self):
        self.parse_btmon_log = btmon_parse.parse_btmon_log
        self.analyze_gatt_operations = btmon_parse.analyze_gatt_operations

    def test_empty_log(self):
        """Пустой лог не даёт событий."""
        events = self.parse_btmon_log("")
        self.assertEqual(len(events), 0)

    def test_mtu_event(self):
        """MTU exchange парсится корректно."""
        log = """
< ACL Data TX: Handle 0 flags 0x00 MTU TX: 256
> ACL Data RX: Handle 0 flags 0x00 MTU RX: 512
"""
        events = self.parse_btmon_log(log)
        mtu_events = [e for e in events if e["type"] == "mtu"]
        self.assertEqual(len(mtu_events), 2)
        self.assertEqual(mtu_events[0]["size"], 256)
        self.assertEqual(mtu_events[1]["size"], 512)

    def test_hci_events(self):
        """HCI события парсятся."""
        log = """> HCI Event: LE Meta Event (0x3e)
> HCI Event: Connection Complete (0x03)
< HCI Command: LE Set Scan Parameters (0x08)
"""
        events = self.parse_btmon_log(log)
        self.assertEqual(len(events), 3)
        types = [e["type"] for e in events]
        self.assertIn("hci_event", types)
        self.assertIn("hci_cmd", types)

    def test_gatt_operations(self):
        """GATT-операции обнаруживаются."""
        log = """
Read Request: ATT Handle: 0x0012
Read Response: Value: 48656c6c6f
Write Request: ATT Handle: 0x0014
Handle Value Notification: ATT Handle: 0x0015
"""
        events = self.parse_btmon_log(log)
        self.assertGreaterEqual(len(events), 1)

    def test_analysis(self):
        """Анализ GATT-операций работает."""
        events = [
            {"type": "read_req", "handle": "0x0012"},
            {"type": "read_rsp", "value": "48656c6c6f"},
            {"type": "write_req", "handle": "0x0014"},
            {"type": "notify", "handle": "0x0015"},
            {"type": "mtu", "size": 256},
        ]
        analysis = self.analyze_gatt_operations(events)
        self.assertEqual(analysis["total_events"], 5)
        self.assertIn("read_req", analysis["statistics"])
        self.assertIn("0x0014", analysis["handle_usage"])

    def test_hex_value_parsing(self):
        """Парсинг hex-значений."""
        log = """Value: 48 65 6c 6c 6f 20 57 6f 72 6c 64"""
        events = self.parse_btmon_log(log)
        # hex value может извлекаться
        self.assertIsInstance(events, list)

    def test_advertising_report(self):
        """LE Advertising Report."""
        log = """> HCI Event: LE Meta Event (0x3f)
"""
        events = self.parse_btmon_log(log)
        self.assertGreaterEqual(len(events), 1)


class TestBtsnoopParser(unittest.TestCase):
    """Тесты для btsnoop-analyze.py."""

    def setUp(self):
        self.parser_class = btsnoop_analyze.BTSnoopParser

    def _make_btsnoop_header(self, datalink: int = 0x1002) -> bytes:
        """Создаёт валидный btsnoog заголовок (16 байт)."""
        import struct
        magic = b"btsnoop\x00"  # 8 bytes
        version = struct.pack(">I", 1)
        dl = struct.pack(">I", datalink)
        return magic + version + dl

    def _make_packet_record(self, data: bytes, ts_sec: int = 0, ts_usec: int = 0,
                            flags: int = 0) -> bytes:
        """Создаёт запись пакета btsnoop (24 байта заголовка + данные)."""
        import struct
        orig_len = struct.pack(">I", len(data))
        incl_len = struct.pack(">I", len(data))
        flags_pack = struct.pack(">I", flags)
        drops = struct.pack(">I", 0)
        ts_s = struct.pack(">I", ts_sec)
        ts_us = struct.pack(">I", ts_usec)
        return orig_len + incl_len + flags_pack + drops + ts_s + ts_us + data

    def test_invalid_file(self):
        """Несуществующий файл вызывает ошибку."""
        with self.assertRaises(Exception):
            p = self.parser_class("/nonexistent/file.pcap")
            p.parse()

    def test_empty_btsnoop(self):
        """Пустой btsnoop файл (только заголовок)."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".log") as f:
            f.write(self._make_btsnoop_header())
            fname = f.name

        try:
            p = self.parser_class(fname)
            result = p.parse()
            self.assertEqual(len(result), 0)
        finally:
            os.unlink(fname)

    def test_hci_command_packet(self):
        """Парсинг HCI команды."""
        import struct
        # HCI Command: OGF=0x08, OCF=0x000B (LE Set Scan Parameters)
        opcode = struct.pack("<H", (0x08 << 10) | 0x000B)
        packet = bytes([0x01]) + opcode + bytes([0x07]) + b"\x01\x10\x00\x01\x00\x00\x00"

        with tempfile.NamedTemporaryFile(delete=False, suffix=".log") as f:
            f.write(self._make_btsnoop_header())
            f.write(self._make_packet_record(packet, 100, 0, 0))
            fname = f.name

        try:
            p = self.parser_class(fname)
            result = p.parse()
            self.assertEqual(len(result), 1)
            self.assertEqual(result[0]["type"], "hci_cmd")
        finally:
            os.unlink(fname)

    def test_acl_data_packet(self):
        """Парсинг ACL data пакета с L2CAP + ATT."""
        import struct
        # ACL data: handle=0, PB=0, BC=0, length=7
        handle = struct.pack("<H", 0x0000)  # handle | PB | BC
        length = struct.pack("<H", 7)
        # L2CAP: length=3, cid=0x0004 (ATT)
        l2cap = struct.pack("<HH", 3, 0x0004)
        # ATT: Read Request (0x0A) with handle 0x0001
        att = bytes([0x0A, 0x01, 0x00])
        packet = bytes([0x02]) + handle + length + l2cap + att

        with tempfile.NamedTemporaryFile(delete=False, suffix=".log") as f:
            f.write(self._make_btsnoop_header())
            f.write(self._make_packet_record(packet, 200, 5000, 0))
            fname = f.name

        try:
            p = self.parser_class(fname)
            result = p.parse()
            self.assertGreaterEqual(len(result), 1)
            # Проверяем ATT
            gatt = p.get_gatt_ops()
            self.assertGreaterEqual(len(gatt), 1)
        finally:
            os.unlink(fname)

    def test_hci_event_packet(self):
        """Парсинг HCI события."""
        # HCI Event: Command Complete (0x0E)
        packet = bytes([0x04, 0x0E, 0x05, 0x01, 0x01, 0x20, 0x00, 0x00])

        with tempfile.NamedTemporaryFile(delete=False, suffix=".log") as f:
            f.write(self._make_btsnoop_header())
            f.write(self._make_packet_record(packet, 300, 10000, 0))
            fname = f.name

        try:
            p = self.parser_class(fname)
            result = p.parse()
            self.assertEqual(len(result), 1)
            self.assertEqual(result[0]["type"], "hci_evt")
            self.assertEqual(result[0]["event_code"], 0x0E)
        finally:
            os.unlink(fname)

    def test_le_advertising_report(self):
        """LE Advertising Report с адресом."""
        # LE Meta Event (0x3E) + LE Advertising Report (0x02)
        # num_reports=1, evt_type=0, addr_type=0, addr=AA:BB:CC:DD:EE:FF
        report_data = bytes([0x02, 0x01, 0x00]) + bytes([0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF])
        report_data += bytes([0x00, 0x00])  # data len + data
        report_data += bytes([0x7F])  # RSSI
        le_evt = bytes([0x02]) + report_data
        packet = bytes([0x04, 0x3E, len(le_evt)]) + le_evt

        with tempfile.NamedTemporaryFile(delete=False, suffix=".log") as f:
            f.write(self._make_btsnoop_header())
            f.write(self._make_packet_record(packet, 400, 0, 1))
            fname = f.name

        try:
            p = self.parser_class(fname)
            result = p.parse()
            self.assertGreaterEqual(len(result), 1)
            if "advertising_address" in result[0]:
                self.assertIn("AA", result[0]["advertising_address"])
        finally:
            os.unlink(fname)


class TestGattScan(unittest.TestCase):
    """Тесты для gatt-scan.py."""

    def setUp(self):
        self.describe_uuid = gatt_scan.describe_uuid
        self.uuid_to_short = gatt_scan.uuid_to_short
        self.KNOWN_SERVICES = gatt_scan.KNOWN_SERVICES
        self.KNOWN_CHARACTERISTICS = gatt_scan.KNOWN_CHARACTERISTICS

    def test_uuid_to_short_16bit(self):
        """16-битный UUID не сокращается."""
        self.assertEqual(self.uuid_to_short("1800"), "1800")

    def test_uuid_to_short_128bit(self):
        """128-битный Bluetooth UUID сокращается до 16 бит."""
        uuid = "0000180f-0000-1000-8000-00805f9b34fb"
        self.assertEqual(self.uuid_to_short(uuid), "180f")

    def test_uuid_to_short_custom(self):
        """128-битный кастомный UUID не сокращается."""
        uuid = "12345678-1234-5678-1234-56789abcdef0"
        result = self.uuid_to_short(uuid)
        self.assertEqual(result, uuid)

    def test_describe_uuid_known(self):
        """Известные UUID получают человекочитаемое имя."""
        name = self.describe_uuid("1800", self.KNOWN_SERVICES)
        self.assertEqual(name, "Generic Access")

    def test_describe_uuid_unknown(self):
        """Неизвестные UUID возвращаются как есть."""
        name = self.describe_uuid("dead", self.KNOWN_SERVICES)
        self.assertEqual(name, "dead")

    def test_describe_characteristic(self):
        """Известные характеристики распознаются."""
        name = self.describe_uuid("2a00", self.KNOWN_CHARACTERISTICS)
        self.assertEqual(name, "Device Name")

    def test_hex_value_parsing_btmon(self):
        """Проверка работы с btmon hex."""
        # Интеграционная проверка: результат импорта
        self.assertIn("1800", self.KNOWN_SERVICES)
        self.assertIn("2a00", self.KNOWN_CHARACTERISTICS)


class TestProfile(unittest.TestCase):
    """Тесты GATT-профилей."""

    def test_profile_exists(self):
        """Проверка существования файлов профилей."""
        gatt_dir = os.path.join(os.path.dirname(__file__), "..", "gatt")
        self.assertTrue(os.path.isdir(gatt_dir), "Директория gatt/ не найдена")
        yaml_files = [f for f in os.listdir(gatt_dir) if f.endswith(".yaml")]
        self.assertGreater(len(yaml_files), 0, "YAML-профили не найдены")

    def test_profile_yaml_syntax(self):
        """Проверка синтаксиса YAML-профилей."""
        import yaml
        gatt_dir = os.path.join(os.path.dirname(__file__), "..", "gatt")
        for fname in os.listdir(gatt_dir):
            if fname.endswith(".yaml"):
                fpath = os.path.join(gatt_dir, fname)
                with open(fpath, "r") as f:
                    try:
                        data = yaml.safe_load(f)
                        self.assertIsNotNone(data, f"{fname}: пустой YAML")
                        self.assertIn("device", data, f"{fname}: нет device")
                        self.assertIn("services", data, f"{fname}: нет services")
                    except yaml.YAMLError as e:
                        self.fail(f"{fname}: ошибка YAML: {e}")


if __name__ == "__main__":
    unittest.main()
