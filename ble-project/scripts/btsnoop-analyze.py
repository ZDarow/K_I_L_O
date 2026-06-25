#!/usr/bin/env python3
"""
Анализатор btsnoop логов — парсинг HCI-трафика Android BTSnoop.

Читает файлы btsnoop_hci.log, btsnoop.cfa или raw PCAP-файлы
(формат btsnoop/varied) и извлекает HCI-события, ACL-пакеты
и GATT-операции.

Форматы ввода:
  - Android btsnoop_hci.log (стандартный btsnoop)
  - Wireshark/tcpdump PCAP (btsnoop format)
  - Raw HCI dump в hex

Примеры:
  python3 btsnoop-analyze.py /sdcard/btsnoop_hci.log
  python3 btsnoop-analyze.py capture.cfa --format human
  python3 btsnoop-analyze.py dump.hex --format json --output hci.json
  python3 btsnoop-analyze.py log.pcap --gatt-only
"""

import argparse
import json
import logging
import os
import re
import struct
import sys
from collections import defaultdict
from datetime import datetime, timedelta
from typing import Optional

logging.basicConfig(level=logging.INFO, format="%(message)s")
log = logging.getLogger("btsnoop-analyze")

# Константы HCI
HCI_COMMAND_PKT = 0x01
HCI_ACL_DATA_PKT = 0x02
HCI_SCO_DATA_PKT = 0x03
HCI_EVENT_PKT = 0x04
HCI_ISO_DATA_PKT = 0x05

HCI_EVENT_NAMES: dict[int, str] = {
    0x01: "Inquiry Complete",
    0x02: "Inquiry Result",
    0x03: "Connection Complete",
    0x04: "Connection Request",
    0x05: "Disconnection Complete",
    0x06: "Authentication Complete",
    0x07: "Remote Name Request Complete",
    0x08: "Encryption Change",
    0x09: "Change Connection Link Key Complete",
    0x0A: "Master Link Key Complete",
    0x0B: "Read Remote Supported Features Complete",
    0x0C: "Read Remote Version Information Complete",
    0x0D: "QoS Setup Complete",
    0x0E: "Command Complete",
    0x0F: "Command Status",
    0x10: "Hardware Error",
    0x13: "Number of Completed Packets",
    0x14: "Mode Change",
    0x15: "Return Link Keys",
    0x16: "Pin Code Request",
    0x17: "Link Key Request",
    0x18: "Link Key Notification",
    0x19: "Loopback Command",
    0x1A: "Data Buffer Overflow",
    0x1B: "Max Slots Change",
    0x1C: "Read Clock Offset Complete",
    0x1D: "Connection Packet Type Changed",
    0x1E: "QoS Violation",
    0x20: "Page Scan Repetition Mode Change",
    0x21: "Flow Specification Complete",
    0x22: "Inquiry Result with RSSI",
    0x2F: "LE Meta Event",
    0x36: "Number of Completed Data Blocks",
}

LE_META_EVENT_NAMES: dict[int, str] = {
    0x01: "LE Connection Complete",
    0x02: "LE Advertising Report",
    0x03: "LE Connection Update Complete",
    0x04: "LE Read Remote Features Complete",
    0x05: "LE Long Term Key Request",
    0x06: "LE Remote Connection Parameter Request",
    0x07: "LE Data Length Change",
    0x08: "LE Read Local P-256 Public Key Complete",
    0x09: "LE Generate DHKey Complete",
    0x0A: "LE Enhanced Connection Complete",
    0x0B: "LE Direct Advertising Report",
    0x0C: "LE PHY Update Complete",
    0x0D: "LE Extended Advertising Report",
    0x0E: "LE Periodic Advertising Sync Established",
    0x0F: "LE Periodic Advertising Report",
    0x10: "LE Periodic Advertising Sync Lost",
    0x11: "LE Extended Scan Timeout",
    0x12: "LE Extended Advertising Set Terminated",
    0x13: "LE Scan Request Received",
    0x14: "LE Channel Selection Algorithm",
}


# === BTSNOOP File Format ===
# https://www.fte.com/webhelp/bpa/Content/Technical_Information/BT_Snoop_File_Format.htm

BTSNOOP_MAGIC = b"btsnoop\x00"
PCAP_MAGIC_NANO = 0xa1b23c4d
PCAP_MAGIC_MICRO = 0xa1b2c3d4
PCAP_MAGIC_NANO_SWAP = 0x4d3cb2a1
PCAP_MAGIC_MICRO_SWAP = 0xd4c3b2a1

BTSNOOP_DLC_HCI = 0x1002  # DLC_HCI_H4


class BTSnoopParser:
    """Парсер btsnoop/PCAP файлов с HCI-трафиком."""

    def __init__(self, filepath: str):
        self.filepath = filepath
        self.packets: list[dict] = []
        self.stats: dict = defaultdict(int)
        self.connections: list[dict] = []
        self.gatt_ops: list[dict] = []

    def parse(self) -> list[dict]:
        """Парсит файл и возвращает список HCI-пакетов."""
        with open(self.filepath, "rb") as f:
            data = f.read()

        if len(data) < 16:
            raise ValueError("Файл слишком мал для btsnoog/PCAP заголовка")

        magic = data[:8]

        if data[:8] == BTSNOOP_MAGIC[:8]:
            return self._parse_btsnoop(data)
        else:
            pcap_magic = struct.unpack("<I", data[:4])[0]
            if pcap_magic in (PCAP_MAGIC_NANO, PCAP_MAGIC_MICRO,
                              PCAP_MAGIC_NANO_SWAP, PCAP_MAGIC_MICRO_SWAP):
                return self._parse_pcap(data, pcap_magic)
            else:
                return self._parse_raw_hex(data)

    def _parse_btsnoop(self, data: bytes) -> list[dict]:
        """Парсит формат btsnoop."""
        # Заголовок: magic(8) + version(4) + datalink(4) = 16
        if len(data) < 16:
            return []

        version = struct.unpack(">I", data[8:12])[0]
        datalink = struct.unpack(">I", data[12:16])[0]

        log.info(f"BTSnoop: version={version}, datalink=0x{datalink:04x}")
        if datalink != BTSNOOP_DLC_HCI:
            log.warning(f"Неизвестный DLC: 0x{datalink:04x} (ожидается HCI)")

        offset = 16
        pkt_num = 0
        while offset + 24 <= len(data):
            # Заголовок пакета btsnoop: 24 байта
            hdr = data[offset:offset + 24]
            orig_len = struct.unpack(">I", hdr[0:4])[0]
            incl_len = struct.unpack(">I", hdr[4:8])[0]
            flags = struct.unpack(">I", hdr[8:12])[0]
            drops = struct.unpack(">I", hdr[12:16])[0]
            ts_sec = struct.unpack(">I", hdr[16:20])[0]
            ts_usec = struct.unpack(">I", hdr[20:24])[0]

            # Cumulative drops
            if drops > 0 and pkt_num == 0:
                log.warning(f"Потеряно пакетов: {drops}")

            packet_data = data[offset + 24:offset + 24 + incl_len]

            direction = "host->controller" if (flags & 0x01) else "controller->host"

            pkt = self._decode_hci_packet(packet_data, ts_sec, ts_usec, direction)
            if pkt:
                pkt["number"] = pkt_num + 1
                pkt["flags"] = flags
                pkt["drops"] = drops
                self.packets.append(pkt)
                self.stats[pkt["type_name"]] += 1

            offset += 24 + incl_len
            pkt_num += 1

        log.info(f"BTSnoop: {pkt_num} пакетов")
        return self.packets

    def _parse_pcap(self, data: bytes, magic: int) -> list[dict]:
        """Парсит PCAP-формат (Wireshark/tcpdump)."""
        endian = "<" if magic in (PCAP_MAGIC_NANO, PCAP_MAGIC_MICRO) else ">"
        is_nano = magic in (PCAP_MAGIC_NANO, PCAP_MAGIC_NANO_SWAP)

        # Global header: magic(4) + version_major(2) + version_minor(2) +
        #               thiszone(4) + sigfigs(4) + snaplen(4) + network(4) = 24
        if len(data) < 24:
            return []

        network = struct.unpack(f"{endian}I", data[20:24])[0]
        log.info(f"PCAP: network={network}, nanosec={is_nano}")

        offset = 24
        pkt_num = 0
        while offset + 16 <= len(data):
            # Packet header: ts_sec(4) + ts_frac(4) + incl_len(4) + orig_len(4) = 16
            ts_sec = struct.unpack(f"{endian}I", data[offset:offset + 4])[0]
            ts_frac = struct.unpack(f"{endian}I", data[offset + 4:offset + 8])[0]
            incl_len = struct.unpack(f"{endian}I", data[offset + 8:offset + 12])[0]
            orig_len = struct.unpack(f"{endian}I", data[offset + 12:offset + 16])[0]

            packet_data = data[offset + 16:offset + 16 + incl_len]

            ts_usec = ts_frac // 1000 if is_nano else ts_frac

            pkt = self._decode_hci_packet(packet_data, ts_sec, ts_usec, "unknown")
            if pkt:
                pkt["number"] = pkt_num + 1
                self.packets.append(pkt)
                self.stats[pkt["type_name"]] += 1

            offset += 16 + incl_len
            pkt_num += 1

        log.info(f"PCAP: {pkt_num} пакетов")
        return self.packets

    def _parse_raw_hex(self, data: bytes) -> list[dict]:
        """Парсит raw hex dump (одна строка = одно HCI-событие)."""
        try:
            text = data.decode("utf-8", errors="replace")
        except Exception:
            text = data.hex()

        lines = text.splitlines()
        for i, line in enumerate(lines):
            line = line.strip()
            if not line:
                continue
            # Пытаемся распарсить hex
            hex_str = re.sub(r'[^0-9a-fA-F]', '', line)
            if len(hex_str) < 2:
                continue
            try:
                binary = bytes.fromhex(hex_str)
            except ValueError:
                continue

            pkt = self._decode_hci_packet(binary, 0, 0, "unknown")
            if pkt:
                pkt["number"] = i + 1
                pkt["line"] = line[:80]
                self.packets.append(pkt)
                self.stats[pkt["type_name"]] += 1

        log.info(f"Raw hex: {len(self.packets)} пакетов")
        return self.packets

    def _decode_hci_packet(self, data: bytes, ts_sec: int, ts_usec: int,
                           direction: str) -> Optional[dict]:
        """Декодирует HCI-пакет из сырых байт."""
        if not data:
            return None

        pkt_type = data[0]
        result: dict = {
            "timestamp": ts_sec + ts_usec / 1_000_000,
            "direction": direction,
            "raw_size": len(data),
            "raw_hex": data.hex(),
        }

        if pkt_type == HCI_COMMAND_PKT:
            result["type"] = "hci_cmd"
            result["type_name"] = "HCI Command"
            if len(data) >= 4:
                opcode = struct.unpack("<H", data[1:3])[0]
                ogf = (opcode >> 10) & 0x3F
                ocf = opcode & 0x3FF
                result["opcode"] = f"0x{opcode:04x}"
                result["ogf"] = ogf
                result["ocf"] = ocf
                result["params"] = data[3:].hex()

        elif pkt_type == HCI_ACL_DATA_PKT:
            result["type"] = "acl_data"
            result["type_name"] = "ACL Data"
            if len(data) >= 5:
                handle = struct.unpack("<H", data[1:3])[0] & 0x0FFF
                pb_flag = (data[1] >> 4) & 0x03
                bc_flag = (data[2] >> 4) & 0x03
                length = struct.unpack("<H", data[3:5])[0]
                payload = data[5:5 + length] if length > 0 else b""
                result["handle"] = f"0x{handle:04x}"
                result["pb_flag"] = pb_flag
                result["acl_length"] = length
                result["payload"] = payload.hex()

                # Попытка детектировать L2CAP + ATT
                if len(payload) >= 4:
                    l2cap_len = struct.unpack("<H", payload[0:2])[0]
                    cid = struct.unpack("<H", payload[2:4])[0]
                    result["l2cap_cid"] = f"0x{cid:04x}"
                    if cid == 0x0004:  # ATT
                        if len(payload) > 4:
                            att_opcode = payload[4]
                            att_names = {
                                0x02: "ATT Read Request",
                                0x0A: "ATT Read Response",
                                0x12: "ATT Write Request",
                                0x52: "ATT Write Command",
                                0x1B: "ATT Handle Value Notification",
                                0x1D: "ATT Handle Value Indication",
                            }
                            result["att_op"] = att_names.get(att_opcode,
                                                             f"ATT 0x{att_opcode:02x}")
                            result["type"] = "gatt"
                            result["type_name"] = result["att_op"]
                            self.gatt_ops.append(result)

        elif pkt_type == HCI_EVENT_PKT:
            result["type"] = "hci_evt"
            result["type_name"] = "HCI Event"
            if len(data) >= 3:
                evt_code = data[1]
                evt_len = data[2]
                evt_data = data[3:3 + evt_len] if evt_len > 0 else b""
                result["event_code"] = evt_code
                result["event_name"] = HCI_EVENT_NAMES.get(evt_code, f"Unknown(0x{evt_code:02x})")
                result["event_data"] = evt_data.hex()
                result["type_name"] = result["event_name"]

                # LE Meta Event
                if evt_code == 0x2F and evt_data:
                    le_code = evt_data[0]
                    le_name = LE_META_EVENT_NAMES.get(le_code, f"LE Unknown(0x{le_code:02x})")
                    result["le_meta_code"] = le_code
                    result["le_meta_name"] = le_name
                    result["type_name"] = le_name

                    # Advertising Report
                    if le_code == 0x02 and len(evt_data) > 3:
                        num_reports = evt_data[1]
                        result["num_reports"] = num_reports
                        report = evt_data[2:]
                        if len(report) >= 8:
                            evt_type = report[0]
                            addr_type = report[1]
                            addr = ":".join(f"{b:02X}" for b in report[2:8])
                            result["advertising_address"] = addr
                            rssi = struct.unpack("b", bytes([report[-1]]))[0] if len(report) > 2 else 0
                            result["rssi"] = rssi

        elif pkt_type == HCI_SCO_DATA_PKT:
            result["type"] = "sco_data"
            result["type_name"] = "SCO Data"

        else:
            result["type"] = f"unknown(0x{pkt_type:02x})"
            result["type_name"] = f"Unknown(0x{pkt_type:02x})"

        return result

    def get_stats(self) -> dict:
        """Возвращает статистику пакетов."""
        return {
            "total": len(self.packets),
            "by_type": dict(self.stats),
            "gatt_operations": len(self.gatt_ops),
        }

    def get_gatt_ops(self) -> list[dict]:
        """Возвращает только GATT-операции."""
        return self.gatt_ops


def print_stats(stats: dict) -> None:
    """Вывод статистики."""
    log.info(f"\n{'=' * 50}")
    log.info("HCI Traffic Analysis")
    log.info(f"{'=' * 50}")
    log.info(f"Всего пакетов: {stats['total']}")
    log.info(f"GATT операций: {stats['gatt_operations']}")
    log.info("")
    log.info(f"{'Тип пакета':45s} {'Количество':10s}")
    log.info("-" * 55)
    for pkt_type, count in sorted(stats["by_type"].items(), key=lambda x: -x[1]):
        log.info(f"{pkt_type:45s} {count:10d}")


def print_gatt_ops(gatt_ops: list[dict]) -> None:
    """Вывод GATT-операций."""
    if not gatt_ops:
        log.info("\nGATT-операции не найдены")
        return

    log.info(f"\n{'=' * 60}")
    log.info("GATT Operations")
    log.info(f"{'=' * 60}")
    for op in gatt_ops[:50]:
        h = op.get("handle", "")
        l2 = op.get("l2cap_cid", "")
        att = op.get("att_op", "")
        raw = op.get("raw_size", 0)
        log.info(f"  #{op.get('number', '?'):5d}  {att:35s}  Handle={h}  L2CAP={l2}  ({raw} bytes)")

    if len(gatt_ops) > 50:
        log.info(f"  ... и ещё {len(gatt_ops) - 50} операций")


def main():
    parser = argparse.ArgumentParser(
        description="Анализатор btsnoop логов — HCI трафик и GATT-операции",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Примеры:
  python3 btsnoop-analyze.py /sdcard/btsnoop_hci.log
  python3 btsnoop-analyze.py capture.cfa --gatt-only
  python3 btsnoop-analyze.py dump.pcap --format json -o output.json
        """,
    )
    parser.add_argument("input", help="Файл btsnoog/PCAP/hex")
    parser.add_argument("--format", "-f", choices=["human", "json", "summary"],
                        default="summary", help="Формат вывода")
    parser.add_argument("--output", "-o", help="Файл для сохранения результатов (JSON)")
    parser.add_argument("--gatt-only", action="store_true",
                        help="Показать только GATT-операции")

    args = parser.parse_args()

    if not os.path.exists(args.input):
        log.error(f"Файл не найден: {args.input}")
        sys.exit(1)

    log.info(f"Чтение: {args.input} ({os.path.getsize(args.input)} bytes)")

    parser_obj = BTSnoopParser(args.input)
    try:
        packets = parser_obj.parse()
    except Exception as e:
        log.error(f"Ошибка парсинга: {e}")
        sys.exit(1)

    stats = parser_obj.get_stats()
    gatt_ops = parser_obj.get_gatt_ops()

    if args.gatt_only:
        print_gatt_ops(gatt_ops)
        if args.output:
            with open(args.output, "w") as f:
                json.dump({"gatt_operations": gatt_ops}, f, indent=2, default=str)
            log.info(f"GATT-операции сохранены: {args.output}")
        return

    if args.format == "json":
        result = {
            "file": args.input,
            "stats": stats,
            "gatt_operations": gatt_ops,
            "packets": packets,
        }
        output = json.dumps(result, indent=2, ensure_ascii=False, default=str)
        if args.output:
            with open(args.output, "w") as f:
                f.write(output)
            log.info(f"Результаты сохранены: {args.output}")
        else:
            print(output)
    elif args.format == "summary":
        print_stats(stats)
        print_gatt_ops(gatt_ops)
        if args.output:
            result = {"stats": stats, "gatt_operations": gatt_ops}
            with open(args.output, "w") as f:
                json.dump(result, f, indent=2, default=str)
    else:
        # human-readable
        print_stats(stats)
        print_gatt_ops(gatt_ops)
        log.info(f"\nВсего пакетов: {len(packets)}")
        for pkt in packets[:20]:
            log.info(f"  #{pkt['number']:5d}  {pkt.get('type_name', pkt['type']):40s} "
                     f"({pkt['raw_size']} bytes)")
        if len(packets) > 20:
            log.info(f"  ... и ещё {len(packets) - 20} пакетов")


if __name__ == "__main__":
    main()
