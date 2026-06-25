#!/usr/bin/env python3
"""
GATT-сканер — обнаружение BLE-устройств и GATT-профилей.

Использует библиотеку bleak для сканирования BLE-устройств,
подключения и обхода GATT-сервисов/характеристик/дескрипторов.

Режимы работы:
  scan       — сканирование BLE-устройств
  discover   — подключение к устройству и обход GATT
  monitor    — мониторинг рекламных пакетов в реальном времени

Примеры:
  python3 gatt-scan.py scan --timeout 10
  python3 gatt-scan.py discover --address AA:BB:CC:DD:EE:FF
  python3 gatt-scan.py discover --name "MyDevice"
  python3 gatt-scan.py monitor --timeout 30 --output /tmp/scan.pcap
"""

import argparse
import asyncio
import json
import logging
import os
import signal
import struct
import sys
import time
from typing import Optional

# Словарь известных UUID сервисов GATT
KNOWN_SERVICES: dict[str, str] = {
    "1800": "Generic Access",
    "1801": "Generic Attribute",
    "1802": "Immediate Alert",
    "1803": "Link Loss",
    "1804": "Tx Power",
    "1805": "Current Time",
    "1806": "Reference Time Update",
    "1807": "Next DST Change",
    "1808": "Glucose",
    "1809": "Health Thermometer",
    "180a": "Device Information",
    "180d": "Heart Rate",
    "180f": "Battery Service",
    "1810": "Blood Pressure",
    "1811": "Alert Notification",
    "1812": "Human Interface Device",
    "1813": "Scan Parameters",
    "1814": "Running Speed and Cadence",
    "1815": "Automation IO",
    "1816": "Cycling Speed and Cadence",
    "181a": "Environmental Sensing",
    "181c": "User Data",
    "6001": "QBgrp/QBpro Service (Alibaba)",
    "fe00": "Xiaomi Mi Band",
    "fee0": "Xiaomi Mi Band 2/3/4",
    "fee1": "Xiaomi Mi Band HR",
    "feb6": "Xiaomi Legacy",
    "fc01": "Xiaomi (Custom)",
    "0d00": "Xiaomi (Custom)",
    "a001": "Qingping/ClearGrass",
    "ff00": "Tuya/Bluetooth Smart",
}

# Словарь известных UUID характеристик
KNOWN_CHARACTERISTICS: dict[str, str] = {
    "2a00": "Device Name",
    "2a01": "Appearance",
    "2a02": "Peripheral Privacy Flag",
    "2a03": "Reconnection Address",
    "2a04": "Peripheral Preferred Connection Parameters",
    "2a05": "Service Changed",
    "2a06": "Alert Level",
    "2a19": "Battery Level",
    "2a23": "System ID",
    "2a24": "Model Number String",
    "2a25": "Serial Number String",
    "2a26": "Firmware Revision String",
    "2a27": "Hardware Revision String",
    "2a28": "Software Revision String",
    "2a29": "Manufacturer Name String",
    "2a37": "Heart Rate Measurement",
    "2a38": "Body Sensor Location",
    "2a39": "Heart Rate Control Point",
    "2a3f": "Alert Status",
    "2a46": "New Alert",
    "2a49": "Blood Pressure Feature",
    "2a50": "PnP ID",
}

logging.basicConfig(level=logging.WARNING, format="%(message)s")
log = logging.getLogger("gatt-scan")


def uuid_to_short(uuid: str) -> str:
    """Сокращает 128-битный UUID до 16-битного, если это стандартный GATT UUID."""
    if len(uuid) == 4:
        return uuid.lower()
    if len(uuid) == 8:
        return uuid.lower()
    # Bluetooth Base UUID: 0000xxxx-0000-1000-8000-00805F9B34FB
    if uuid.lower().endswith("-0000-1000-8000-00805f9b34fb"):
        short = uuid[4:8].lower()
        if short != "0000":
            return short
    return uuid


def describe_uuid(uuid: str, known: dict[str, str]) -> str:
    """Возвращает человекочитаемое имя UUID."""
    short = uuid_to_short(uuid)
    return known.get(short, uuid)


def format_manufacturer_data(data: bytes) -> str:
    """Пытается декодировать manufacturer data."""
    if len(data) < 2:
        return data.hex()
    company_id = struct.unpack("<H", data[:2])[0]
    payload = data[2:]
    return f"Company=0x{company_id:04x} Data={payload.hex()}"


async def scan_devices(timeout: int = 10, output: Optional[str] = None) -> list[dict]:
    """Сканирует BLE-устройства и возвращает список обнаруженных."""
    try:
        from bleak import BleakScanner
    except ImportError:
        log.error("bleak не установлен. Установи: pip install bleak")
        sys.exit(1)

    devices: list[dict] = []

    def detection_callback(device, advertisement_data):
        info = {
            "address": device.address,
            "name": advertisement_data.local_name or device.name or "Unknown",
            "rssi": advertisement_data.rssi,
            "tx_power": advertisement_data.tx_power,
            "uuids": list(advertisement_data.service_uuids) if advertisement_data.service_uuids else [],
            "manufacturer": None,
        }
        if advertisement_data.manufacturer_data:
            for comp, data in advertisement_data.manufacturer_data.items():
                info["manufacturer"] = f"Company=0x{comp:04x} Data={data.hex()}"
                break
        devices.append(info)

    scanner = BleakScanner(detection_callback=detection_callback)
    log.info(f"Сканирование BLE-устройств ({timeout} сек)...")
    log.info("Нажми Ctrl+C для досрочной остановки")
    try:
        await scanner.start()
        await asyncio.sleep(timeout)
        await scanner.stop()
    except asyncio.CancelledError:
        await scanner.stop()

    # Дедупликация по адресу (оставляем с最强的 RSSI)
    unique: dict[str, dict] = {}
    for d in devices:
        addr = d["address"]
        if addr not in unique or d["rssi"] > unique[addr]["rssi"]:
            unique[addr] = d

    result = sorted(unique.values(), key=lambda x: x["rssi"], reverse=True)

    if output:
        with open(output, "w") as f:
            json.dump(result, f, indent=2, ensure_ascii=False)
        log.info(f"Результаты сохранены: {output}")

    return result


async def discover_gatt(address: str, timeout: int = 30) -> dict:
    """Подключается к устройству и обходит GATT-сервисы/характеристики/дескрипторы."""
    try:
        from bleak import BleakClient
        from bleak.exc import BleakError
    except ImportError:
        log.error("bleak не установлен. Установи: pip install bleak")
        sys.exit(1)

    result: dict = {
        "address": address,
        "services": [],
    }

    try:
        async with BleakClient(address, timeout=timeout) as client:
            log.info(f"Подключено: {address}")
            result["mtu"] = client.mtu_size if hasattr(client, "mtu_size") else None

            for service in client.services:
                svc_info = {
                    "uuid": service.uuid,
                    "handle": service.handle,
                    "name": describe_uuid(service.uuid, KNOWN_SERVICES),
                    "characteristics": [],
                }

                for char in service.characteristics:
                    char_info = {
                        "uuid": char.uuid,
                        "handle": char.handle,
                        "properties": list(char.properties),
                        "name": describe_uuid(char.uuid, KNOWN_CHARACTERISTICS),
                        "descriptors": [],
                    }

                    # Читаем значение характеристики (если readable)
                    value = None
                    if "read" in char.properties:
                        try:
                            raw = await client.read_gatt_char(char.uuid)
                            char_info["value_raw"] = raw.hex()
                            char_info["value_utf8"] = _try_decode(raw)
                        except Exception as e:
                            char_info["read_error"] = str(e)

                    for desc in char.descriptors:
                        desc_info = {
                            "uuid": desc.uuid,
                            "handle": desc.handle,
                        }
                        try:
                            raw = await client.read_gatt_descriptor(desc.handle)
                            desc_info["value"] = raw.hex()
                        except Exception:
                            pass
                        char_info["descriptors"].append(desc_info)

                    svc_info["characteristics"].append(char_info)

                result["services"].append(svc_info)

        log.info(f"Отключено: {address}")
    except BleakError as e:
        log.error(f"Ошибка подключения к {address}: {e}")
        result["error"] = str(e)
    except asyncio.TimeoutError:
        log.error(f"Таймаут подключения к {address}")
        result["error"] = "timeout"
    except Exception as e:
        log.error(f"Неизвестная ошибка: {e}")
        result["error"] = str(e)

    return result


def _try_decode(data: bytes) -> Optional[str]:
    """Пытается декодировать байты как UTF-8 строку."""
    try:
        decoded = data.decode("utf-8").strip().replace("\x00", "")
        if decoded and all(32 <= ord(c) < 127 or c in " абвгдеёжзийклмнопрстуфхцчшщъыьэюя" for c in decoded):
            return decoded
    except (UnicodeDecodeError, AttributeError):
        pass
    return None


async def monitor_devices(timeout: int = 30, output: Optional[str] = None) -> None:
    """Мониторинг рекламных пакетов BLE-устройств в реальном времени."""
    try:
        from bleak import BleakScanner
    except ImportError:
        log.error("bleak не установлен")
        sys.exit(1)

    packets = []

    def callback(device, advertisement_data):
        ts = time.strftime("%H:%M:%S")
        name = advertisement_data.local_name or device.name or "Unknown"
        rssi = advertisement_data.rssi
        uuids = len(advertisement_data.service_uuids or [])
        mfr = ""
        if advertisement_data.manufacturer_data:
            mfr = " [mfr data]"
        line = f"{ts}  {device.address:18s}  {rssi:4d} dBm  {name:20s}  {uuids} UUIDs{mfr}"
        log.info(line)
        packets.append({
            "time": ts,
            "address": device.address,
            "name": name,
            "rssi": rssi,
            "service_uuids": list(advertisement_data.service_uuids or []),
        })

    log.info(f"Мониторинг BLE-пакетов ({timeout} сек)...")
    log.info(f"{'Время':8s}  {'Адрес':18s}  {'RSSI':8s}  {'Имя':20s}  {'Службы':10s}")
    log.info("-" * 70)

    scanner = BleakScanner(detection_callback=callback)
    try:
        await scanner.start()
        await asyncio.sleep(timeout)
        await scanner.stop()
    except asyncio.CancelledError:
        await scanner.stop()

    if output and packets:
        with open(output, "w") as f:
            json.dump(packets, f, indent=2)
        log.info(f"Пакеты сохранены: {output}")


def print_devices(devices: list[dict]) -> None:
    """Выводит список устройств в табличном формате."""
    if not devices:
        log.warning("Устройства не найдены")
        return

    log.info(f"\nНайдено устройств: {len(devices)}")
    log.info(f"{'Адрес':20s} {'RSSI':6s} {'Имя':30s} {'Сервисы':20s}")
    log.info("-" * 80)
    for d in devices:
        name = (d["name"] or "Unknown")[:28]
        svc = ", ".join(d["uuids"][:3]) if d["uuids"] else ""
        log.info(f"{d['address']:20s} {d['rssi']:4d} dBm {name:30s} {svc:20s}")
    log.info("-" * 80)


def print_gatt(result: dict) -> None:
    """Выводит GATT-профиль в иерархическом формате."""
    if "error" in result:
        log.error(f"Ошибка: {result['error']}")
        return

    log.info(f"\nGATT-профиль устройства: {result['address']}")
    if result.get("mtu"):
        log.info(f"MTU: {result['mtu']}")
    log.info(f"{'=' * 60}")

    for svc in result["services"]:
        svc_name = svc.get("name", "")
        svc_line = f"  Сервис: {svc['uuid']} [{svc['handle']}]"
        if svc_name:
            svc_line += f" — {svc_name}"
        log.info(svc_line)

        for char in svc["characteristics"]:
            props = ", ".join(char["properties"])
            char_name = char.get("name", "")
            char_line = f"    ├─ Характеристика: {char['uuid']} [{char['handle']}] ({props})"
            if char_name:
                char_line += f" — {char_name}"
            log.info(char_line)

            if char.get("value_raw"):
                log.info(f"    │  Значение: {char['value_raw']}")
            if char.get("value_utf8"):
                log.info(f"    │  Текст: {char['value_utf8']}")

            for desc in char["descriptors"]:
                desc_line = f"    │  └─ Дескриптор: {desc['uuid']} [{desc['handle']}]"
                if desc.get("value"):
                    desc_line += f" = {desc['value']}"
                log.info(desc_line)

        log.info(f"  {'─' * 56}")

    # Количество сервисов/характеристик
    svc_count = len(result["services"])
    char_count = sum(len(s["characteristics"]) for s in result["services"])
    log.info(f"\nИтого: {svc_count} сервисов, {char_count} характеристик")


def _setup_signal_handler():
    """Настраивает обработчик SIGINT для корректного завершения asyncio."""

    def handler():
        for task in asyncio.all_tasks():
            task.cancel()

    signal.signal(signal.SIGINT, lambda s, f: handler())


def main():
    parser = argparse.ArgumentParser(
        description="GATT-сканер — обнаружение BLE-устройств и GATT-профилей",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Примеры:
  python3 gatt-scan.py scan --timeout 10
  python3 gatt-scan.py discover --address AA:BB:CC:DD:EE:FF
  python3 gatt-scan.py discover --name "MyDevice"
  python3 gatt-scan.py monitor --timeout 30
  python3 gatt-scan.py scan --output devices.json
        """,
    )
    parser.add_argument("mode", choices=["scan", "discover", "monitor"],
                        help="Режим: scan (сканирование), discover (GATT-обход), monitor (мониторинг)")
    parser.add_argument("--address", "-a", help="BLE-адрес устройства (для discover)")
    parser.add_argument("--name", "-n", help="Имя устройства для поиска (для discover)")
    parser.add_argument("--timeout", "-t", type=int, default=10, help="Таймаут в секундах (по умолч. 10)")
    parser.add_argument("--output", "-o", help="Файл для сохранения результатов (JSON)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Подробный вывод")

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    _setup_signal_handler()

    if args.mode == "scan":
        devices = asyncio.run(scan_devices(args.timeout, args.output))
        print_devices(devices)
    elif args.mode == "discover":
        if not args.address and not args.name:
            # Если адрес не указан, сначала сканируем
            log.info("Адрес не указан. Выполняю предварительное сканирование...")
            devices = asyncio.run(scan_devices(args.timeout))
            if not devices:
                log.error("Устройства не найдены")
                sys.exit(1)
            # Берём первое устройство с именем или просто первое
            target = None
            if args.name:
                for d in devices:
                    if args.name.lower() in (d.get("name") or "").lower():
                        target = d["address"]
                        break
            if not target:
                target = devices[0]["address"]
                log.info(f"Выбрано первое устройство: {target} ({devices[0].get('name', '')})")

            result = asyncio.run(discover_gatt(target, args.timeout))
        else:
            addr = args.address
            if not addr and args.name:
                log.info(f"Поиск устройства по имени: {args.name}")
                devices = asyncio.run(scan_devices(args.timeout))
                for d in devices:
                    if args.name.lower() in (d.get("name") or "").lower():
                        addr = d["address"]
                        break
                if not addr:
                    log.error(f"Устройство с именем '{args.name}' не найдено")
                    sys.exit(1)
            result = asyncio.run(discover_gatt(addr, args.timeout))

        print_gatt(result)
        if args.output:
            with open(args.output, "w") as f:
                json.dump(result, f, indent=2, ensure_ascii=False)
            log.info(f"GATT-профиль сохранён: {args.output}")

    elif args.mode == "monitor":
        asyncio.run(monitor_devices(args.timeout, args.output))


if __name__ == "__main__":
    main()
