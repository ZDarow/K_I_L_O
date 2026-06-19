# BLE Реинжениринг — справочник

## GATT Discovery (типовой профиль)
```yaml
services:
  - uuid: 0x1800  # Generic Access
    characteristics:
      - uuid: 0x2A00  # Device Name
        properties: read
      - uuid: 0x2A01  # Appearance
        properties: read
  - uuid: custom-128bit
    characteristics:
      - uuid: <custom-uuid>
        properties: read/write/notify
        descriptors:
          - uuid: 0x2902  # CCCD
```

## HCI Command Groups
| Group | Code | Description |
|-------|------|-------------|
| Link Control | 0x01 | Create/accept/disconnect connection, LE advertising, scan |
| LE Controller | 0x08 | LE Set Scan Params, LE Create Connection, LE Read Buffer Size |
| Vendor Debug | 0xFF | VS-specific (ESP32, CSR, Broadcom, TI) |

## Полезные команды
```bash
# BlueZ
bluetoothctl scan on                    # LE scan
bluetoothctl pair <MAC>                  # Pair device
bluetoothctl connect <MAC>               # Connect
bluetoothctl info <MAC>                  # Device info + GATT services
bluetoothctl menu gatt                   # GATT explorer

# btmon
btmon                                     # Live monitor
btmon -T -w trace.log                     # Log to file
btmon -r trace.log                        # Replay
btmon -r trace.log --dump                 # Parse dump

# HCI raw
hcitool lescan                            # LE scan
hcitool lecc <MAC>                        # LE connect
gatttool -b <MAC> -t random --primary     # List services
gatttool -b <MAC> -t random --characteristics  # List characteristics

# ESP32
idf.py set-target esp32c3
idf.py menuconfig                          # BLE config
idf.py build && idf.py flash monitor

# Android
adb logcat -s BluetoothGatt               # BLE Gatt logs
adb shell settings put global ble_snoop_log_path /data/misc/bluetooth/logs/btsnoop_hci.log
adb shell settings put global btsnoop_log_duration 600
```

## Типовые паттерны реверса
1. Подключи btmon → запись трафика → анализ GATT
2. Сравни UUID с известными спецификациями (Bluetooth SIG, вендорские)
3. Если UUID не известен — отправляй write/read и анализируй ответ
4. Для ESP32: читай прошивку через esptool.py, ищи таблицы GATT в бинарнике
5. Для Android: btsnoop log → Wireshark → JSON → структура
