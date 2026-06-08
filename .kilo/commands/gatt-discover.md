---
description: Run GATT discovery on a BLE device, save profile to YAML/JSON
version: 1.0.0
agent: dev
---

# GATT Discovery

## Ручной режим
```bash
bluetoothctl connect <MAC>
bluetoothctl menu gatt
# list-attributes / select-service / list-characteristics

# Или gatttool
gatttool -b <MAC> -t random --primary
gatttool -b <MAC> -t random --characteristics
```

## Автоматический режим
```python
#!/usr/bin/env python3
"""GATT discovery via gatttool"""
import subprocess, json, sys, os
from datetime import datetime

MAC = sys.argv[1] if len(sys.argv) > 1 else None
if not MAC:
    print("Usage: python3 gatt_discover.py <MAC>")
    sys.exit(1)

out = subprocess.check_output(
    ["gatttool", "-b", MAC, "-t", "random", "--primary"],
    stderr=subprocess.DEVNULL
).decode()
services = []
for line in out.strip().split('\n'):
    if not line.strip(): continue
    parts = line.split()
    if len(parts) >= 3:
        services.append({"handle": parts[0].rstrip(','), "uuid": parts[2]})

out = subprocess.check_output(
    ["gatttool", "-b", MAC, "-t", "random", "--characteristics"],
    stderr=subprocess.DEVNULL
).decode()
chars = []
for line in out.strip().split('\n'):
    if not line.strip(): continue
    parts = line.split()
    if len(parts) >= 4:
        chars.append({
            "handle": parts[0].rstrip(','),
            "properties": parts[3].rstrip(','),
            "uuid": parts[4] if len(parts) > 4 else '?'
        })

result = {"device": MAC, "services": services, "characteristics": chars}
ts = datetime.now().strftime('%Y%m%d_%H%M%S')
out_path = f"ble-project/gatt/{MAC.replace(':', '')}_{ts}.json"
os.makedirs("ble-project/gatt", exist_ok=True)
with open(out_path, 'w') as f:
    json.dump(result, f, indent=2)
print(f"GATT profile saved: {out_path}")
print(f"Services: {len(services)}, Characteristics: {len(chars)}")
```

## Результат
- JSON: `ble-project/gatt/<MAC>_<timestamp>.json`
- Конвертируй в YAML для анализа
