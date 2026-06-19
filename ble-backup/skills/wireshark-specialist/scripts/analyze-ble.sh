#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# analyze-ble.sh — Анализ BLE-сессий из pcapng
# ============================================================

PCAP="${1:?Usage: $0 capture.pcapng}"

echo "=== BLE Capture Analysis ==="
echo "File: $PCAP"
echo ""

# 1. Basic stats
echo "--- Statistics ---"
capinfos "$PCAP" 2>/dev/null | grep -E "Number of packets|Packet size|Duration|Data bit rate"

# 2. Protocol hierarchy
echo ""
echo "--- BLE Protocol Summary ---"
tshark -r "$PCAP" -q -z io,phs 2>/dev/null | grep -i "bluetooth\|btle\|btatt\|btsmp\|btl2cap" || echo "(none found)"

# 3. Advertising packets
echo ""
echo "--- Advertising Packets ---"
tshark -r "$PCAP" -Y "btle.advertising" -T fields \
  -e frame.number \
  -e frame.time_relative \
  -e btle.advertising_address \
  -e btle.advertising_header_type 2>/dev/null | head -30

echo ""
echo "--- Connection Requests ---"
tshark -r "$PCAP" -Y "btle.connect_req" -T fields \
  -e frame.number \
  -e btle.initiator_address \
  -e btle.advertiser_address \
  -e btle.conn_interval \
  -e btle.conn_latency \
  -e btle.conn_timeout 2>/dev/null || echo "(none)"

echo ""
echo "--- ATT Operations (Read/Write/Notify) ---"
tshark -r "$PCAP" -Y "btatt" -T fields \
  -e frame.number \
  -e frame.time_relative \
  -e btatt.opcode \
  -e btatt.handle \
  -e btatt.uuid16 \
  -e btatt.value 2>/dev/null | head -50

echo ""
echo "--- SMP Pairing ---"
tshark -r "$PCAP" -Y "btsmp" -T fields \
  -e frame.number \
  -e btsmp.code \
  -e btsmp.command 2>/dev/null || echo "(none)"
