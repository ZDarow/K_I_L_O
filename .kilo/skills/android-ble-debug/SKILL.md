---
name: android-ble-debug
description: "Android BLE отладка — btsnoop, logcat, ADB трассировка, анализ GATT через Android стек"
version: 1.0.0
tags: [android, ble, bluetooth, gatt, adb, debugging, btsnoop]
tools_required: [adb, bluetoothctl, wireshark, tshark, python3]
---

# Android BLE Debug — отладка Bluetooth на Android

## Назначение

Диагностика и анализ BLE-соединений на Android-устройствах. Включение btsnoop логов, захват HCI трафика через ADB, анализ logcat фильтров BluetoothGatt, восстановление GATT-профилей из Android-дампа.

---

## 1. Включение BTSnoop логов

### Через ADB (режим разработчика)
```bash
# Включить btsnoop (Android 8+)
adb shell settings put global ble_snoop_log_path /data/misc/bluetooth/logs/btsnoop_hci.log
adb shell settings put global btsnoop_log_duration 600  # секунд
adb shell settings put global btsnoop_log_max_size 10000000  # байт

# Перезапустить Bluetooth
adb shell svc bluetooth disable
adb shell svc bluetooth enable

# Выполнить взаимодействие с BLE устройством...
# Остановить логирование
adb shell settings put global btsnoop_log_path /data/misc/bluetooth/logs/btsnoop_hci.cfa
```

### Через инженерное меню
```bash
# Открыть инженерное меню
adb shell am start -n com.android.bluetooth/.btservice.BluetoothBtsnoopSettings

# Или через приложение "Настройки" → "Для разработчиков"
# Включить "Запись лога HCI Bluetooth snoop"
```

### Просмотр логов
```bash
# Скачать btsnoop файл
adb pull /data/misc/bluetooth/logs/btsnoop_hci.log /tmp/btsnoop_hci.log

# Анализ через tshark
tshark -r /tmp/btsnoop_hci.log -Y "btatt" -T fields \
  -e frame.number -e btatt.opcode -e btatt.handle -e btatt.value

# Открыть в Wireshark
wireshark /tmp/btsnoop_hci.log
```

---

## 2. Logcat фильтры Bluetooth

```bash
# Все Bluetooth логи
adb logcat -s BluetoothGatt:S BluetoothAdapter:S BtGatt:S

# Расширенная трассировка GATT
adb logcat -s BluetoothGatt:S BtGatt:S BtGatt.GattService:S

# HCI логи
adb logcat -s Hci:V BtHci:V

# Broadcast-ы Bluetooth
adb logcat -s BluetoothBroadcastReceiver:S

# Пакетный захват (сохранить в файл)
adb logcat -s BluetoothGatt:S > /tmp/ble_gatt.log

# Фильтр по PID (если известно приложение)
adb logcat --pid=$(adb shell pidof -s com.example.app) -s BluetoothGatt:S
```

---

## 3. Инструменты для анализа

### Python-скрипт для парсинга btsnoop
```python
#!/usr/bin/env python3
"""Парсинг BTSnoop логов и извлечение GATT операций."""

import struct
import sys

def parse_btsnoop(filename):
    """Парсинг btsnoop формата и извлечение HCI/ACL пакетов."""
    with open(filename, 'rb') as f:
        header = f.read(16)
        if header[:8] != b'btsnoop\x00':
            print("Неверный формат btsnoop")
            return
        
        while True:
            # Заголовок пакета (24 байта)
            pkt = f.read(24)
            if len(pkt) < 24:
                break
            
            orig_len = struct.unpack('>I', pkt[0:4])[0]
            incl_len = struct.unpack('>I', pkt[4:8])[0]
            flags = struct.unpack('>I', pkt[8:12])[0]
            drops = struct.unpack('>I', pkt[12:16])[0]
            
            data = f.read(incl_len)
            direction = 'SENT' if (flags & 1) else 'RECV'
            
            # HCI ACL пакет (4 байта заголовок)
            if incl_len >= 4:
                hci_type = data[0]
                if hci_type == 0x02:  # ACL data
                    handle = struct.unpack('<H', data[1:3])[0] & 0x0FFF
                    pb_flag = (data[1] >> 4) & 0x03
                    length = data[3]
                    
                    # L2CAP (4 байта)
                    if incl_len >= 8:
                        l2cap_len = struct.unpack('<H', data[4:6])[0]
                        cid = struct.unpack('<H', data[6:8])[0]
                        
                        if cid == 0x0004:  # ATT
                            att_data = data[8:8+l2cap_len]
                            if att_data:
                                opcode = att_data[0]
                                op_names = {
                                    0x01: 'Read Request',
                                    0x02: 'Read Response',
                                    0x03: 'Write Request',
                                    0x04: 'Write Response',
                                    0x0B: 'Write Command',
                                    0x0D: 'Read by Type Request',
                                    0x0E: 'Read by Type Response',
                                    0x10: 'Read by Group Type Request',
                                    0x11: 'Read by Group Type Response',
                                    0x12: 'Find by Type Value Request',
                                }
                                op_name = op_names.get(opcode, f'Unknown(0x{opcode:02X})')
                                print(f"[{direction}] ATT {op_name} | handle=0x{handle:04X} | data={att_data.hex()}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Использование: python3 btsnoop_parser.py <btsnoop_file>")
        sys.exit(1)
    parse_btsnoop(sys.argv[1])
```

### Wireshark display filters
```bash
# BLE ATT операции
btatt

# GATT чтение/запись
btatt.opcode == 0x02 || btatt.opcode == 0x12

# Подключения
btl2cap

# HCI команды
bthci_cmd

# Фильтр по handle
btatt.handle == 0x0024

# Все операции с конкретным устройством
btcommon.eir_ad.advertising_data && btle.advertising_header
```

---

## 4. Восстановление GATT из Android стека

### Из btsnoop
```bash
# Шаг 1: Извлечь все ATT операции
tshark -r btsnoop_hci.log -Y "btatt" -T json > att_ops.json

# Шаг 2: Собрать дерево сервисов
python3 << 'EOF'
import json

with open('att_ops.json') as f:
    data = json.load(f)

services = {}
chars = {}
descs = {}

for pkt in data:
    layers = pkt.get('_source', {}).get('layers', {})
    att = layers.get('btatt', {})
    
    if 'btatt.opcode' in att:
        opcode = int(att['btatt.opcode'], 16)
        handle = int(att.get('btatt.handle', '0'), 16)
        
        # Read by Group Type Response — объявление сервиса
        if opcode == 0x11 and 'btatt.value' in att:
            val = att['btatt.value'].replace(':', '')
            services[handle] = val
        
        # Read by Type Response — характеристика
        if opcode == 0x0E and 'btatt.value' in att:
            val = att['btatt.value'].replace(':', '')
            chars[handle] = val

print("=== Services ===")
for h, v in sorted(services.items()):
    print(f"  Handle 0x{h:04X}: {v}")

print("\n=== Characteristics ===")
for h, v in sorted(chars.items()):
    print(f"  Handle 0x{h:04X}: {v}")
EOF
```

### Из logcat
```bash
# Захват GATT discovery из лога
adb logcat -s BluetoothGatt:S BtGatt:S > /tmp/gatt_discovery.log &
# ...запустить приложение...
kill %1

# Извлечение сервисов
grep -i "onServicesDiscovered\|onCharacteristic" /tmp/gatt_discovery.log

# Извлечение UUID
grep -oP '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' /tmp/gatt_discovery.log | sort -u
```

---

## 5. Продвинутые техники

### Frida перехват BLE вызовов
```javascript
// frida_ble.js — перехват BLE GATT операций
if (Java.available) {
    Java.perform(function() {
        var BluetoothGatt = Java.use('android.bluetooth.BluetoothGatt');
        
        BluetoothGatt.discoverServices.implementation = function() {
            console.log('[BLE] discoverServices called');
            return this.discoverServices();
        };
        
        BluetoothGatt.setCharacteristicNotification.implementation = function(char, enable) {
            console.log('[BLE] setCharacteristicNotification: ' + 
                char.getUuid().toString() + ' enable=' + enable);
            return this.setCharacteristicNotification(char, enable);
        };
        
        BluetoothGatt.writeCharacteristic.implementation = function(char) {
            var uuid = char.getUuid().toString();
            var value = '';
            var val = char.getValue();
            if (val) {
                for (var i = 0; i < val.length; i++) {
                    value += ('0' + (val[i] & 0xFF).toString(16)).slice(-2);
                }
            }
            console.log('[BLE] writeCharacteristic: ' + uuid + ' value=' + value);
            return this.writeCharacteristic(char);
        };
        
        BluetoothGatt.readCharacteristic.implementation = function(char) {
            console.log('[BLE] readCharacteristic: ' + char.getUuid().toString());
            return this.readCharacteristic(char);
        };
    });
}
```

Запуск:
```bash
frida -U -l frida_ble.js com.example.app
```

### ADB BLE shell команды
```bash
# Сброс Bluetooth стека
adb shell svc bluetooth disable && sleep 2 && adb shell svc bluetooth enable

# Проверка состояния
adb shell dumpsys bluetooth_manager
adb shell dumpsys bluetooth | grep -i "state\|adapter\|gatt"

# Список сопряжённых устройств
adb shell dumpsys BluetoothAdapter

# LE scan через Android shell (требуется root)
adb shell hcitool lescan 2>/dev/null || echo "требуется root"
```

---

## Типовые проблемы и решения

| Проблема | Причина | Решение |
|----------|---------|---------|
| Не видно GATT сервисы | Не включён btsnoop | `settings put global ble_snoop_log_path ...` |
| Пустой btsnoop файл | Bluetooth не перезапущен | `svc bluetooth disable && svc bluetooth enable` |
| Нет logcat логов | Фильтр слишком узкий | Используй `-s BluetoothGatt:S BtGatt:V` |
| TIMEOUT при сканировании | Стек занят | Увеличь `btsnoop_log_duration` до 600+ |
| GATT 133 error | Неправильный handle | Проверь handle через read_by_type |
