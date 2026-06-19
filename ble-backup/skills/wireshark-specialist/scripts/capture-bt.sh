#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# capture-bt.sh — Захват Bluetooth/BLE трафика
# ============================================================
# Режимы:
#   btmon   — HCI log через btmon (рекомендуется)
#   tshark  — захват через tshark на bluetooth0
#   android — извлечение hci_snoop через ADB

MODE="${1:-btmon}"
OUT="${2:-capture_$(date +%Y%m%d_%H%M%S)}"

case "$MODE" in
  btmon)
    echo "[*] Capturing via btmon → ${OUT}.hci"
    echo "[*] Press Ctrl+C to stop"
    btmon -w "${OUT}.hci"
    echo "[+] Saved: ${OUT}.hci"
    echo "[*] Convert to pcapng: tshark -r ${OUT}.hci -w ${OUT}.pcapng"
    ;;

  tshark)
    IFACE="${3:-bluetooth0}"
    echo "[*] Capturing on ${IFACE} → ${OUT}.pcapng"
    echo "[*] Filter: btle or bthci_acl"
    tshark -i "$IFACE" -f "btle or bthci_acl" -w "${OUT}.pcapng"
    echo "[+] Saved: ${OUT}.pcapng"
    ;;

  android)
    echo "[*] Extracting HCI snoop log from Android device via ADB"
    adb shell "touch /sdcard/btsnoop_hci.log && chmod 644 /sdcard/btsnoop_hci.log"
    adb shell "cat /sdcard/btsnoop_hci.log" > "${OUT}.btsnoop"
    echo "[+] Saved: ${OUT}.btsnoop"
    echo "[*] Or check: /data/misc/bluetooth/logs/btsnoop_hci.log"
    ;;

  *)
    echo "Usage: $0 {btmon|tshark|android} [output_name] [interface]"
    exit 1
    ;;
esac
