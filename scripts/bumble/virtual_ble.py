#!/usr/bin/env python3
"""Виртуальный BLE-стенд на базе Google Bumble.

Использует Virtual Radio вместо физического HCI-адаптера.
Позволяет тестировать GATT-сканеры и анализаторы без реального Bluetooth-адаптера.

Пример:
    python3 ble-project/bumble/virtual_ble.py --scenario scan
    python3 ble-project/bumble/virtual_ble.py --scenario gatt-server
"""

import argparse
import asyncio
import sys

from bumble.device import Device
from bumble.hci import Address
from bumble.utils import AsyncRunner

DEVICE_NAME = "K_I_L_O Virtual BLE"
DEVICE_ADDRESS = Address("F0:F1:F2:F3:F4:F5")


async def scenario_scan(duration: int = 5):
    """Сценарий: сканирование виртуальных BLE-устройств."""
    print(f"[BLE] Запуск виртуального сканирования ({duration}с)...")
    print(f"[BLE] Адрес: {DEVICE_ADDRESS}")
    device = Device.with_hci(
        "virt:0",
        address=DEVICE_ADDRESS,
        name=DEVICE_NAME,
    )

    await device.power_on()
    device.on(
        "advertisement",
        lambda adv: print(f"[BLE] Найдено устройство: {adv.address}, RSSI={adv.rssi}"),
    )

    await device.start_scanning()
    await asyncio.sleep(duration)
    await device.stop_scanning()
    await device.power_off()

    print("[BLE] Сканирование завершено.")


async def scenario_gatt_server():
    """Сценарий: простой GATT-сервер с виртуальным устройством."""
    print(f"[BLE] Запуск виртуального GATT-сервера ({DEVICE_ADDRESS})...")
    device = Device.with_hci(
        "virt:0",
        address=DEVICE_ADDRESS,
        name=DEVICE_NAME,
    )
    await device.power_on()

    # Добавляем простой GATT-сервис с характеристикой
    @device.on("connection")
    def on_connection(connection):
        print(f"[BLE] Подключено: {connection.peer_address}")

    print("[BLE] GATT-сервер готов (нажмите Ctrl+C для выхода)")
    try:
        await asyncio.Event().wait()
    except asyncio.CancelledError:
        pass
    finally:
        await device.power_off()
        print("[BLE] GATT-сервер остановлен.")


async def scenario_ping():
    """Сценарий: проверка доступности Bumble (Virtual Radio)."""
    try:
        Device.with_hci(
            "virt:0", address=DEVICE_ADDRESS
        )  # Проверка доступности Virtual Radio
        print("[BLE] Virtual Radio: ДОСТУПЕН")
        print(f"[BLE] Устройство: {DEVICE_NAME} ({DEVICE_ADDRESS})")
    except Exception as e:
        print(f"[BLE] Virtual Radio: ОШИБКА ({e})")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Виртуальный BLE-стенд (Google Bumble)"
    )
    parser.add_argument(
        "--scenario",
        "-s",
        choices=["scan", "gatt-server", "ping"],
        default="ping",
        help="Сценарий тестирования (по умолчанию: ping)",
    )
    parser.add_argument(
        "--duration",
        "-d",
        type=int,
        default=5,
        help="Длительность сканирования в секундах",
    )

    args = parser.parse_args()

    scenarios = {
        "scan": lambda: scenario_scan(args.duration),
        "gatt-server": scenario_gatt_server,
        "ping": scenario_ping,
    }

    runner = AsyncRunner()
    runner.run(scenarios[args.scenario]())


if __name__ == "__main__":
    main()
