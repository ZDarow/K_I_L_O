---
description: Run GATT discovery on a BLE device and save profile
version: 1.0.0
agent: gatt-recovery
---

# GATT Discovery

## Usage
```bash
# Discover all services and characteristics
bluetoothctl connect <MAC>
bluetoothctl menu gatt
# Then: list-attributes / select-service / list-characteristics

# OR using gatttool
gatttool -b <MAC> -t random --primary
gatttool -b <MAC> -t random --characteristics

# OR using btmon + bluetoothctl
btmon -T -w /tmp/gatt_discovery.log &
bluetoothctl connect <MAC>
bluetoothctl info <MAC>
kill %1  # stop btmon
```

## Automated discovery script
```python
#!/usr/bin/env python3
"""Automated GATT discovery via gatttool output"""
import subprocess, json, sys, os

MAC = sys.argv[1] if len(sys.argv) > 1 else None
if not MAC:
    print("Usage: python3 gatt_discover.py <MAC>")
    sys.exit(1)

# Primary services
out = subprocess.check_output(
    ["gatttool", "-b", MAC, "-t", "random", "--primary"],
    stderr=subprocess.DEVNULL
).decode()

services = []
for line in out.strip().split('\n'):
    if not line.strip(): continue
    parts = line.split()
    if len(parts) >= 3:
        handle = parts[0].rstrip(',')
        uuid = parts[2]
        services.append({"handle": handle, "uuid": uuid})

# Characteristics
out = subprocess.check_output(
    ["gatttool", "-b", MAC, "-t", "random", "--characteristics"],
    stderr=subprocess.DEVNULL
).decode()

chars = []
for line in out.strip().split('\n'):
    if not line.strip(): continue
    parts = line.split()
    if len(parts) >= 4:
        # handle: 0x0001, char properties: 0x02, char value handle: 0x0002, uuid: 0x2a00
        h = parts[0].rstrip(',')
        props = parts[3].rstrip(',')
        uuid = parts[4] if len(parts) > 4 else '?'
        chars.append({"handle": h, "properties": props, "uuid": uuid})

# Save result
result = {"device": MAC, "services": services, "characteristics": chars}
out_path = f"ble-project/gatt/{MAC.replace(':', '')}_{__import__('datetime').datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
os.makedirs("ble-project/gatt", exist_ok=True)
with open(out_path, 'w') as f:
    json.dump(result, f, indent=2)
print(f"GATT profile saved: {out_path}")
print(f"Services: {len(services)}, Characteristics: {len(chars)}")
```

## Output
- JSON: `ble-project/gatt/<MAC>_<timestamp>.json`
- Convert to YAML for analysis
