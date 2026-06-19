---
description: Capture and analyze BLE traffic via btmon
version: 1.0.0
agent: ble-engineer
---

# BLE Capture

1. Определи доступные адаптеры:
   ```bash
   hciconfig 2>/dev/null || bluetoothctl list
   ```
2. Запусти захват:
   ```bash
   btmon -T -w /tmp/ble_capture.log &
   BTMON_PID=$!
   ```
3. Дай инструкцию пользователю: «Выполните действие на устройстве, затем нажмите Enter»
4. Останови захват:
   ```bash
   kill $BTMON_PID 2>/dev/null || true
   ```
5. Сконвертируй в PCAP (см. скрипт в gatt-discover)
6. Проанализируй: GATT-сервисы, характеристики, вендор-специфичные HCI
7. Сохрани отчёт в `ble-project/`
