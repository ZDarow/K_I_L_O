# BLE Protocol Reference Guide

## BLE Stack

```
+------------------------------------------------------------------+
|                        APPLICATION                               |
+------------------------------------------------------------------+
|  GAP (Generic Access Profile)    |  GATT (Generic Attribute Profile) |
+------------------------------------------------------------------+
|  SM (Security Manager)           |  ATT (Attribute Protocol)        |
+------------------------------------------------------------------+
|  L2CAP (Logical Link Control & Adaptation Protocol)               |
+------------------------------------------------------------------+
|  Link Layer (LL)                                                  |
+------------------------------------------------------------------+
|  PHY (1M / 2M / Coded)                                           |
+------------------------------------------------------------------+
```

## BLE Phases

### 1. Advertising (Broadcaster → Observer)
```
PDU Types:
- ADV_IND        (0x00): Connectable undirected
- ADV_DIRECT_IND (0x01): Connectable directed
- ADV_NONCONN_IND(0x02): Non-connectable
- ADV_SCAN_IND   (0x06): Scannable undirected
- SCAN_REQ       (0x03): Scan request
- SCAN_RSP       (0x04): Scan response
- CONNECT_REQ    (0x05): Connection request
```

### 2. Connection (Central ↔ Peripheral)
CONNECT_REQ fields:
- InitA: Initiator address
- AdvA: Advertiser address
- AA: Access Address (32-bit)
- CRCInit: CRC initialization
- WinSize: Transmit window size
- WinOffset: Transmit window offset
- Interval: Connection interval (1.25ms units)
- Latency: Connection slave latency
- Timeout: Supervision timeout (10ms units)
- ChM: Channel map (37 channels)
- Hop: Hop increment (5-16)
- SCA: Sleep clock accuracy

### 3. Data Exchange
LL Data PDU:
- LLID (2 bits): 00=LL Data, 01=LL Data (continuation), 10=LL Control
- NESN/SN: Flow control
- MD: More data flag

## BLE L2CAP

Fixed Channels:
- 0x0004: ATT
- 0x0005: LE Signaling
- 0x0006: SMP

Signaling commands (CID 0x0005):
- 0x01: Reject
- 0x02: Connection Request
- 0x03: Connection Response
- 0x04: Configuration Request
- 0x05: Configuration Response
- 0x0A: Disconnection Request
- 0x0B: Disconnection Response
- 0x12: LE Credit Based Connection Request
- 0x13: LE Credit Based Connection Response

## ATT Protocol

### General
- Client → Server: requests, writes, commands
- Server → Client: responses, notifications, indications

### ATT PDUs
| Opcode | Name | Direction |
|--------|------|-----------|
| 0x01 | Read by Group Type Request | C→S |
| 0x02 | Read by Group Type Response | S→C |
| 0x03 | Read by Type Request | C→S |
| 0x04 | Read by Type Response | S→C |
| 0x08 | Read Request | C→S |
| 0x09 | Read Response | S→C |
| 0x0A | Read Blob Request | C→S |
| 0x0B | Read Blob Response | S→C |
| 0x0C | Read Multiple Request | C→S |
| 0x0D | Read Multiple Response | S→C |
| 0x0E | Read by Group Type Request | C→S |
| 0x10 | Write Request | C→S |
| 0x11 | Write Response | S→C |
| 0x12 | Write Command | C→S |
| 0x13 | Signed Write Command | C→S |
| 0x14 | Prepare Write Request | C→S |
| 0x15 | Prepare Write Response | S→C |
| 0x16 | Execute Write Request | C→S |
| 0x17 | Execute Write Response | S→C |
| 0x18 | Handle Value Notification | S→C |
| 0x19 | Handle Value Indication | S→C |
| 0x1A | Handle Value Confirmation | C→S |
| 0x1B | Write Command | C→S |
| 0x52 | Exchange MTU Request | C→S |
| 0x53 | Exchange MTU Response | S→C |

### ATT Header Format
```
Byte 0:    Opcode
Bytes 1-2: Handle (for requests targeting specific handle)
Bytes 3+:  Value / Data
```

## GATT Profile Hierarchy

```
Service (UUID)
├── Characteristic (UUID + Properties)
│   ├── Value (handle)
│   ├── Descriptor: Client Characteristic Configuration (0x2902)
│   ├── Descriptor: Server Characteristic Configuration (0x2903)
│   └── Descriptor: Characteristic User Description (0x2901)
└── Characteristic (UUID + Properties)
    └── ...
```

### Characteristic Properties
| Bit | Property | Meaning |
|-----|----------|---------|
| 0x01 | Broadcast | Permits broadcasts |
| 0x02 | Read | Permits reads |
| 0x04 | Write Without Response | Permits writes without ack |
| 0x08 | Write | Permits writes with ack |
| 0x10 | Notify | Permits notifications |
| 0x20 | Indicate | Permits indications |
| 0x40 | Authenticated Signed Writes | Permits signed writes |
| 0x80 | Extended Properties | More properties in descriptor |

### CCCD (Client Characteristic Configuration) 0x2902
- 0x0000: Disable notifications/indications
- 0x0001: Enable notifications
- 0x0002: Enable indications

## Security Manager Protocol (SMP)

### Pairing Flow (LE Legacy)
```
Phase 1: Pairing Feature Exchange
  C→S: Pairing Request (IO Capability, OOB, AuthReq, KeySize, InitKeyDist)
  S→C: Pairing Response (IO Capability, OOB, AuthReq, KeySize, RespKeyDist)

Phase 2: Short Term Key (STK) Generation
  - Just Works: STK = s1(TK=0, rand1, rand2)
  - Passkey: TK = 6-digit pin, authenticated
  - OOB: TK from out-of-band

Phase 3: Transport Specific Key Distribution
  - LTK (Long Term Key)
  - EDIV + RAND
  - IRK (Identity Resolving Key)
  - CSRK (Connection Signature Resolving Key)
```

### Pairing Flow (LE Secure Connections, BT 4.2+)
```
Phase 1: Feature Exchange (same as Legacy)

Phase 2: LTK Generation (ECDH)
  - Numeric Comparison: display 6-digit, user confirms
  - Passkey: enter 6-digit
  - Just Works: no authentication
  - OOB: NFC or other

Phase 3: Key Distribution
  - LTK, EDIV, RAND, IRK, CSRK
```

### SMP Commands
| Code | Command |
|------|---------|
| 0x01 | Pairing Request |
| 0x02 | Pairing Response |
| 0x03 | Pairing Confirm |
| 0x04 | Pairing Random |
| 0x05 | Pairing Failed |
| 0x06 | Encryption Information |
| 0x07 | Central Identification |
| 0x08 | Identity Information |
| 0x09 | Identity Address Information |
| 0x0A | Signing Information |
| 0x0B | Security Request |

## BLE PHY Modes
| PHY | Bitrate | Range | Introduced |
|-----|---------|-------|------------|
| 1M | 1 Mbps | Standard | BT 4.0 |
| 2M | 2 Mbps | Short | BT 5.0 |
| Coded S=2 | 500 kbps | 2× range | BT 5.0 |
| Coded S=8 | 125 kbps | 4× range | BT 5.0 |

## Advertising Extensions (BT 5.0+)
- Primary channels: 37, 38, 39 (1M only)
- Secondary channels: 0-36 (1M, 2M, Coded)
- AUX_ADV_IND: extended advertising on secondary
- Periodic advertising: sync train for broadcaster

## Wireshark Display Filter Reference

| Filter | Description |
|--------|-------------|
| `btle` | All BLE packets |
| `btle.advertising` | Advertising PDUs |
| `btle.connect_req` | Connection requests |
| `btatt` | All ATT operations |
| `btatt.opcode == 0x1e` | Notifications |
| `btatt.uuid16 == 0x180d` | Specific service (Heart Rate) |
| `btsmp` | Security Manager |
| `btsmp.code == 0x01` | Pairing Request |
| `btl2cap` | L2CAP layer |
| `btl2cap.cid == 0x0005` | LE Signaling |
