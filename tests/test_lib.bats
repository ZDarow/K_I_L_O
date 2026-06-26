#!/usr/bin/env bats
# Тесты для scripts/lib.sh
# shellcheck disable=SC2030,SC2031  # BATS запускает тесты в сабшеллах

setup() {
  load '../scripts/lib.sh'
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR" || exit 1
}

teardown() {
  rm -rf "$TEST_DIR"
}

# ═══════════════════════════════════════════════════
# Тесты: цвета и логирование
# ═══════════════════════════════════════════════════

@test "log: выводит зелёную галочку" {
  run log "тест"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[✓]"* ]]
  [[ "$output" == *"тест"* ]]
}

@test "warn: выводит жёлтое предупреждение" {
  run warn "предупреждение"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[!]"* ]]
  [[ "$output" == *"предупреждение"* ]]
}

@test "error: выводит красный крест" {
  run error "ошибка"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[✗]"* ]]
  [[ "$output" == *"ошибка"* ]]
}

@test "header: выводит заголовок" {
  run header "Заголовок"
  [ "$status" -eq 0 ]
  [[ "$output" == *"━━━"* ]]
  [[ "$output" == *"Заголовок"* ]]
}

@test "info: выводит INFO" {
  run info "информация"
  [ "$status" -eq 0 ]
  [[ "$output" == *"INFO:"* ]]
  [[ "$output" == *"информация"* ]]
}

# ═══════════════════════════════════════════════════
# Тесты: проверки
# ═══════════════════════════════════════════════════

@test "check_cmd: существующая команда возвращает 0" {
  run check_cmd "bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bash установлен"* ]]
}

@test "check_cmd: несуществующая команда возвращает 1" {
  run check_cmd "nonexistent_cmd_xyz"
  [ "$status" -eq 1 ]
  [[ "$output" == *"не найден"* ]]
}

@test "require_cmd: существующая команда не вызывает ошибку" {
  run require_cmd "bash"
  [ "$status" -eq 0 ]
}

@test "require_cmd: несуществующая команда завершается с ошибкой" {
  run require_cmd "nonexistent_cmd_xyz"
  [ "$status" -eq 1 ]
}

# ═══════════════════════════════════════════════════
# Тесты: dry-run
# ═══════════════════════════════════════════════════

@test "dry_run: возвращает 0 при INSTALL_DRY_RUN=1" {
  export INSTALL_DRY_RUN=1
  run dry_run "тест"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY-RUN]"* ]]
}

@test "dry_run: возвращает 1 при INSTALL_DRY_RUN=0" {
  export INSTALL_DRY_RUN=0
  run dry_run "тест"
  [ "$status" -eq 1 ]
}

# ═══════════════════════════════════════════════════
# Тесты: бэкап
# ═══════════════════════════════════════════════════

@test "backup_file: создаёт бэкап файла" {
  BACKUP_DIR="/tmp/kilo-test-backup"
  mkdir -p "$BACKUP_DIR"
  echo "test content" >"$TEST_DIR/test.txt"
  run backup_file "$TEST_DIR/test.txt"
  [ "$status" -eq 0 ]
  # Проверяем, что бэкап создан
  find "$BACKUP_DIR" -name "test.txt" | grep -q .
}

@test "backup_file: несуществующий файл не вызывает ошибку" {
  BACKUP_DIR="/tmp/kilo-test-backup"
  run backup_file "$TEST_DIR/nonexistent.txt"
  [ "$status" -eq 0 ]
  [[ "$output" == "" ]]
}

# ═══════════════════════════════════════════════════
# Тесты: manifest
# ═══════════════════════════════════════════════════

@test "manifest_init: создаёт manifest.json" {
  MANIFEST_DIR="$TEST_DIR/manifest"
  MANIFEST_FILE="$MANIFEST_DIR/manifest.json"
  export INSTALL_DRY_RUN=0
  run manifest_init
  [ "$status" -eq 0 ]
  [ -f "$MANIFEST_FILE" ]
}

@test "manifest_init: содержит правильную структуру" {
  MANIFEST_DIR="$TEST_DIR/manifest2"
  MANIFEST_FILE="$MANIFEST_DIR/manifest.json"
  export INSTALL_DRY_RUN=0
  manifest_init
  run python3 -c "import json; m=json.load(open('$MANIFEST_FILE')); print(m['version'])"
  [ "$status" -eq 0 ]
  [[ "$output" == "1.3.0" ]]
}

@test "manifest_add_file: добавляет файл в manifest" {
  MANIFEST_DIR="$TEST_DIR/manifest3"
  MANIFEST_FILE="$MANIFEST_DIR/manifest.json"
  export INSTALL_DRY_RUN=0
  manifest_init
  echo "test" >"$TEST_DIR/test_manifest.txt"
  manifest_add_file "$TEST_DIR/test_manifest.txt"
  run python3 -c "import json; m=json.load(open('$MANIFEST_FILE')); print(len(m['files']))"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ] || [ "$output" = "2" ] # 1 или 2 (с учётом файла манифеста)
}

@test "manifest_set_config: устанавливает конфигурацию" {
  MANIFEST_DIR="$TEST_DIR/manifest4"
  MANIFEST_FILE="$MANIFEST_DIR/manifest.json"
  export INSTALL_DRY_RUN=0
  manifest_init
  manifest_set_config "test_key" "test_value"
  run python3 -c "import json; m=json.load(open('$MANIFEST_FILE')); print(m['configs']['test_key'])"
  [ "$status" -eq 0 ]
  [ "$output" = "test_value" ]
}

# ═══════════════════════════════════════════════════
# Тесты: show_version
# ═══════════════════════════════════════════════════

@test "show_version: выводит версию" {
  run show_version
  [ "$status" -eq 0 ]
  [[ "$output" == *"KiloCode CLI Installer"* ]]
}
