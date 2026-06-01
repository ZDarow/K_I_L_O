---
description: Capture and analyze BLE traffic
agent: ble-engineer
---

1. Определи доступные адаптеры BLE:
   ```bash
   hciconfig 2>/dev/null || bluetoothctl list
   ```
2. Запусти захват трафика:
   ```bash
   btmon -T -w /tmp/ble_capture.log &
   BTMON_PID=$!
   ```
3. Дай инструкцию пользователю: «Выполните действие на устройстве, затем нажмите Enter»
4. Останови захват:
   ```bash
   kill $BTMON_PID
   ```
5. Сконвертируй в PCAP:
   ```bash
    python3 -c "
import struct, sys

# Глобальный заголовок PCAP (little-endian)
PCAP_MAGIC = 0xa1b2c3d4
PCAP_VERSION_MAJOR = 2
PCAP_VERSION_MINOR = 4
PCAP_SNAPLEN = 65535
PCAP_LINKTYPE = 201  # LINKTYPE_BLUETOOTH_HCI_H4

with open('/tmp/ble_capture.log') as f:
    lines = f.readlines()

with open('/tmp/ble_capture.pcap', 'wb') as out:
    # Пишем глобальный заголовок PCAP
    out.write(struct.pack('<IHHIIII',
        PCAP_MAGIC, PCAP_VERSION_MAJOR, PCAP_VERSION_MINOR,
        0, 0, PCAP_SNAPLEN, PCAP_LINKTYPE))

    for line in lines:
        # Парсим строку btmon: ищем HEX-дамп пакета
        if '<' in line or '>' in line:
            # Извлекаем HEX из строки btmon
            hex_bytes = []
            for word in line.split():
                try:
                    if len(word) == 2:
                        int(word, 16)
                        hex_bytes.append(int(word, 16))
                except ValueError:
                    continue
            if hex_bytes:
                ts_sec = 0
                ts_usec = 0
                incl_len = len(hex_bytes)
                orig_len = incl_len
                out.write(struct.pack('<IIII', ts_sec, ts_usec, incl_len, orig_len))
                out.write(bytes(hex_bytes))

print(f'Конвертировано {len(lines)} строк в PCAP')
    "
    ```
6. Проанализируй:
   - Извлеки GATT-сервисы и характеристики
   - Определи соединения и параметры
   - Найди вендор-специфичные HCI-команды
7. Сохрани отчёт: `analysis/gatt_profile.yaml`, `analysis/connection_params.txt`
