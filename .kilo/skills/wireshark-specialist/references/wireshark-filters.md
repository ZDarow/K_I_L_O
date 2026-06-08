# Wireshark Display Filters — коллекция

## Capture Filters (BPF)

### Bluetooth Classic
```bash
# All HCI packets
hci

# ACL data
hci and ether proto 0x0002

# SCO voice
hci and ether proto 0x0003

# HCI events
hci and ether proto 0x0004

# RFCOMM channel 1
hci and (hci_len > 0) and (hci_data[9:1] == 0x01)
```

### BLE
```bash
# All BLE
btle

# BLE advertising
btle and (btle[0] & 0x0f) <= 0x06

# BLE connection requests
btle and btle[0] == 0x05

# Full capture (no filter)
# BLE filter isn't BPF — use tshark display filter instead:
tshark -i bluetooth0 -Y "btle" -w capture.pcapng
```

### General (non-BT)
```bash
# Only TCP
tcp

# Specific port
port 443

# Host
host 192.168.1.1

# Subnet
net 192.168.1.0/24

# Combined
tcp and port 80 and host 10.0.0.1

# Exclude
not arp and not icmp

# Packet length
len > 100
```

## Display Filters (Wireshark GUI / tshark -Y)

### Bluetooth Classic
```wireshark
# All classic BT
bthci_acl || bthci_cmd || bthci_evt || bthci_sco

# Only ACL packets
bthci_acl

# SDP
btsdp

# RFCOMM
btrfcomm

# A2DP audio
btavdtp || bta2dp

# HFP
bthfp

# HID
bthid

# BNEP (Bluetooth PAN)
btbnep

# HCI events only
hci_evt

# HCI commands
hci_cmd
```

### BLE
```wireshark
# All BLE (most useful)
btle

# Advertising chain
btle.advertising

# Scan requests / responses
btle.scan_req || btle.scan_rsp

# Connection
btle.connect_req

# Data channel
btle.data

# Empty PDUs (keep alive)
btle.data && btle.length == 0

# ATT protocol
btatt

# ATT — specific operations
btatt.opcode == 0x01  # Read by Group Type (service discovery)
btatt.opcode == 0x08  # Read by Type (characteristic discovery)
btatt.opcode == 0x0a  # Read Request
btatt.opcode == 0x12  # Write Request
btatt.opcode == 0x1b  # Write Command
btatt.opcode == 0x1e  # Notification
btatt.opcode == 0x1d  # Indication
btatt.opcode == 0x52  # Exchange MTU Request

# ATT — read/write/notify combined
btatt.opcode == 0x0a || btatt.opcode == 0x12 || btatt.opcode == 0x1b || btatt.opcode == 0x1e

# ATT by UUID
btatt.uuid16 == 0x180d  # Heart Rate
btatt.uuid16 == 0x180f  # Battery
btatt.uuid16 == 0x180a  # Device Information
btatt.uuid16 == 0x1800  # Generic Access

# L2CAP
btl2cap

# SMP (Security Manager)
btsmp

# BLE HCI
hci_le || hci_le_evt

# Specific device
btle.adv_addr == 12:34:56:78:9a:bc

# Connection handle
btle.connection_handle == 0x0000
```

### BLE — Combined Analysis
```wireshark
# Full BLE device interaction (advertising + connection + data)
btle && btle.adv_addr == 12:34:56:78:9a:bc

# Reassembled GATT operations
btatt && btatt.handle == 0x0010

# Follow characteristic value changes (notifications + writes)
btatt.handle == 0x0010
```

### General Protocol Filters
```wireshark
# HTTP
http
http.request
http.response
http.request.method == GET
http.host contains "example"

# TLS
tls
tls.handshake.type == 1      # Client Hello
tls.handshake.type == 2      # Server Hello
tls.handshake.type == 11     # Certificate
tls.handshake.type == 16     # Encrypted Extensions
tls.handshake.extensions_server_name contains "example"

# DNS
dns
dns.qry.name contains "example"
dns.flags.response == 0      # queries
dns.flags.response == 1      # responses

# DHCP
dhcp
dhcp.option.dhcp == 1        # discover
dhcp.option.dhcp == 3        # request

# ARP
arp
arp.opcode == 1              # request
arp.opcode == 2              # reply

# ICMP
icmp
icmp.type == 8               # echo request
icmp.type == 0               # echo reply

# 802.11 Wi-Fi
wlan
wlan.fc.type_subtype == 0x08  # Beacon
wlan.fc.type_subtype == 0x05  # Probe Response
wlan.fc.type_subtype == 0x0b  # Authentication
wlan.fc.type_subtype == 0x00  # Association Request
wlan.fc.type_subtype == 0x0c  # Deauthentication
eapol                          # 4-way handshake

# IPv4/IPv6
ip.addr == 192.168.1.1
ipv6.addr == fe80::1
ip.src == 10.0.0.1 && ip.dst == 10.0.0.2
```

## tshark Field Extraction

### BLE Field Export
```bash
# All BLE advertising fields
tshark -r capture.pcapng -Y "btle.advertising" -T fields \
  -e frame.number \
  -e frame.time_relative \
  -e btle.advertising_address \
  -e btle.advertising_header_type \
  -e btle.advertising_header_length

# ATT operations as CSV
tshark -r capture.pcapng -Y "btatt" -T fields \
  -e frame.number \
  -e btatt.opcode \
  -e btatt.handle \
  -e btatt.uuid16 \
  -e btatt.value \
  -E separator=, -E header=y

# Connection parameters
tshark -r capture.pcapng -Y "btle.connect_req" -T fields \
  -e btle.conn_interval \
  -e btle.conn_latency \
  -e btle.conn_timeout

# Classic BT SDP
tshark -r capture.pcapng -Y "btsdp" -T fields \
  -e btsdp.service_uuid \
  -e btsdp.service_name
```

### General Field Export
```bash
# HTTP request/response
tshark -r capture.pcapng -Y "http" -T fields \
  -e http.request.method \
  -e http.request.uri \
  -e http.response.code \
  -e http.content_type

# DNS queries
tshark -r capture.pcapng -Y "dns.flags.response == 0" -T fields \
  -e dns.qry.name \
  -e dns.qry.type

# TCP streams
tshark -r capture.pcapng -Y "tcp" -T fields \
  -e tcp.stream \
  -e tcp.srcport \
  -e tcp.dstport \
  -e tcp.flags.syn \
  -e tcp.flags.ack

# Follow TCP stream
tshark -r capture.pcapng -q -z follow,tcp,ascii,0
```

## Statistics
```bash
# IO graph (1-second intervals)
tshark -r capture.pcapng -z io,stat,1

# Protocol hierarchy
tshark -r capture.pcapng -q -z io,phs

# Endpoints
tshark -r capture.pcapng -q -z endpoints,ip

# Conversations
tshark -r capture.pcapng -q -z conv,tcp

# Expert info
tshark -r capture.pcapng -q -z expert
```

## Complex Filters
```wireshark
# BLE: only notifications with non-zero data
btatt.opcode == 0x1e && btatt.value

# BLE: connection interval < 10ms (aggressive power)
btle.connect_req && btle.conn_interval < 8

# BLE: find all characteristics with Notify property
btatt.opcode == 0x08 && btatt.value matches "^..\\x10"

# BLE: pairing with MITM protection
btsmp && btsmp.authreq_mitm == 1

# Classic: RFCOMM with data payload
btrfcomm && frame.len > 30

# Multi-layer: BLE notification → interpret as custom profile
btatt.opcode == 0x1e && btatt.handle == 0x0015
```
