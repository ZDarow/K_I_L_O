#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# btmon-capture.sh — Захват через btmon с автоконвертацией
# ============================================================

OUT_DIR="${1:-./bt_captures}"
DURATION="${2:-}" # seconds, empty = manual stop

mkdir -p "$OUT_DIR"
TS=$(date +%Y%m%d_%H%M%S)
HCI_FILE="${OUT_DIR}/btmon_${TS}.hci"
PCAP_FILE="${OUT_DIR}/btmon_${TS}.pcapng"

echo "[*] btmon capture → $HCI_FILE"

if [[ -n "$DURATION" ]]; then
  echo "[*] Duration: ${DURATION}s"
  timeout "$DURATION" btmon -w "$HCI_FILE" || true
else
  echo "[*] Press Ctrl+C to stop"
  btmon -w "$HCI_FILE"
fi

echo "[+] HCI saved: $HCI_FILE ($(stat -c%s "$HCI_FILE") bytes)"

# Convert to pcapng for Wireshark
if command -v tshark &>/dev/null; then
  echo "[*] Converting to pcapng..."
  tshark -r "$HCI_FILE" -w "$PCAP_FILE" 2>/dev/null || {
    echo "[!] Conversion failed; copying raw HCI"
    cp "$HCI_FILE" "${OUT_DIR}/btmon_${TS}.raw_hci"
  }
  echo "[+] PCAPNG: $PCAP_FILE"
fi

# Summary
echo ""
echo "=== Quick summary ==="
if command -v tshark &>/dev/null && [[ -f "$PCAP_FILE" ]]; then
  tshark -r "$PCAP_FILE" -q -z io,phs 2>/dev/null | head -20
fi

echo "[*] Done. Files in $OUT_DIR"
