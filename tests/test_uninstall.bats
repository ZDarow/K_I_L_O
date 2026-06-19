#!/usr/bin/env bats
# Тесты для uninstall.sh

setup() {
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    load "$SCRIPT_DIR/scripts/lib.sh"
}

@test "uninstall.sh существует" {
    [ -f "$SCRIPT_DIR/uninstall.sh" ]
}

@test "uninstall.sh загружается без синтаксических ошибок" {
    run bash -n "$SCRIPT_DIR/uninstall.sh"
    [ "$status" -eq 0 ]
}

@test "uninstall.sh поддерживает --dry-run" {
    # Устанавливаем INSTALL_DRY_RUN=1 чтобы избежать запроса подтверждения
    run bash -c "INSTALL_DRY_RUN=1 bash '$SCRIPT_DIR/uninstall.sh' --dry-run"
    [ "$status" -eq 0 ]
    [[ "$output" == *"сухой прогон"* ]] || [[ "$output" == *"dry-run"* ]] || [[ "$output" == *"DRY-RUN"* ]]
}
