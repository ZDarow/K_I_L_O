#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# frida-enumerate.sh — Быстрое перечисление через Frida
# ============================================================

APP="${1:?Usage: $0 com.target.app [script.js]}"
SCRIPT="${2:-}"

TMPDIR=$(mktemp -d)

# 1. Enumerate classes
echo "[*] Enumerating loaded classes for $APP..."
cat >"$TMPDIR/enum_classes.js" <<'JSEOF'
Java.perform(function() {
  console.log("[*] Loaded classes containing 'target|crypto|license|key':");
  Java.enumerateLoadedClasses({
    onMatch: function(cls) {
      var lower = cls.toLowerCase();
      if (lower.includes("target") || lower.includes("crypto") ||
          lower.includes("license") || lower.includes("key") ||
          lower.includes("security") || lower.includes("aes") ||
          lower.includes("ssl") || lower.includes("cert")) {
        console.log("  " + cls);
      }
    },
    onComplete: function() { console.log("[+] Done enumerating"); }
  });
});
JSEOF

# 2. Enumerate exports from loaded native libs
cat >"$TMPDIR/enum_native.js" <<'JSEOF'
Java.perform(function() {
  console.log("[*] Loaded native libraries:");
  Process.enumerateModules({
    onMatch: function(mod) {
      if (mod.name.includes("ssl") || mod.name.includes("crypto") ||
          mod.name.includes("native") || mod.name.includes("core")) {
        console.log("  " + mod.name + " @ " + mod.base);
      }
    },
    onComplete: function() { console.log("[+] Done enumerating modules"); }
  });
});
JSEOF

# 3. Run
echo "[*] Running enumeration..."
frida -U -f "$APP" -l "$TMPDIR/enum_classes.js" --no-pause -o "$TMPDIR/classes.txt" 2>/dev/null &
FRIDA_PID=$!
sleep 5
kill $FRIDA_PID 2>/dev/null || true

frida -U -l "$TMPDIR/enum_native.js" --no-pause -o "$TMPDIR/native.txt" 2>/dev/null &
FRIDA_PID=$!
sleep 3
kill $FRIDA_PID 2>/dev/null || true

echo ""
echo "=== Classes found ==="
cat "$TMPDIR/classes.txt"
echo ""
echo "=== Native libs found ==="
cat "$TMPDIR/native.txt"

# 4. If custom script specified, run it
if [[ -n "$SCRIPT" && -f "$SCRIPT" ]]; then
  echo ""
  echo "[*] Running custom script: $SCRIPT"
  frida -U -f "$APP" -l "$SCRIPT" --no-pause
fi

rm -rf "$TMPDIR"
