# ESP32 Firmware — BLE GATT Server & Scanner

Прошивки для ESP32, используемые для тестирования и реверс-инжиниринга
BLE/GATT протоколов.

## Структура

```
firmware/
├── esp32-gatt-server/
│   ├── esp32-gatt-server.ino    — GATT-сервер с кастомными сервисами
│   └── platformio.ini            — PlatformIO конфигурация (опционально)
└── esp32-ble-scanner/
    ├── esp32-ble-scanner.ino     — BLE-сканер с GATT-обходом
    └── platformio.ini            — PlatformIO конфигурация (опционально)
```

## Сборка и загрузка

### Через Arduino CLI

```bash
# Установка ESP32 ядра
arduino-cli core update-index
arduino-cli core install esp32:esp32

# GATT-сервер
arduino-cli compile --fbn esp32:esp32:esp32 ble-project/firmware/esp32-gatt-server/
arduino-cli upload --fbn esp32:esp32:esp32 -p /dev/ttyUSB0 ble-project/firmware/esp32-gatt-server/

# BLE-сканер
arduino-cli compile --fbn esp32:esp32:esp32 ble-project/firmware/esp32-ble-scanner/
arduino-cli upload --fbn esp32:esp32:esp32 -p /dev/ttyUSB0 ble-project/firmware/esp32-ble-scanner/
```

### Через PlatformIO

```bash
# Установка PlatformIO
pip install platformio

# GATT-сервер
cd ble-project/firmware/esp32-gatt-server/
pio run -t upload

# BLE-сканер
cd ble-project/firmware/esp32-ble-scanner/
pio run -t upload
```

### Через Arduino IDE

1. Открой File → Preferences → Additional Boards Manager URLs
2. Добавь: `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
3. Инструменты → Плата → ESP32 Arduino → выбери свою плату
4. Открой .ino файл, нажми Upload

## ESP32 GATT Server

Создаёт BLE-устройство с именем **"Kilo BLE Test"**.

### GATT-сервисы

| Сервис | UUID | Описание |
|--------|------|----------|
| Generic Access | 0x1800 | Имя устройства, Appearance |
| Device Information | 0x180A | Производитель, модель, серийный номер, версии |
| Battery Service | 0x180F | Battery Level (100%) |
| Custom Service | 0xFFE0 | Тестовый сервис для реверса |

### Кастомный сервис (0xFFE0)

| Характеристика | UUID | Свойства | Описание |
|---------------|------|----------|----------|
| Read Counter | 0xFFE1 | Read | Возвращает инкрементальный счётчик (4 байта LE) |
| Write No Resp | 0xFFE2 | Write NR | Запись без ответа (Write Command) |
| Write Response | 0xFFE3 | Write | Запись с ответом (Write Request) |
| Notify | 0xFFE4 | Notify, Read | Отправляет счётчик каждую секунду |
| Config | 0xFFE5 | Read, Write | Конфигурация (8 байт, сохраняется в NVS) |

### Использование для тестирования

```bash
# Сканирование
python3 ble-project/scripts/gatt-scan.py scan

# Discovery GATT-профиля
python3 ble-project/scripts/gatt-scan.py discover --name "Kilo BLE Test"

# Мониторинг btmon в реальном времени
btmon | python3 ble-project/scripts/btmon-parse.py --stdin --format summary
```

## ESP32 BLE Scanner

Интерактивный BLE-сканер через Serial (115200 baud).

### Команды

| Команда | Описание |
|---------|----------|
| `1` | Сканировать устройства (5 сек) |
| `2` | Подключиться к устройству по номеру |
| `3` | Мониторинг рекламных пакетов (30 сек) |
| `i` | Информация о текущем подключении |
| `g` | GATT-обход (список сервисов и характеристик) |
| `r` | Чтение характеристики по handle/UUID |
| `d` | Отключиться |
| `m` | Меню |

### Использование

```bash
# Подключение к ESP32 через Serial
screen /dev/ttyUSB0 115200
# или
minicom -D /dev/ttyUSB0 -b 115200
```

## Требования

- ESP32 DevKit v1, ESP32-C3, ESP32-S3 или любой совместимый модуль
- USB-UART адаптер (обычно встроен в плату)
- Arduino CLI 1.x или PlatformIO
- Python 3.x (для инструментов анализа)
