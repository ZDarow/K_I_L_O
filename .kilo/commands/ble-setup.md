---
description: Setup BLE development environment (ESP32, Android, BlueZ)
---

# BLE Setup — автонастройка окружения

1. Определи ОС и доступные инструменты
2. Установи базовый набор: bluez-tools, btmon, tshark, python3, pip
3. Установи Python-библиотеки: bleak, bumble, bleson, pygatt, bluepy
4. По платформе:
   - **ESP32**: клонируй ESP-IDF, установи toolchain
   - **Android**: проверь adb, установи platform-tools
   - **BlueZ**: проверь bluetoothd, dbus, libbluetooth-dev
5. Верифицируй: `btmon --version`, `bluetoothctl --version`, `python3 -c "import bleak"`
6. Создай структуру `ble-project/`
7. Верни отчёт: что установлено, что не удалось
