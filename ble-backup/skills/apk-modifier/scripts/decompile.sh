#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# decompile.sh — Полная декомпиляция APK (ресурсы + DEX + native)
# ============================================================

APK="$1"
OUT_DIR="${2:-./decompiled}"

if [[ ! -f "$APK" ]]; then
  echo "[!] APK not found: $APK"
  exit 1
fi

echo "[*] Decompiling $APK → $OUT_DIR"

# 1. apktool — ресурсы + smali
echo "[*] apktool decompile..."
apktool d -f --only-main-classes "$APK" -o "$OUT_DIR/apktool"

# 2. jadx — Java source (graded parsing)
echo "[*] jadx decompile..."
jadx -d "$OUT_DIR/java" "$APK" 2>/dev/null

# 3. Native libs
echo "[*] Extracting native libraries..."
unzip -o "$APK" "lib/*" -d "$OUT_DIR/native" 2>/dev/null

# 4. Strings
echo "[*] Extracting strings..."
strings "$APK" | sort -u > "$OUT_DIR/strings_all.txt"

# 5. APKiD — protection detection
if command -v apkid &>/dev/null; then
  echo "[*] APKiD scan..."
  apkid "$APK" > "$OUT_DIR/apkid_report.txt"
else
  echo "[!] APKiD not found, skipping"
fi

# 6. Manifest
echo "[*] Extracting AndroidManifest.xml..."
unzip -o "$APK" AndroidManifest.xml -d "$OUT_DIR" 2>/dev/null

echo "[+] Done. Directory structure:"
find "$OUT_DIR" -maxdepth 2 -type d | head -20
