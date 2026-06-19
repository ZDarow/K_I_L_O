#!/usr/bin/env bats
# Тесты: проверка синхронизации src/dot-kilo/ и .kilo/

setup() {
    PROJECT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "src/dot-kilo/ и .kilo/ не имеют критических расхождений" {
    errors=0
    for f in $(find "$PROJECT_DIR/src/dot-kilo" -not -path '*/node_modules/*' -not -name 'package-lock.json' -type f | sed "s|$PROJECT_DIR/src/dot-kilo/||" | sort); do
        src="$PROJECT_DIR/src/dot-kilo/$f"
        kilo="$PROJECT_DIR/.kilo/$f"
        if [ ! -f "$kilo" ]; then
            echo "ONLY_IN_SRC: $f"
            errors=$((errors + 1))
        elif ! diff -q "$src" "$kilo" >/dev/null 2>&1; then
            echo "DIFF: $f"
            errors=$((errors + 1))
        fi
    done
    [ "$errors" -eq 0 ]
}

@test "все агенты присутствуют в обоих наборах" {
    for agent in dev git-specialist adb-specialist apk-reverse-engineer debugger doc-scribe esp32-arduino-specialist log-analyzer planner reviewer sys-inspector; do
        [ -f "$PROJECT_DIR/src/dot-kilo/agent/$agent.md" ] || { echo "Missing src/dot-kilo/agent/$agent.md"; false; }
        [ -f "$PROJECT_DIR/.kilo/agent/$agent.md" ] || { echo "Missing .kilo/agent/$agent.md"; false; }
    done
}

@test "ключевые команды присутствуют в обоих наборах" {
    for cmd in ble-capture ble-debug ble-setup flutter-build gatt-discover git-branch git-commit git-status test plan review; do
        [ -f "$PROJECT_DIR/src/dot-kilo/commands/$cmd.md" ] || { echo "Missing src/dot-kilo/commands/$cmd.md"; false; }
        [ -f "$PROJECT_DIR/.kilo/commands/$cmd.md" ] || { echo "Missing .kilo/commands/$cmd.md"; false; }
    done
}
