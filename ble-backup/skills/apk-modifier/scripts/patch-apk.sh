#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# patch-apk.sh — Применение smali-патчей к APK через набор правил
# ============================================================
# Формат правил: file.smali:line:old_text|new_text
# Пример:
#   patch-apk.sh decompiled_dir rules.txt modified_out
#
# rules.txt:
#   smali/com/app/LicenseCheck.smali:45:if-eqz v0, :cond_skip|goto :cond_skip
#   smali/com/app/Config.smali:120:const-string v1, "https://prod.api.com"|const-string v1, "https://debug.api.com"

DECOMPILED_DIR="$1"
RULES_FILE="$2"
OUT_DIR="${3:-./patched}"

if [[ ! -d "$DECOMPILED_DIR" ]]; then
  echo "[!] Decompiled dir not found: $DECOMPILED_DIR"
  exit 1
fi
if [[ ! -f "$RULES_FILE" ]]; then
  echo "[!] Rules file not found: $RULES_FILE"
  exit 1
fi

echo "[*] Applying patches from $RULES_FILE → $DECOMPILED_DIR"
echo ""

cp -r "$DECOMPILED_DIR" "$OUT_DIR"

SUCCESS=0
FAIL=0

while IFS='|' read -r location replacement; do
  [[ -z "$location" ]] && continue

  file_line="${location%%:*}"
  rest="${location#*:}"
  line="${rest%%:*}"
  old="${rest#*:}"

  smali_file="$OUT_DIR/$file_line"

  if [[ ! -f "$smali_file" ]]; then
    echo "  [FAIL] File not found: $smali_file"
    ((FAIL++))
    continue
  fi

  original_line=$(sed -n "${line}p" "$smali_file")
  if [[ "$original_line" != *"$old"* ]]; then
    echo "  [SKIP] Pattern not found at $file_line:$line"
    echo "         expected: $old"
    echo "         actual:   $original_line"
    ((FAIL++))
    continue
  fi

  sed -i "${line}s/.*/${replacement}/" "$smali_file"
  echo "  [OK] $file_line:$line → $replacement"
  ((SUCCESS++))

done <"$RULES_FILE"

echo ""
echo "[+] Patches applied: $SUCCESS success, $FAIL failed"
echo "[*] Next: run 'apktool b $OUT_DIR -o modified-unsigned.apk'"
