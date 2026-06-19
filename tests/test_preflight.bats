#!/usr/bin/env bats
# Тесты для scripts/preflight.sh

setup() {
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    load "$SCRIPT_DIR/scripts/lib.sh"
}

@test "preflight.sh существует" {
    [ -f "$SCRIPT_DIR/scripts/preflight.sh" ]
}

@test "preflight.sh загружается без ошибок" {
    run bash -n "$SCRIPT_DIR/scripts/preflight.sh"
    [ "$status" -eq 0 ]
}

@test "preflight.sh содержит все секции проверок" {
    run grep -c "subheader" "$SCRIPT_DIR/scripts/preflight.sh"
    [ "$status" -eq 0 ]
    [ "$output" -ge 7 ]  # Минимум 7 секций проверок
}
