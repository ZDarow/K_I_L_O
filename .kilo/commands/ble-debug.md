---
description: Debug BLE connection to any device — scan, connect, discover GATT, send commands, read notifications
version: 1.0.0
agent: ble-engineer
---

# BLE Debug

## 1. Сканирование устройств
```bash
# Через bluetoothctl
bluetoothctl scan on

# Через hcitool
hcitool lescan

# Через Python (Bleak)
python3 -c "
import asyncio
from bleak import BleakScanner
devices = asyncio.run(BleakScanner.discover(timeout=5))
for d in devices: print(f'{d.name} [{d.address}] RSSI={d.rssi}')
"
```

## 2. Подключение и GATT discovery
```bash
bluetoothctl connect <MAC>
bluetoothctl info <MAC>
bluetoothctl menu gatt
# list-attributes — просмотр всех сервисов и характеристик

# Или через gatttool
gatttool -b <MAC> -t random --primary
gatttool -b <MAC> -t random --characteristics
```

## 3. Отправка произвольной команды
```bash
# Через gatttool (HEX)
gatttool -b <MAC> -t random --char-write-req \
  --handle=0xNNNN \
  --value=<HEX_STRING>

# Через Python (Bleak) — универсальный скрипт
python3 -c "
import asyncio
from bleak import BleakScanner, BleakClient

async def main():
    target = input('Device name/MAC: ')
    devices = await BleakScanner.discover(timeout=5)
    dev = next((d for d in devices if target.lower() in (d.name or '').lower() or target == d.address), None)
    if not dev: print('Not found'); return
    print(f'Connecting to {dev.name} [{dev.address}]...')
    async with BleakClient(dev.address) as client:
        print(f'Connected. Services:')
        for s in client.services:
            print(f'  {s.uuid}')
            for c in s.characteristics:
                print(f'    {c.uuid} props={c.properties}')
        # Отправка данных в характеристику
        chr_uuid = input('Characteristic UUID: ')
        data = bytes.fromhex(input('HEX data: '))
        await client.write_gatt_char(chr_uuid, data)
        print(f'Sent: {data.hex()}')
        # Чтение нотификаций
        def notify(sender, data):
            print(f'Notify: {data.hex()}')
        await client.start_notify(chr_uuid, notify)
        await asyncio.sleep(5)
        await client.stop_notify(chr_uuid)

asyncio.run(main())
"
```

## 4. Мониторинг трафика
```bash
btmon -T -w /tmp/ble_trace.log &
# Выполни действия на устройстве, затем:
kill %1
# Анализируй лог:
cat /tmp/ble_trace.log | head -50
```

## 5. Анализ протокола
1. Определи UUID сервисов и характеристик
2. Сравни с Bluetooth SIG (16-bit) — если не найден, значит vendor-specific
3. Отправляй write/read и анализируй ответ
4. Построй карту характеристик: какие на чтение, запись, нотификацию

## 6. Полезные ссылки
- Bluetooth SIG: https://www.bluetooth.com/specifications/assigned-numbers/
- BLE-инструменты в навыке `ble-engineering`
