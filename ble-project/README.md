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

# Быстрый запуск через Makefile
make ble-setup     # настройка окружения
make ble-scan      # сканирование устройств
make ble-test      # запуск тестов
```

## Структура

```
ble-project/
├── scripts/           # Скрипты настройки и анализа
│   ├── setup-env.sh       # Настройка Python-окружения
│   ├── activate.sh        # Активация виртуального окружения
│   ├── gatt-scan.py       # GATT-сканер (обнаружение + GATT-профиль)
│   ├── btmon-parse.py     # Парсер btmon логов (GATT-операции)
│   └── btsnoop-analyze.py # Анализатор btsnoop HCI-трафика
├── tests/             # Python-тесты BLE-инструментов
│   ├── __init__.py
│   └── test_ble_tools.py
├── gatt/              # Восстановленные GATT-профили (YAML)
│   └── xiaomi-miband6.yaml
├── logs/              # btmon/btsnoop/PCAP логи (заглушка)
├── protocol/          # Спецификации протоколов (заглушка)
├── firmware/          # ESP32 код и прошивки (заглушка)
├── android/           # Android-приложения/сервисы (заглушка)
├── bluez/             # Linux-агенты/плагины BlueZ (заглушка)
└── docs/              # Итоговая документация (заглушка)
```

## Инструменты

### gatt-scan.py — GATT-сканер

```
python3 scripts/gatt-scan.py scan          # Сканирование BLE-устройств
python3 scripts/gatt-scan.py discover -a AA:BB:CC:DD:EE:FF  # GATT-профиль
python3 scripts/gatt-scan.py discover -n "MyDevice"         # Поиск по имени
python3 scripts/gatt-scan.py monitor       # Мониторинг в реальном времени
```

Обнаруживает BLE-устройства, подключается и обходит GATT-сервисы,
характеристики и дескрипторы с чтением значений.

### btmon-parse.py — парсер btmon логов

```
python3 scripts/btmon-parse.py capture.log          # Сводка GATT-операций
python3 scripts/btmon-parse.py capture.log --format json  # JSON-вывод
btmon | python3 scripts/btmon-parse.py --stdin      # Pipe из btmon
python3 scripts/btmon-parse.py capture.log --filter gatt   # Только GATT
```

Парсит вывод btmon и извлекает GATT: read/write/notify/indicate + MTU,
HCI-события и ACL-пакеты с Handle-ами.

### btsnoop-analyze.py — анализатор btsnoop

```
python3 scripts/btsnoop-analyze.py /sdcard/btsnoop_hci.log  # Android log
python3 scripts/btsnoop-analyze.py capture.cfa --gatt-only   # Только GATT
python3 scripts/btsnoop-analyze.py dump.pcap --format json   # JSON
```

Парсит btsnoop/PCAP/hex файлы с HCI-трафиком, извлекает GATT-операции,
advertising reports, L2CAP + ATT.

## Зависимости

```bash
# Системные
sudo apt install bluez bluez-tools bluez-hcidump tshark cmake python3-venv

# Python (устанавливаются через make ble-setup или setup-env.sh)
pip install bleak bumble bleson pyyaml
```

## Тестирование

```bash
make ble-test                    # Через Makefile
cd ble-project && python3 -m pytest tests/ -v    # Pytest
cd ble-project && python3 -m unittest discover -s tests -v  # Unittest
```

## Makefile цели

```
make ble-setup       — Создание .venv и установка зависимостей
make ble-test        — Запуск тестов BLE-инструментов
make ble-scan        — Сканирование BLE-устройств (требует HCI)
make ble-venv-check  — Проверка виртуального окружения
```

## Агенты KiloCode

- `ble-engineer` — BLE/Bluetooth reverse engineering (ESP32, Android, BlueZ)
- `gatt-recovery` — GATT profile recovery из BLE-трафика
- `ble-specialist` — Эксперт по BLE/GATT реверс-инжинирингу
