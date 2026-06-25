#!/usr/bin/env python3
"""
Инструменты для работы с BLE на Android через ADB.

Предоставляет утилиты для:
  1. Включения BTSnoop логов на Android
  2. Захвата btsnoop логов с устройства
  3. Мониторинга BLE через logcat
  4. GATT-сканирования через ADB shell
  5. Отключения/включения Bluetooth

Требуется: ADB, Android-устройство с USB-отладкой

Примеры:
  python3 android-ble.py snoop-enable         # Включить BTSnoop
  python3 android-ble.py snoop-capture        # Скачать btsnoop логи
  python3 android-ble.py logcat               # Мониторинг BLE в logcat
  python3 android-ble.py scan                 # BLE-скан через ADB
  python3 android-ble.py services AA:BB:CC:DD:EE:FF  # GATT-сервисы
"""

import argparse
import json
import logging
import os
import re
import subprocess
import sys
import tempfile
import time
from datetime import datetime
from typing import Optional

logging.basicConfig(level=logging.INFO, format="%(message)s")
log = logging.getLogger("android-ble")

# Цвета для вывода
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
RED = "\033[0;31m"
CYAN = "\033[0;36m"
BOLD = "\033[1m"
NC = "\033[0m"


def run_adb(args: list[str], timeout: int = 30) -> subprocess.CompletedProcess:
    """Запускает ADB команду и возвращает результат."""
    cmd = ["adb"] + args
    try:
        result = subprocess.run(cmd, capture_output=True, text=True,
                                timeout=timeout)
        return result
    except FileNotFoundError:
        log.error(f"{RED}ADB не найден. Установи: sudo apt install adb{NC}")
        sys.exit(1)
    except subprocess.TimeoutExpired:
        log.error(f"{RED}Таймаут ADB команды: {' '.join(cmd)}{NC}")
        sys.exit(1)


def check_device() -> bool:
    """Проверяет наличие Android-устройства."""
    result = run_adb(["devices"])
    lines = [l for l in result.stdout.splitlines()
             if l.strip() and not l.startswith("List")]
    if not lines:
        log.warning(f"{YELLOW}Нет подключённых Android-устройств.{NC}")
        return False
    log.info(f"{GREEN}Устройство: {lines[0]}{NC}")
    return True


# ─── BTSnoop ──────────────────────────────────────

def snoop_enable():
    """
    Включает BTSnoop логи на Android.

    Работает двумя способами:
      1. Через developer settings (Android 8+)
      2. Через инженерное меню (MTK/Qualcomm)
    """
    if not check_device():
        return

    log.info(f"{BOLD}Включение BTSnoop логов...{NC}")

    # Способ 1: settings put global
    cmds = [
        "settings put global btsnoop_log_icon 0",
        "settings put global btsnoop_log_mode 1",
        "settings put global btsnoop_default_log_mode 1",
        "settings put global bluetooth_btsnoop_log_mode 1",
        "settings put global bluetooth_log_icon 0",
    ]

    for cmd in cmds:
        result = run_adb(["shell", cmd])
        if result.returncode != 0:
            log.warning(f"  {YELLOW}Не удалось: {cmd}{NC}")

    log.info(f"{GREEN}BTSnoop включён. Перезагрузи Bluetooth для применения.{NC}")
    log.info(f"{YELLOW}Путь к логам: /sdcard/btsnoop_hci.log{NC}")
    log.info(f"{YELLOW}  или: /data/misc/bluetooth/logs/btsnoop_hci.log{NC}")


def snoop_capture(output: Optional[str] = None):
    """Скачивает btsnoop лог с Android-устройства."""
    if not check_device():
        return

    # Пути, где могут лежать btsnoop логи
    paths = [
        "/sdcard/btsnoop_hci.log",
        "/sdcard/btsnoop.cfa",
        "/data/misc/bluetooth/logs/btsnoop_hci.log",
        "/data/misc/bluetooth/logs/btsnoop.cfa",
        "/data/vendor/bluetooth/logs/btsnoop_hci.log",
    ]

    found = []
    for path in paths:
        result = run_adb(["shell", f"test -f {path} && echo YES || echo NO"])
        if "YES" in result.stdout:
            found.append(path)

    if not found:
        log.error(f"{RED}BTSnoop логи не найдены.{NC}")
        log.info(f"{YELLOW}Сначала включи BTSnoop: android-ble.py snoop-enable{NC}")
        log.info(f"{YELLOW}Затем перезагрузи Bluetooth и выполни действия.{NC}")
        return

    log.info(f"{GREEN}Найдены логи:{NC}")
    downloaded = []
    for path in found:
        if not output:
            fname = f"btsnoop_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        else:
            base, ext = os.path.splitext(output)
            fname = f"{base}_{os.path.basename(path).replace('.', '_')}{ext}"

        result = run_adb(["pull", path, fname])
        if result.returncode == 0:
            size = os.path.getsize(fname)
            log.info(f"  {GREEN}{fname}{NC} ({size:,} bytes)")
            downloaded.append(fname)
        else:
            log.error(f"  {RED}Ошибка загрузки: {path}{NC}")

    return downloaded


# ─── Logcat ────────────────────────────────────────

def logcat_monitor(duration: int = 30, filter_str: str = "BluetoothGatt"):
    """Мониторинг BLE логов Android через logcat."""
    if not check_device():
        return

    log.info(f"{BOLD}Мониторинг logcat ({duration} сек)...{NC}")
    log.info(f"{YELLOW}Фильтр: {filter_str}{NC}")
    log.info(f"{'=' * 60}")

    try:
        # Запускаем logcat с фильтром
        cmd = ["adb", "logcat", "-v", "time",
               f"-s", filter_str,
               "-T", "1"]
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )

        start_time = time.time()
        try:
            for line in iter(proc.stdout.readline, ''):
                if not line:
                    break
                print(f"  {line.rstrip()}")
                if time.time() - start_time > duration:
                    break
        finally:
            proc.terminate()
            proc.wait(timeout=5)

    except KeyboardInterrupt:
        log.info(f"\n{YELLOW}Прервано пользователем{NC}")
    except Exception as e:
        log.error(f"{RED}Ошибка: {e}{NC}")


# ─── BLE Scan через ADB ────────────────────────────

def ble_scan(duration: int = 10):
    """BLE-сканирование через ADB shell с hcitool или bluetoothctl."""
    if not check_device():
        return

    log.info(f"{BOLD}BLE сканирование через ADB ({duration} сек)...{NC}")

    # Попытка 1: через hcitool
    result = run_adb(["shell", "hcitool lescan --duplicates &"],
                     timeout=duration + 5)
    if result.returncode == 0:
        time.sleep(duration)
        run_adb(["shell", "pkill -INT hcitool 2>/dev/null || true"])

        result = run_adb(["shell", "hcitool lescan 2>&1 | head -50"])
        if result.stdout.strip():
            log.info(f"{GREEN}Устройства (hcitool):{NC}")
            for line in result.stdout.splitlines():
                if ":" in line and len(line) > 20:
                    print(f"  {line}")
                elif "LE Scan" in line:
                    continue
            return

    # Попытка 2: через bluetoothctl
    result = run_adb(["shell",
                      f"timeout {duration} bluetoothctl scan on 2>&1 | head -30"])
    if result.stdout.strip():
        log.info(f"{GREEN}Устройства (bluetoothctl):{NC}")
        for line in result.stdout.splitlines():
            if "Device" in line:
                print(f"  {line.strip()}")
        return

    # Попытка 3: через dumpsys
    log.info(f"{YELLOW}Попытка через dumpsys bluetooth_manager...{NC}")
    result = run_adb(["shell", "dumpsys bluetooth_manager | grep -i 'device:' | head -20"])
    if result.stdout.strip():
        for line in result.stdout.splitlines():
            print(f"  {line.strip()}")

    log.info(f"{YELLOW}Сканирование завершено{NC}")


# ─── GATT Services ─────────────────────────────────

def gatt_services(address: str):
    """Получение GATT-сервисов устройства через ADB."""
    if not check_device():
        return

    log.info(f"{BOLD}GATT-сервисы для {address}{NC}")

    # Способ через dumpsys
    result = run_adb(["shell", f"dumpsys bluetooth_manager | grep -A 200 '{address}'"])
    if result.stdout.strip():
        log.info(f"{GREEN}Информация из dumpsys:{NC}")
        for line in result.stdout.splitlines():
            line = line.strip()
            if line:
                print(f"  {line}")

    # Создаём скрипт для BLE-скана через Android API
    log.info(f"{YELLOW}Для полного GATT-обхода используй gatt-scan.py{NC}")


# ─── Bluetooth Control ─────────────────────────────

def bluetooth_toggle(action: str):
    """Включение/выключение Bluetooth."""
    if not check_device():
        return

    val = "1" if action == "on" else "0"
    cmds = [
        f"settings put global bluetooth_on {val}",
        f"svc bluetooth {action}",
    ]
    for cmd in cmds:
        run_adb(["shell", cmd])

    time.sleep(2)
    result = run_adb(["shell", "dumpsys bluetooth_manager | grep 'state:' | head -1"])
    state = result.stdout.strip() or "unknown"
    log.info(f"{GREEN}Bluetooth {action}: {state}{NC}")


# ─── Main ──────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Android BLE инструменты через ADB",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Примеры:
  python3 android-ble.py snoop-enable          # Включить BTSnoop
  python3 android-ble.py snoop-capture         # Скачать btsnoop
  python3 android-ble.py logcat                # Мониторинг GATT логов
  python3 android-ble.py logcat --filter BluetoothGatt --duration 60
  python3 android-ble.py scan                  # BLE-скан
  python3 android-ble.py bluetooth on          # Включить BT
  python3 android-ble.py bluetooth off         # Выключить BT
        """,
    )

    subparsers = parser.add_subparsers(dest="command", help="Команда")

    p_snoop = subparsers.add_parser("snoop-enable", help="Включить BTSnoop логи")
    p_snoop = subparsers.add_parser("snoop-capture", help="Скачать btsnoop логи")
    p_snoop.add_argument("--output", "-o", help="Файл для сохранения")

    p_logcat = subparsers.add_parser("logcat", help="Мониторинг BLE logcat")
    p_logcat.add_argument("--duration", "-t", type=int, default=30,
                          help="Длительность (сек)")
    p_logcat.add_argument("--filter", "-f", default="BluetoothGatt",
                          help="Фильтр logcat (по умолч. BluetoothGatt)")

    p_scan = subparsers.add_parser("scan", help="BLE сканирование")
    p_scan.add_argument("--duration", "-t", type=int, default=10,
                        help="Длительность (сек)")

    p_svc = subparsers.add_parser("services", help="GATT-сервисы")
    p_svc.add_argument("address", help="BLE-адрес устройства")

    p_bt = subparsers.add_parser("bluetooth", help="Управление Bluetooth")
    p_bt.add_argument("action", choices=["on", "off"], help="Вкл/Выкл")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    if args.command == "snoop-enable":
        snoop_enable()
    elif args.command == "snoop-capture":
        snoop_capture(args.output)
    elif args.command == "logcat":
        logcat_monitor(args.duration, args.filter)
    elif args.command == "scan":
        ble_scan(args.duration)
    elif args.command == "services":
        gatt_services(args.address)
    elif args.command == "bluetooth":
        bluetooth_toggle(args.action)


if __name__ == "__main__":
    main()
