---
name: ble-engineering
description: Bluetooth/BLE протоколы, реинжениринг, GATT recovery, ESP32/Android/BlueZ разработка, общая разработка ПО
---

# BLE Engineering — универсальный навык

Используй для задач по BLE-реинженирингу, GATT recovery, разработке под ESP32/Android/BlueZ, и общей программной инженерии.

## Процесс

1. **Детекция платформы** — определи ОС, Bluetooth-стек, доступные инструменты
2. **Автонастройка** — разверни необходимое окружение
3. **Захват/анализ** — получи данные (btmon, PCAP, HEX, logcat)
4. **Восстановление** — извлеки GATT-структуру, UUID, протокол
5. **Реализация** — напиши совместимый код/драйвер/библиотеку
6. **Верификация** — проверь на реальном устройстве

## Инструменты по платформам

| Платформа | Инструменты |
|-----------|-------------|
| **BlueZ (Linux)** | bluetoothctl, btmon, gatttool, hcitool, D-Bus API |
| **ESP32** | ESP-IDF, NimBLE, Bluedroid, idf.py, esptool.py |
| **Android** | adb, btsnoop, nRF Connect, BluetoothGatt API |
| **Общие** | tshark, Wireshark, Python (bleak, bumble, bleson) |

## Типовые паттерны реверса

1. btmon → захват трафика → анализ GATT → YAML-профиль
2. BLE snoop log (Android) → Wireshark → JSON → структура
3. ESP32 прошивка → esptool.py → поиск GATT-таблиц
4. Неизвестный 128-bit UUID → write/read → анализ ответа

## GATT Recovery

```yaml
services:
  - uuid: "0x1800"  # Generic Access
    characteristics:
      - uuid: "0x2A00"  # Device Name
        properties: ["read"]
      - uuid: "0x2A01"  # Appearance  
        properties: ["read"]
  - uuid: "<128bit-uuid>"
    name: "Vendor Service"
    characteristics:
      - uuid: "<uuid>"
        properties: ["read", "write", "notify"]
        descriptors:
          - uuid: "0x2902"  # CCCD
```

## Ссылки

- Bluetooth SIG Assigned Numbers: https://www.bluetooth.com/specifications/assigned-numbers/
- ESP-IDF BLE docs: https://docs.espressif.com/projects/esp-idf/en/latest/api-guides/ble/index.html
- Android BLE: https://developer.android.com/guide/topics/connectivity/bluetooth/ble-overview
- BlueZ D-Bus API: https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/doc
