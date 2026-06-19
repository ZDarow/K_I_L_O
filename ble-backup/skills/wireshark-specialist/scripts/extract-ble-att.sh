#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# extract-ble-att.sh — Извлечение ATT-операций в читаемый формат
# ============================================================

PCAP="${1:?Usage: $0 capture.pcapng [opcode]}"
OPCODE_FILTER="${2:-}"

FILTER="btatt"
[[ -n "$OPCODE_FILTER" ]] && FILTER="btatt.opcode == $OPCODE_FILTER"

echo "# BLE ATT Operations from: $PCAP"
echo "# Filter: $FILTER"
echo "# Timestamp,Opcode,Handle,UUID16,Data"
echo ""

tshark -r "$PCAP" -Y "$FILTER" -T fields \
  -e frame.time_relative \
  -e btatt.opcode \
  -e btatt.handle \
  -e btatt.uuid16 \
  -e btatt.value \
  -E separator=',' 2>/dev/null

echo ""
echo "--- Opcode Legend ---"
echo "0x01=ReadByGroupType, 0x08=ReadByType, 0x0A=ReadReq, 0x0B=ReadRsp"
echo "0x12=WriteReq, 0x13=WriteRsp, 0x1B=WriteCmd, 0x1E=Notification, 0x1D=Indication"
echo "0x52=ExchangeMTU, 0x53=ExchangeMTU_Rsp"
