#!/usr/bin/env bats
# Тесты для scripts/verify.sh

setup() {
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    load "$SCRIPT_DIR/scripts/lib.sh"
}

@test "verify.sh существует" {
    [ -f "$SCRIPT_DIR/scripts/verify.sh" ]
}

@test "verify.sh загружается без ошибок" {
    run bash -n "$SCRIPT_DIR/scripts/verify.sh"
    [ "$status" -eq 0 ]
}

@test "verify.sh содержит check_file" {
    run grep -c "check_file" "$SCRIPT_DIR/scripts/verify.sh"
    [ "$status" -eq 0 ]
    [ "$output" -ge 5 ]  # Минимум 5 вызовов check_file
}

@test "verify.sh содержит check_dir" {
    run grep -c "check_dir" "$SCRIPT_DIR/scripts/verify.sh"
    [ "$status" -eq 0 ]
    [ "$output" -ge 3 ]  # Минимум 3 вызова check_dir
}
