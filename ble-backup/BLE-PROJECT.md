# BLE-проект (ble-project/)

---

## Назначение

`ble-project/` — это рабочее пространство для BLE/Bluetooth-реинжениринга.
Устанавливается в `~/ble-project/` при установке KiloCode CLI.

---

## Структура

```text
~/ble-project/
├── scripts/
│   ├── setup-env.sh      # Настройка Python-окружения
│   └── activate.sh       # Активация виртуального окружения
├── logs/                 # btmon/btsnoop/PCAP логи
├── gatt/                 # Восстановленные GATT-профили (YAML/JSON)
├── protocol/             # Спецификация протокола
├── firmware/             # ESP32/микроконтроллерный код
├── android/              # Android-приложение/сервис
├── bluez/                # Linux-драйвер/агент/плагин
└── docs/                 # Итоговая документация
```

---

## Скрипты

### `scripts/setup-env.sh`

Настройка виртуального Python-окружения с BLE-библиотеками:

```bash
./scripts/setup-env.sh
```

**Устанавливаемые пакеты:**
| Пакет | Назначение |
|-------|-----------|
| bleak | BLE-клиент для Python |
| bumble | Реализация BLE-стека на Python |
| bleson | BLE-библиотека для Linux |
| pygatt | GATT-клиент через gatttool |
| bluepy | Интерфейс к BlueZ |
| pyshark | Анализ pcapng-файлов |

### `scripts/activate.sh`

Активация виртуального окружения:

```bash
source scripts/activate.sh
```

Или через алиас (после установки):
```bash
ble-activate
```

---

## Использование

### 1. Захват BLE-трафика

```bash
# Через btmon
btmon -T -w ~/ble-project/logs/capture_$(date +%Y%m%d_%H%M%S).log

# Через Python (Bleak)
python3 -c "
import asyncio
from bleak import BleakScanner
devices = asyncio.run(BleakScanner.discover(timeout=10))
for d in devices:
    print(f'{d.name} [{d.address}] RSSI={d.rssi}')
"
```

### 2. GATT Discovery

```bash
# Через bluetoothctl
bluetoothctl connect <MAC>
bluetoothctl menu gatt
# list-attributes

# Сохранение результата
gatttool -b <MAC> -t random --primary > ~/ble-project/gatt/<device>.txt
```

### 3. Анализ GATT-профиля

```bash
# Конвертация в YAML (через инструмент gatt-to-yaml)
/gatt-to-yaml --jsonPath ~/ble-project/gatt/<device>.json

# Сохранение профиля
# → ~/ble-project/gatt/<device>_<date>.yaml
```

### 4. ESP32-прошивка

```bash
cd ~/ble-project/firmware/
# Разработка прошивки в Arduino CLI или ESP-IDF
```

---

## Полезные алиасы (после установки)

```bash
ble-activate    # Активировать Python-окружение BLE
                # source ~/ble-project/scripts/activate.sh

ble-env         # Показать информацию о BLE-окружении
                # python3 -c "import bleak; print('Bleak OK')"

ble-project     # Перейти в ~/ble-project/
                # cd ~/ble-project/
```

---

## BLE-стек: используемые технологии

```text
Приложение
    │
    ├── Python (bleak, pygatt, bluepy)
    ├── Node.js (noble, bleno)
    └── C/C++ (BlueZ D-Bus API)
         │
    ┌────┴────┐
    │  BlueZ  │  (Linux Bluetooth stack)
    └────┬────┘
         │
    ┌────┴────┐
    │  HCI    │  (Host Controller Interface)
    └────┬────┘
         │
    ┌────┴────────┐
    │  Bluetooth  │
    │  Controller │  (USB/UART адаптер)
    └─────────────┘
```

---

## Типовой рабочий процесс

### 1. Разведка
```bash
btmon -T -w ~/ble-project/logs/explore.log &
bluetoothctl scan on
# ... найти устройство ...
kill %1
```

### 2. Подключение
```bash
bluetoothctl connect <MAC>
bluetoothctl info <MAC>
```

### 3. GATT Discovery
```bash
gatttool -b <MAC> -t random --primary
gatttool -b <MAC> -t random --characteristics
# Сохранить в ~/ble-project/gatt/
```

### 4. Анализ
- Определить UUID сервисов и характеристик
- Сравнить с Bluetooth SIG Assigned Numbers
- Построить карту GATT-профиля

### 5. Реализация
- ESP32: Arduino CLI / ESP-IDF firmware
- Android: BLE-приложение через Kotlin/Java
- Linux: BlueZ D-Bus агент/плагин

### 6. Документирование
```yaml
# ~/ble-project/gatt/<device>_<date>.yaml
device: "AA:BB:CC:DD:EE:FF"
services:
  - uuid: 0x1800
    name: "Generic Access"
    characteristics:
      - uuid: 0x2A00
        name: "Device Name"
        properties: read
```
