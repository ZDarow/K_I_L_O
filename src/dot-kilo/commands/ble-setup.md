---
description: Setup BLE development environment (ESP32, Android, BlueZ)
version: 1.0.0
agent: ble-engineer
---

Выполни автонастройку окружения для BLE-разработки:

1. Определи текущую ОС и доступные инструменты
2. Установи базовый набор: bluez-tools, btmon, tshark, python3-bleak
3. Настрой Python-окружение: virtualenv, bleak, bumble, bleson
4. Если указана платформа — разверни:
   - ESP32: клонируй ESP-IDF, установи toolchain
   - Android: проверь adb, установи platform-tools
   - BlueZ: проверь bluetoothd, dbus, установи libbluetooth-dev
5. Верифицируй: `btmon --version`, `bluetoothctl --version`, `python3 -c "import bleak"`
6. Создай структуру проекта `ble-project/` с поддиректориями
7. Верни отчёт: что установлено, что не удалось, какие порты/сервисы доступны
