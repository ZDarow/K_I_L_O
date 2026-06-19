#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# extract-resources.sh — Извлечение и классификация ресурсов
# ============================================================

APK="$1"
OUT="${2:-./resources_extracted}"

mkdir -p "$OUT"

echo "[*] Extracting from $APK → $OUT"

# 1. AndroidManifest.xml
echo "[+] Manifest"
unzip -o "$APK" AndroidManifest.xml -d "$OUT" 2>/dev/null

# 2. All resources
echo "[+] Resources (res/)"
unzip -o "$APK" "res/*" -d "$OUT" 2>/dev/null

# 3. Assets
echo "[+] Assets"
unzip -o "$APK" "assets/*" -d "$OUT" 2>/dev/null

# 4. Native libs
echo "[+] Native libs"
unzip -o "$APK" "lib/*" -d "$OUT" 2>/dev/null

# 5. Certificates
echo "[+] Certificates"
unzip -o "$APK" "META-INF/*" -d "$OUT" 2>/dev/null

# 6. Extract strings from resources.arsc
if command -v aapt2 &>/dev/null; then
  echo "[+] String resources (aapt2)"
  aapt2 dump resources "$APK" 2>/dev/null | grep -E "^.*resource.*string/" >"$OUT/string_resources.txt" || true
fi

# 7. Hardcoded URLs/IPs
echo "[+] Scanning for hardcoded endpoints..."
strings "$APK" | grep -oE 'https?://[a-zA-Z0-9./_-]+' | sort -u >"$OUT/urls.txt"
strings "$APK" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]+' | sort -u >"$OUT/endpoints.txt"

# 8. Base64-encoded content
echo "[+] Scanning for potential base64..."
strings "$APK" | grep -oE '[A-Za-z0-9+/=]{20,}' | sort -u >"$OUT/base64_candidates.txt"

echo "[+] Done. Files:"
ls -1 "$OUT"/
