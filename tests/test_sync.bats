#!/usr/bin/env bats
# Тесты: проверка синхронизации src/kilo-config/ и .kilo/

setup() {
  PROJECT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "src/kilo-config/ и .kilo/ не имеют критических расхождений" {
  errors=0
  for f in $(find "$PROJECT_DIR/src/kilo-config" -not -path '*/node_modules/*' -not -name 'package-lock.json' -type f | sed "s|$PROJECT_DIR/src/kilo-config/||" | sort); do
    src="$PROJECT_DIR/src/kilo-config/$f"
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

@test "агенты синхронизированы" {
  for agent in dev git-specialist debugger doc-scribe log-analyzer planner reviewer sys-inspector; do
    [ -f "$PROJECT_DIR/src/kilo-config/agent/$agent.md" ] || {
      echo "Missing src: $agent"
      false
    }
    [ -f "$PROJECT_DIR/.kilo/agent/$agent.md" ] || {
      echo "Missing .kilo: $agent"
      false
    }
  done
}

@test "ключевые команды присутствуют в обоих наборах" {
  for cmd in flutter-build git-branch git-commit git-status test plan review; do
    [ -f "$PROJECT_DIR/src/kilo-config/commands/$cmd.md" ] || {
      echo "Missing src/kilo-config/commands/$cmd.md"
      false
    }
    [ -f "$PROJECT_DIR/.kilo/commands/$cmd.md" ] || {
      echo "Missing .kilo/commands/$cmd.md"
      false
    }
  done
}
