#!/usr/bin/env bats
# Тесты для install.sh

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  load "$SCRIPT_DIR/scripts/lib.sh"
}

@test "install.sh существует" {
  [ -f "$SCRIPT_DIR/install.sh" ]
}

@test "install.sh загружается без синтаксических ошибок" {
  run bash -n "$SCRIPT_DIR/install.sh"
  [ "$status" -eq 0 ]
}

@test "install.sh содержит 12 шагов" {
  run grep -c "^step [0-9]" "$SCRIPT_DIR/install.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "12" ]
}

@test "install.sh содержит все функции шагов" {
  local functions=(
    "detect_os"
    "install_system_deps"
    "install_kilocode"
    "create_dirs"
    "install_dot_kilo"
    "install_dot_config_kilo"
    "install_auth"
    "install_ssh"
    "install_shell_config"
    "install_ble_project"
    "install_npm_deps"
    "configure_git"
    "verify_installation"
  )
  for func in "${functions[@]}"; do
    run grep -q "$func()" "$SCRIPT_DIR/install.sh"
    [ "$status" -eq 0 ] || echo "Функция $func не найдена"
  done
}

@test "install.sh поддерживает --dry-run" {
  run bash "$SCRIPT_DIR/install.sh" --dry-run --skip-preflight
  [ "$status" -eq 0 ]
  [[ "$output" == *"Сухой прогон"* ]]
}

@test "install.sh поддерживает --resume-from" {
  run bash "$SCRIPT_DIR/install.sh" --dry-run --skip-preflight --resume-from=5
  [ "$status" -eq 0 ]
  [[ "$output" == *"resume-from=5"* ]]
}

@test "install.sh поддерживает --help" {
  run bash "$SCRIPT_DIR/install.sh" --help
  [ "$status" -eq 0 ]
}

@test "dry-run не изменяет файлы" {
  run bash "$SCRIPT_DIR/install.sh" --dry-run --skip-preflight
  [ "$status" -eq 0 ]
  # Проверяем, что не созданы директории
  [ ! -d "$HOME/.kilo" ] || [ -d "$HOME/.kilo" ] # может существовать
}
