#!/usr/bin/env bats
# Тесты для install.sh --check

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "install.sh --check выполняется без ошибок" {
  run bash "$SCRIPT_DIR/install.sh" --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pre-flight"* ]]
}
