# Bluetooth Classic Analysis Report

## 1. Capture Info
- **File**: `{{capture_file}}`
- **Duration**: {{duration_sec}}s
- **Total packets**: {{total_packets}}
- **Capture method**: {{capture_method}}

## 2. Device Discovery (Inquiry)
| Device | Class | RSSI | Services |
|--------|-------|------|----------|
| {{addr}} | {{cod}} | {{rssi}} | {{services}} |

## 3. Connections
| # | Source | Destination | Link Type | Role |
|---|--------|------------|-----------|------|
| 1 | {{addr}} | {{addr}} | ACL/SCO | Master/Slave |

## 4. SDP Services Discovered
| Service | UUID | Channel | Protocol |
|---------|------|---------|----------|
| {{name}} | {{uuid}} | PSMM {{psm}} / RFCOMM {{channel}} | {{proto}} |

## 5. RFCOMM Sessions
| DLCI | Direction | State | Data Packets |
|------|-----------|-------|-------------|
| {{dlci}} | {{dir}} | {{state}} | {{count}} |

## 6. L2CAP Channels
| SCID/DCID | PSM | State | Mode |
|-----------|-----|-------|------|
| 0x{{scid}}/0x{{dcid}} | {{psm}} | {{state}} | {{mode}} |

## 7. Audio (if A2DP/HSP/HFP)
- Codec: {{codec}} (SBC/AAC/aptX/LDAC)
- Bitrate: {{bitrate}} kbps
- Sampling: {{sampling}} Hz

## 8. Key Findings
- {{finding}}

## 9. Conclusion
{{conclusion}}
