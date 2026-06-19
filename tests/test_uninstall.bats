#!/usr/bin/env bats
# Тесты для install.sh --uninstall

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "install.sh загружается без синтаксических ошибок" {
  run bash -n "$SCRIPT_DIR/install.sh"
  [ "$status" -eq 0 ]
}

@test "install.sh --uninstall --dry-run выполняется" {
  run bash "$SCRIPT_DIR/install.sh" --uninstall --dry-run --skip-preflight
  [ "$status" -eq 0 ]
  [[ "$output" == *"Удаление"* ]]
}
