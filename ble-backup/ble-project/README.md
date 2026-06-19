# BLE Engineering Project

BLE-проект для реверс-инжиниринга Bluetooth Low Energy устройств.
Устанавливается в `~/ble-project/` установщиком KiloCode CLI.

## Быстрый старт

```bash
# Настройка Python-окружения
./scripts/setup-env.sh

# Активация виртуального окружения
source .venv/bin/activate

# Или через alias (после source ~/.bashrc)
ble-activate
```

## Структура

```text
ble-project/
├── scripts/       # Скрипты настройки и анализа
├── logs/          # btmon/btsnoop/PCAP логи
├── gatt/          # Восстановленные GATT-профили
├── protocol/      # Спецификации протоколов
├── firmware/      # ESP32 код и прошивки
├── android/       # Android-приложения/сервисы
├── bluez/         # Linux-агенты/плагины BlueZ
└── docs/          # Итоговая документация
```

## Зависимости

Устанавливаются через `install.sh` или вручную:

```bash
# Системные
sudo apt install bluez bluez-tools bluez-hcidump tshark cmake python3-venv

# Python
pip install bleak bumble bleson pygatt bluepy
```

## Агенты KiloCode

- `ble-engineer` — BLE/Bluetooth reverse engineering (ESP32, Android, BlueZ)
- `gatt-recovery` — GATT profile recovery из BLE-трафика
