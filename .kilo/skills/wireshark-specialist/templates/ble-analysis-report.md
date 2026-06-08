# BLE Analysis Report

## 1. Capture Info
- **File**: `{{capture_file.pcapng}}`
- **Duration**: {{duration_sec}}s
- **Packets**: {{total_packets}}
- **BLE packets**: {{ble_packets}} ({{ble_percent}}%)
- **Captured via**: {{capture_method}} (btmon/tshark/android)

## 2. BLE Devices
| Role | BD_ADDR (Random/Public) | Name (AD) | Packets |
|------|------------------------|-----------|---------|
| Central | {{addr}} | {{name}} | {{count}} |
| Peripheral | {{addr}} | {{name}} | {{count}} |

## 3. Connection Parameters
- Interval: {{conn_interval}} ms ({{interval_raw}} × 1.25ms)
- Latency: {{latency}}
- Supervision Timeout: {{timeout}} ms
- PHY: {{phy}} (1M/2M/Coded)
- Channel Map: {{channel_map}}

## 4. GATT Services Discovered
| Start Handle | End Handle | UUID | Name |
|-------------|-----------|------|------|
| 0x{{s}} | 0x{{e}} | {{uuid}} | {{name}} |

## 5. Characteristics
| Handle | UUID | Properties | Value Handle | Initial Value |
|--------|------|-----------|-------------|--------------|
| 0x{{h}} | {{uuid}} | {{props}} | 0x{{vh}} | {{value}} |

## 6. Data Exchange
| Time | Dir | Opcode | Handle | UUID | Data |
|------|-----|--------|--------|------|------|
| {{t}} | C→P | WriteReq | 0x{{h}} | {{uuid}} | {{hex}} |
| {{t}} | P→C | Notif | 0x{{h}} | {{uuid}} | {{hex}} |

## 7. Pairing (SMP)
- Method: {{pairing_method}} (Just Works/Passkey/OOB/Numeric Comparison)
- Security: {{security_level}} (LE Legacy/LE Secure Connections)
- MITM Protection: {{mitm}}
- Bonding: {{bonding}}

## 8. Anomalies
- {{issue}}
- {{issue}}

## 9. Conclusions
{{conclusions}}
