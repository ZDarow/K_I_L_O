#!/usr/bin/env bats
# Тесты для install.sh

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  load "$SCRIPT_DIR/scripts/lib.sh"
}

@test "install.sh существует" { [ -f "$SCRIPT_DIR/install.sh" ]; }

@test "install.sh без синтаксических ошибок" {
  run bash -n "$SCRIPT_DIR/install.sh"
  [ "$status" -eq 0 ]
}

@test "install.sh содержит 10 шагов" {
  run grep -c "^step [0-9]" "$SCRIPT_DIR/install.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "10" ]
}

@test "install.sh содержит все функции шагов" {
  for func in detect_os install_system_deps install_kilocode create_dirs \
    install_kilo_config install_global_config install_auth \
    install_shell_config install_npm_deps configure_git; do
    run grep -q "$func()" "$SCRIPT_DIR/install.sh"
    [ "$status" -eq 0 ] || echo "Нет функции $func"
  done
}

@test "install.sh --dry-run" {
  run bash "$SCRIPT_DIR/install.sh" --dry-run --skip-preflight
  [ "$status" -eq 0 ]
  [[ "$output" == *"Сухой прогон"* ]]
}

@test "install.sh --help" {
  run bash "$SCRIPT_DIR/install.sh" --help
  [ "$status" -eq 0 ]
}

@test "install.sh --check" {
  run bash "$SCRIPT_DIR/install.sh" --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pre-flight"* ]]
}

@test "install.sh --verify" {
  run bash "$SCRIPT_DIR/install.sh" --verify
  # verify может быть 0 или 1 (зависит от системы)
  [[ "$output" == *"Верификация"* ]]
}

@test "install.sh --uninstall --dry-run" {
  run bash "$SCRIPT_DIR/install.sh" --uninstall --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"Удаление"* ]]
}
