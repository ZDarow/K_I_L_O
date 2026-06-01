#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# sign-apk.sh — Выравнивание + подпись APK
# ============================================================

UNSIGNED_APK="${1:?Usage: sign-apk.sh unsigned.apk [output.apk]}"
OUTPUT_APK="${2:-./modified-signed.apk}"
KEYSTORE="${3:-./mod.jks}"
KEYSTORE_PASS="${4:-123456}"
KEY_ALIAS="${5:-mod}"

WORKDIR=$(mktemp -d)
ALIGNED_APK="$WORKDIR/aligned.apk"

echo "[*] Signing $UNSIGNED_APK → $OUTPUT_APK"

# 1. Create keystore if missing
if [[ ! -f "$KEYSTORE" ]]; then
  echo "[*] Generating new keystore: $KEYSTORE"
  keytool -genkey -v -keystore "$KEYSTORE" \
    -alias "$KEY_ALIAS" -keyalg RSA -keysize 2048 \
    -validity 10000 \
    -storepass "$KEYSTORE_PASS" \
    -keypass "$KEYSTORE_PASS" \
    -dname "CN=Mod, OU=Dev, O=Modder, L=City, S=State, C=US"
fi

# 2. zipalign
echo "[*] zipalign..."
zipalign -p -f 4 "$UNSIGNED_APK" "$ALIGNED_APK"

# 3. apksigner
echo "[*] apksigner..."
apksigner sign \
  --ks "$KEYSTORE" \
  --ks-key-alias "$KEY_ALIAS" \
  --ks-pass "pass:$KEYSTORE_PASS" \
  --out "$OUTPUT_APK" \
  "$ALIGNED_APK"

# 4. Verify
echo "[*] Verifying..."
apksigner verify --verbose "$OUTPUT_APK"

echo "[+] Signed: $OUTPUT_APK"
rm -rf "$WORKDIR"
