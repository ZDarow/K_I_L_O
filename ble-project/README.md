# BLE Engineering Project

Создано агентом `ble-engineer`.

## Статус окружения (текущая сессия)

- **ОС:** Linux Mint 22.3 (Ubuntu 24.04)
- **BlueZ:** установлен (bluetoothctl, btmon, gatttool, hciconfig)
- **Bluetooth-сервис:** неактивен (systemctl start bluetooth)
- **BLE-адаптер:** не обнаружен
- **Python:** 3.12, без pip (требуется sudo apt install python3.12-venv)
- **tshark, cmake:** не установлены

## Быстрый старт

```bash
# Установка всего окружения
./scripts/setup-env.sh

# Активация Python-окружения
source .venv/bin/activate
```

## Структура

```
ble-project/
├── logs/        # btmon/btsnoop/PCAP
├── gatt/        # Восстановленные GATT-профили
├── protocol/    # Спецификации протоколов
├── firmware/    # ESP32 код
├── android/     # Android-приложения
├── bluez/       # Linux-агенты/плагины
├── scripts/     # Скрипты анализа
└── docs/        # Документация
```
