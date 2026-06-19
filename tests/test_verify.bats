#!/usr/bin/env bats
# Тесты для install.sh --verify

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "install.sh --verify загружается без ошибок" {
  run bash -n "$SCRIPT_DIR/install.sh"
  [ "$status" -eq 0 ]
}

@test "install.sh содержит функции проверки" {
  run grep -c "check_cmd\|verify_installation" "$SCRIPT_DIR/install.sh"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}
