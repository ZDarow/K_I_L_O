# Bluetooth Architecture Reference

## Bluetooth Classic Stack

```
+---------------------------------------------------------------+
|                        APPLICATIONS                            |
|   (HFP, HSP, A2DP, AVRCP, HID, PAN, SPP, GAVDP, etc.)        |
+---------------------------------------------------------------+
|  SDP       | RFCOMM    | BNEP     | AVDTP | AVCTP |  MCAP     |
|  Service   | Serial    | Network  | Audio | AV    | Multi-    |
|  Discovery | Emulation | Encapsul | Distr | Control| Channel   |
+---------------------------------------------------------------+
|                        L2CAP                                   |
|   (multiplexing, segmentation/reassembly, protocol channels)   |
+---------------------------------------------------------------+
|   HCI (Host Controller Interface) — UART/USB/SDIO              |
+---------------------------------------------------------------+
|    LM (Link Manager)     |    LC (Link Controller)             |
+---------------------------------------------------------------+
|                  Baseband / PHY (79 channels, 1MHz)            |
+---------------------------------------------------------------+
```

## Bluetooth LE Stack

```
+---------------------------------------------------------------+
|                        APPLICATION                             |
+---------------------------------------------------------------+
|   GAP (Generic Access)   |   GATT (Generic Attribute Profile) |
+---------------------------------------------------------------+
|   SM (Security Manager)  |   ATT (Attribute Protocol)         |
+---------------------------------------------------------------+
|   L2CAP (LE Credit-Based Flow Control, Fixed Channels)        |
+---------------------------------------------------------------+
|   LL (Link Layer) — state machine (advertising/scanning/connected) |
+---------------------------------------------------------------+
|   PHY (1M / 2M / Coded) — 40 channels (37 data + 3 advertising) |
+---------------------------------------------------------------+
```

## Classic Bluetooth — Key Concepts

### Piconet
- 1 Master + up to 7 Active Slaves (+ up to 255 Parked Slaves)
- Master defines clock and hopping sequence
- TDMA: Master transmits in even slots, Slave in odd slots

### SCO vs ACL
| Feature | SCO (Synchronous Connection-Oriented) | ACL (Asynchronous Connection-Less) |
|---------|--------------------------------------|------------------------------------|
| Use | Voice/audio | Data |
| Guaranteed | Bandwidth (64 kbps) | Best effort |
| Retransmission | No | Yes |
| Slots | Reserved | On demand |
| Packets | HV1/HV2/HV3, DV | DM1/DH1, DM3/DH3, DM5/DH5 |

### L2CAP (Logical Link Control and Adaptation Protocol)
- Multiplexing: multiple protocols over single ACL
- Segmentation/Reassembly: large SDUs into smaller PDUs
- Fixed channels:
  - 0x0001: L2CAP signaling
  - 0x0002: Connectionless data
  - 0x0003: AMP manager
- Dynamic channels: allocated via connection request

### Key PSMs (Protocol Service Multiplexers)
| PSM | Protocol |
|-----|----------|
| 0x0001 | SDP |
| 0x0003 | RFCOMM |
| 0x0005 | BNEP |
| 0x0007 | HID Control |
| 0x0009 | HID Interrupt |
| 0x0011 | AVDTP |
| 0x0013 | AVCTP |
| 0x0015 | MCAP Control |

### RFCOMM (Serial Port Emulation)
- Based on GSM TS 07.10
- Up to 60 simultaneous sessions (DLCI 2-61)
- DLCI = 6 × (offset + 1) + direction_bit
- Control frames: SABM, UA, DM, DISC, UIH

### SDP (Service Discovery Protocol)
- ServiceRecord → Attribute list
- Standard attributes (ID 0x0000-0x00FF):
  - 0x0000: ServiceRecordHandle
  - 0x0001: ServiceClassIDList
  - 0x0002: ServiceRecordState
  - 0x0003: ServiceID
  - 0x0004: ProtocolDescriptorList
  - 0x0005: BrowseGroupList
  - 0x0006: LanguageBaseAttributeIDList
  - 0x0007: ServiceInfoTimeToLive
  - 0x0008: ServiceAvailability
  - 0x0009: BluetoothProfileDescriptorList
  - 0x000A: DocumentationURL
  - 0x000B: ClientExecutableURL
  - 0x000C: IconURL
  - 0x0100-0xFFFF: Service-specific

### SDP PDU Types
| PDU ID | Name |
|--------|------|
| 0x01 | Error Response |
| 0x02 | ServiceSearchRequest |
| 0x03 | ServiceSearchResponse |
| 0x04 | ServiceAttributeRequest |
| 0x05 | ServiceAttributeResponse |
| 0x06 | ServiceSearchAttributeRequest |
| 0x07 | ServiceSearchAttributeResponse |

## BLE — Key Concepts

### Link Layer State Machine
```
    +----------+
    |  Standby |
    +----+-----+
         |
    +----+----+     +-----------+     +-----------+
    |Advertising|    | Scanning  |     | Initiating|
    +----+------+    +-----+-----+     +-----+-----+
         |                 |                 |
         +-----------------+-----------------+
                           |
                    +------+------+
                    |  Connected  |
                    | (Master/Slave) |
                    +-------------+
```

### BLE Advertising Channels
| Channel | Frequency |
|---------|-----------|
| CH 37 (2402 MHz) | Primary advertising + connection |
| CH 38 (2426 MHz) | Primary advertising + connection |
| CH 39 (2480 MHz) | Primary advertising + connection |
| CH 0-36 | Data channels (1 MHz spacing) |

### Connection Event Timing
```
Connection Interval (CI): 7.5 ms - 4 s (1.25ms steps)
  ├── Event 1
  │   ├── Master TX
  │   ├── Slave TX (response)
  │   ├── Master TX (next)
  │   └── ... (up to CI)
  ├── Event 2 (CI + latency*1.25ms later)
  └── ...

Slave Latency: 0-499 events (skip connection events)
Supervision Timeout: 100 ms - 32 s (10 ms steps)
```

### BLE Device Address Types
| Type | Bit | Description |
|------|-----|-------------|
| Public | 0 | IEEE-assigned (OUI + vendor) |
| Random Static | 1 | Random, fixed per boot |
| Private Resolvable (RPA) | 2 | Random, resolvable via IRK |
| Private Non-Resolvable | 3 | Random, not resolvable |

### BLE Security Modes
| Mode | Level | Description |
|------|-------|-------------|
| 1 | 1 | No security (Just Works, no MITM) |
| 1 | 2 | Unauthenticated pairing with encryption |
| 1 | 3 | Authenticated pairing with encryption |
| 1 | 4 | LE Secure Connections with 128-bit key |
| 2 | 1 | Data signing without encryption |
| 2 | 2 | Data signing with unauthenticated encryption key |

## Bluetooth Versions

| Version | Year | Key Features |
|---------|------|-------------|
| 1.0/1.0B | 1999 | Initial specification |
| 1.1 | 2002 | IEEE 802.15.1 |
| 1.2 | 2003 | AFH, eSCO, enhanced flow control |
| 2.0 + EDR | 2004 | Enhanced Data Rate (3 Mbps) |
| 2.1 + EDR | 2007 | Secure Simple Pairing (SSP) |
| 3.0 + HS | 2009 | AMP (802.11), L2CAP enhanced |
| 4.0 | 2010 | **BLE introduced**, GATT, SM |
| 4.1 | 2013 | LE L2CAP CoC, privacy improvements |
| 4.2 | 2014 | LE Secure Connections, LE Privacy 1.2, Data Length Extension |
| 5.0 | 2016 | 2M PHY, Coded PHY, Advertising Extensions, AoA/AoD |
| 5.1 | 2019 | AoA/AoD enhancements, GATT caching |
| 5.2 | 2020 | LE Audio (LC3 codec), LE Power Control |
| 5.3 | 2021 | Connection subrating, channel classification |
| 5.4 | 2023 | Periodic Advertising with Responses (PAwR), Encrypted Data |

## Wireshark Dissectors for Bluetooth

```
bluetooth.*         — Bluetooth base
  bthci_cmd         — HCI commands
  bthci_evt         — HCI events
  bthci_acl         — ACL data
  bthci_sco         — SCO data
  btl2cap           — L2CAP layer
  btrfcomm          — RFCOMM
  btsdp             — SDP
  btavdtp           — A2DP audio transport
  bta2dp            — A2DP codec
  btavctp           — AV control
  btbnep            — BNEP (PAN)
  bthid             — HID
  bthfp             — Hands-Free Profile
  bthsp             — Headset Profile
  btle              — BLE Link Layer
  btatt             — ATT
  btsmp             — SMP
```

## Common SDP Service UUIDs (Classic)
| UUID | Service |
|------|---------|
| 0x0001 | Service Discovery Server |
| 0x0003 | RFCOMM |
| 0x0006 | OBEX Object Push |
| 0x0007 | OBEX File Transfer |
| 0x0008 | IrMC Sync |
| 0x000F | Advanced Audio Distribution (A2DP) |
| 0x0010 | Audio/Video Remote Control (AVRCP) |
| 0x0011 | A/V Remote Control Target |
| 0x0012 | Headset - Audio Gateway (HFP) |
| 0x0014 | Hands-Free (HF) |
| 0x0015 | Hands-Free Audio Gateway (AG) |
| 0x0016 | SIM Access (SAP) |
| 0x0017 | Phonebook Access (PBAP) |
| 0x0018 | PBAP Client |
| 0x0019 | PBAP Server |
| 0x0100 | Serial Port (SPP) |
| 0x1101 | Headset |
| 0x1102 | Hands-Free |
| 0x1106 | LAN Access (PAN) |
| 0x111F | Human Interface Device (HID) |

## Wireshark BLE Field Extraction Reference

```bash
# Advertising data (AD structures)
btle.advertising_header_type
btle.advertising_address_type
btle.advertising_address
btle.advertising_header_length
btle.ad_data_type    # 0x01=Flags, 0x02=Incomplete 16-bit UUIDs, 0x09=Complete Local Name
btle.ad_data

# Connection
btle.initiator_address
btle.advertiser_address
btle.conn_interval    # (value * 1.25ms)
btle.conn_latency
btle.conn_timeout     # (value * 10ms)
btle.aa              # Access Address

# ATT
btatt.opcode
btatt.handle
btatt.uuid16
btatt.uuid128
btatt.value
btatt.length

# SMP
btsmp.code
btsmp.io_capability  # 0=DisplayOnly, 1=DisplayYesNo, 2=KeyboardOnly, 3=NoInputNoOutput, 4=KeyboardDisplay
btsmp.oob_flag
btsmp.authreq_mitm
btsmp.authreq_bonding
btsmp.max_key_size
btsmp.init_key_dist
btsmp.resp_key_dist
```
