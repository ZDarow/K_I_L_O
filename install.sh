#!/usr/bin/env bash
# ============================================
# KiloCode CLI — Установщик для Linux Mint
# Репозиторий: https://github.com/ZDarow/K_I_L_O
# ============================================
set -euo pipefail

# Директория скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Загрузка общей библиотеки
if [[ -f "$SCRIPT_DIR/scripts/lib.sh" ]]; then
  source "$SCRIPT_DIR/scripts/lib.sh"
else
  # Fallback — ручное определение, если lib.sh ещё нет
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
  log() { echo -e "${GREEN}[✓]${NC} $1"; }
  warn() { echo -e "${YELLOW}[!]${NC} $1"; }
  error() { echo -e "${RED}[✗]${NC} $1"; }
  header() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }
fi

SRC_DIR="$SCRIPT_DIR/src"

# ─── Парсинг аргументов ──────────────────────────
INSTALL_DRY_RUN=0
RESUME_FROM=1
SKIP_PREFLIGHT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      INSTALL_DRY_RUN=1
      shift
      ;;
    --resume-from)
      RESUME_FROM="$2"
      shift 2
      ;;
    --skip-preflight)
      SKIP_PREFLIGHT=1
      shift
      ;;
    --help | -h)
      echo "Usage: ./install.sh [--dry-run] [--resume-from=N] [--skip-preflight]"
      exit 0
      ;;
    *)
      warn "Неизвестный аргумент: $1"
      shift
      ;;
  esac
done

# ─── Trap ─────────────────────────────────────────
trap_install

# ─── Dry-run режим ───────────────────────────────
if [[ "$INSTALL_DRY_RUN" = "1" ]]; then
  echo -e "${YELLOW}"
  echo "╔══════════════════════════════════════════╗"
  echo "║  KiloCode CLI — СУХОЙ ПРОГОН             ║"
  echo "╚══════════════════════════════════════════╝"
  echo -e "${NC}"
  echo "  Файлы не будут изменены."
  echo ""
else
  echo -e "${BLUE}"
  echo "╔══════════════════════════════════════════╗"
  echo "║  KiloCode CLI — Установщик для Linux Mint ║"
  echo "╚══════════════════════════════════════════╝"
  echo -e "${NC}"
fi

echo "Лог: $LOG_FILE"

# ─── Pre-flight ──────────────────────────────────
if [[ "$SKIP_PREFLIGHT" = "0" ]] && [[ -f "$SCRIPT_DIR/scripts/preflight.sh" ]]; then
  "$SCRIPT_DIR/scripts/preflight.sh" || {
    error "Pre-flight проверка не пройдена. Исправь проблемы и запусти снова."
    exit 1
  }
fi

# ─── Инициализация манифеста ─────────────────────
if [[ "$INSTALL_DRY_RUN" = "0" ]]; then
  manifest_init
  manifest_set_config "src_dir" "$SRC_DIR"
  manifest_set_config "os" "$(uname -s)"
  manifest_set_config "host" "$(hostname 2>/dev/null || echo 'unknown')"
  manifest_set_config "backup_dir" "$BACKUP_DIR"
fi

# ══════════════════════════════════════════════════════════════
# ВСЕ ФУНКЦИИ (определяются до вызовов step для надёжности)
# ══════════════════════════════════════════════════════════════

# ─── Функция шага с resume ───────────────────────
step() {
  local num="$1"
  local desc="$2"
  shift 2
  if [[ "$num" -lt "$RESUME_FROM" ]]; then
    echo -e "  ${YELLOW}[ПРОПУСК]${NC} Шаг $num: $desc (resume-from=$RESUME_FROM)"
    return 0
  fi
  header "Шаг $num: $desc"
  "$@"
  if [[ "$INSTALL_DRY_RUN" = "0" ]]; then
    manifest_set_config "last_step" "$num"
  fi
}

# ─── Шаг 1: Детекция ОС ──────────────────────────
detect_os() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "  ОС: $NAME $VERSION_ID"
    echo "  Архитектура: $(uname -m)"
  else
    warn "Не удалось определить ОС"
  fi
}

# ─── Шаг 2: Установка системных зависимостей ──────
install_system_deps() {
  if dry_run "установка системных пакетов"; then
    return 0
  fi

  # Node.js (через NodeSource)
  if ! command -v node &>/dev/null; then
    warn "Node.js не найден. Устанавливаю Node.js 22 LTS..."
    run_sudo "NodeSource setup" curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    run_sudo "Node.js install" apt-get install -y nodejs
    log "Node.js $(node --version) установлен"
  else
    log "Node.js $(node --version)"
  fi

  # Python и инструменты
  run_sudo "system packages" apt-get install -y -qq \
    python3 python3-pip python3-venv python3-dev \
    git curl wget build-essential \
    cmake \
    libglib2.0-dev || true
  log "Системные пакеты установлены"

  if [[ "$INSTALL_DRY_RUN" = "0" ]]; then
    manifest_set_config "packages" "nodejs python3 git"
  fi
}

# ─── Шаг 3: Установка KiloCode CLI ────────────────
install_kilocode() {
  if command -v npx &>/dev/null; then
    if dry_run "npx --yes kilo --version"; then
      return 0
    fi
    if npx --yes kilo --version &>/dev/null 2>&1; then
      log "KiloCode CLI уже доступен"
    else
      warn "Устанавливаю KiloCode CLI через npm..."
      npm install -g @kilocode/cli 2>&1 | tail -5 | tee -a "$LOG_FILE" || true
    fi
  else
    warn "npx не найден. Установка KiloCode CLI отложена."
  fi
}

# ─── Шаг 4: Создание структуры директорий ─────────
create_dirs() {
  dry_run "mkdir -p $HOME/.kilo $HOME/.config/kilo $HOME/.local/share/kilo $HOME/.ssh $HOME/.npm" && return 0
  mkdir -p "$HOME/.kilo"
  mkdir -p "$HOME/.config/kilo"
  mkdir -p "$HOME/.local/share/kilo"
  mkdir -p "$HOME/.ssh"
  mkdir -p "$HOME/.npm"
  log "Директории созданы"
}

# ─── Шаг 5: Копирование проектной конфигурации Kilo ──
install_kilo_config() {
  if [[ ! -d "$SRC_DIR/kilo-config" ]]; then
    warn "Источник src/kilo-config/ не найден, пропускаю"
    return 0
  fi

  if dry_run "cp -r $SRC_DIR/kilo-config/* $HOME/.kilo/"; then
    return 0
  fi

  # Бэкап существующей конфигурации
  if [[ -f "$HOME/.kilo/kilo.jsonc" ]]; then
    backup_file "$HOME/.kilo"
  fi

  # Копируем каждый файл с проверкой
  local count=0
  while IFS= read -r -d '' f; do
    local rel="${f#$SRC_DIR/kilo-config/}"
    local dest="$HOME/.kilo/$rel"
    mkdir -p "$(dirname "$dest")"
    cp "$f" "$dest"
    manifest_add_file "$dest"
    count=$((count + 1))
  done < <(find "$SRC_DIR/kilo-config" -type f -print0)

  log "Конфигурация ~/.kilo/ установлена ($count файлов)"
}

# ─── Шаг 6: Копирование глобальной конфигурации Kilo ──
install_global_config() {
  if [[ ! -d "$SRC_DIR/global-config" ]]; then
    warn "Источник src/global-config/ не найден, пропускаю"
    return 0
  fi

  if dry_run "cp -r $SRC_DIR/global-config/* $HOME/.config/kilo/"; then
    return 0
  fi

  # Бэкап существующей конфигурации
  if [[ -f "$HOME/.config/kilo/kilo.jsonc" ]]; then
    backup_file "$HOME/.config/kilo"
  fi

  local count=0
  while IFS= read -r -d '' f; do
    local rel="${f#$SRC_DIR/global-config/}"
    local dest="$HOME/.config/kilo/$rel"
    mkdir -p "$(dirname "$dest")"
    cp "$f" "$dest"
    manifest_add_file "$dest"
    count=$((count + 1))
  done < <(find "$SRC_DIR/global-config" -type f -print0)

  log "Конфигурация ~/.config/kilo/ установлена ($count файлов)"
}

# ─── Шаг 7: Установка шаблона auth.json ───────────
install_auth() {
  if [[ ! -f "$SRC_DIR/local-share/auth.template.json" ]]; then
    warn "Шаблон auth.json не найден, пропускаю"
    return 0
  fi

  if dry_run "cp $SRC_DIR/local-share/auth.template.json $HOME/.local/share/kilo/auth.json"; then
    return 0
  fi

  if [[ ! -f "$HOME/.local/share/kilo/auth.json" ]]; then
    cp "$SRC_DIR/local-share/auth.template.json" "$HOME/.local/share/kilo/auth.json"
    manifest_add_file "$HOME/.local/share/kilo/auth.json"
    warn "Шаблон auth.json установлен. Замени API-ключ в ~/.local/share/kilo/auth.json"
  else
    log "auth.json уже существует, пропускаю"
  fi
}

# ─── Шаг 8: Настройка SSH ─────────────────────────
install_ssh() {
  if [[ ! -d "$SRC_DIR/ssh" ]]; then
    warn "Источник src/ssh/ не найден, пропускаю"
    return 0
  fi

  # SSH config
  if [[ -f "$SRC_DIR/ssh/config" ]]; then
    if dry_run "cp $SRC_DIR/ssh/config $HOME/.ssh/config && chmod 600 $HOME/.ssh/config"; then
      :
    elif [[ ! -f "$HOME/.ssh/config" ]]; then
      backup_file "$HOME/.ssh/config" 2>/dev/null || true
      cp "$SRC_DIR/ssh/config" "$HOME/.ssh/config"
      chmod 600 "$HOME/.ssh/config"
      manifest_add_file "$HOME/.ssh/config"
      log "SSH config установлен"
    else
      log "SSH config уже существует, пропускаю"
    fi
  fi

  # Публичный ключ
  if [[ -f "$SRC_DIR/ssh/id_ed25519.pub" ]]; then
    if dry_run "cp $SRC_DIR/ssh/id_ed25519.pub $HOME/.ssh/id_ed25519.pub && chmod 644 $HOME/.ssh/id_ed25519.pub"; then
      :
    elif [[ ! -f "$HOME/.ssh/id_ed25519.pub" ]]; then
      cp "$SRC_DIR/ssh/id_ed25519.pub" "$HOME/.ssh/id_ed25519.pub"
      chmod 644 "$HOME/.ssh/id_ed25519.pub"
      log "SSH публичный ключ установлен"
      warn "Приватный ключ (~/.ssh/id_ed25519) нужно скопировать вручную!"
    else
      log "SSH публичный ключ уже существует, пропускаю"
    fi
  fi

  chmod 700 "$HOME/.ssh" 2>/dev/null || true
}

# ─── Шаг 9: Обновление .bashrc и .profile ─────────
install_shell_config() {
  local f

  # .bashrc
  if [[ -f "$SRC_DIR/bashrc-append.sh" ]]; then
    if dry_run "добавить дополнения KiloCode в .bashrc"; then
      :
    elif ! grep -q "KiloCode CLI" "$HOME/.bashrc" 2>/dev/null; then
      backup_file "$HOME/.bashrc" >/dev/null
      {
        echo ""
        echo "# ============================================"
        echo "# Блок KiloCode CLI — установлено K_I_L_O"
        echo "# ============================================"
        cat "$SRC_DIR/bashrc-append.sh"
      } >>"$HOME/.bashrc"
      manifest_add_file "$HOME/.bashrc"
      log "Дополнения добавлены в ~/.bashrc"
    else
      log "~/.bashrc уже содержит дополнения KiloCode"
    fi
  fi

  # .profile
  if [[ -f "$SRC_DIR/profile-append.sh" ]]; then
    if dry_run "добавить дополнения KiloCode в .profile"; then
      :
    elif ! grep -q "KiloCode CLI" "$HOME/.profile" 2>/dev/null; then
      backup_file "$HOME/.profile" >/dev/null
      {
        echo ""
        echo "# ============================================"
        echo "# Блок KiloCode CLI — установлено K_I_L_O"
        echo "# ============================================"
        cat "$SRC_DIR/profile-append.sh"
      } >>"$HOME/.profile"
      manifest_add_file "$HOME/.profile"
      log "Дополнения добавлены в ~/.profile"
    else
      log "~/.profile уже содержит дополнения KiloCode"
    fi
  fi
}

# ─── Шаг 10: Установка npm-зависимостей Kilo ──────
install_npm_deps() {
  if dry_run "npm install в ~/.kilo/ и ~/.config/kilo/"; then
    return 0
  fi

  if [[ -f "$HOME/.kilo/package.json" ]]; then
    (cd "$HOME/.kilo" && npm install 2>&1 | tail -3 | tee -a "$LOG_FILE") \
      && log "npm-зависимости ~/.kilo/ установлены" \
      || warn "npm install в ~/.kilo/ завершился с ошибками"
  fi

  if [[ -f "$HOME/.config/kilo/package.json" ]]; then
    (cd "$HOME/.config/kilo" && npm install 2>&1 | tail -3 | tee -a "$LOG_FILE") \
      && log "npm-зависимости ~/.config/kilo/ установлены" \
      || warn "npm install в ~/.config/kilo/ завершился с ошибками"
  fi
}

# ─── Шаг 12: Настройка Git ────────────────────────
configure_git() {
  if dry_run "git config --global"; then
    return 0
  fi

  # Проверяем глобальную конфигурацию Git, но НЕ навязываем персональные данные
  local name email
  name="$(git config --global user.name 2>/dev/null || true)"
  email="$(git config --global user.email 2>/dev/null || true)"

  if [[ -n "$name" ]] && [[ -n "$email" ]]; then
    log "Git настроен: $name <$email>"
  else
    warn "Git user.name или user.email не настроены глобально."
    warn "Настрой вручную: git config --global user.name \"Имя\" && git config --global user.email \"email@example.com\""
  fi

  git config --global init.defaultBranch master 2>/dev/null || true
  log "Git глобальная конфигурация проверена"
}

# ─── Шаг 13: Проверка установки ───────────────────
verify_installation() {
  if [[ "$INSTALL_DRY_RUN" = "1" ]]; then
    echo "  Сухой прогон завершён. Ничего не изменено."
    return 0
  fi

  echo ""
  echo -e "  ${GREEN}KiloCode CLI — проверка:${NC}"
  check_cmd node || true
  check_cmd npm || true
  check_cmd npx || true
  check_cmd git || true
  check_cmd python3 || true

  echo ""
  echo -e "  ${GREEN}Конфигурационные файлы:${NC}"
  for f in "$HOME/.kilo/kilo.jsonc" \
    "$HOME/.config/kilo/kilo.jsonc" \
    "$HOME/.config/kilo/AGENTS.md" \
    "$HOME/AGENTS.md" \
    "$HOME/.local/share/kilo/manifest.json"; do
    if [[ -f "$f" ]]; then
      log "  $f"
    else
      warn "  $f — не найден"
    fi
  done

  # Устанавливаем флаг успешного завершения
  manifest_set_config "status" "complete"
  manifest_set_config "completed_at" "$(date -Iseconds)"
}

# ══════════════════════════════════════════════════════════════
# ВЫПОЛНЕНИЕ ШАГОВ
# ══════════════════════════════════════════════════════════════

step 1 "Детекция системы" detect_os
step 2 "Установка системных зависимостей" install_system_deps
step 3 "Установка KiloCode CLI" install_kilocode
step 4 "Создание структуры директорий" create_dirs
step 5 "Установка проектной конфигурации Kilo (~/.kilo/)" install_kilo_config
step 6 "Установка глобальной конфигурации Kilo (~/.config/kilo/)" install_global_config
step 7 "Настройка аутентификации" install_auth
step 8 "Настройка SSH" install_ssh
step 9 "Обновление shell-конфигурации" install_shell_config
step 10 "Установка npm-зависимостей Kilo" install_npm_deps
step 11 "Настройка Git" configure_git
step 12 "Проверка установки" verify_installation

# ═══════════════════════════════════════════════════
# Завершение
# ═══════════════════════════════════════════════════
header "Установка завершена"

if [[ "$INSTALL_DRY_RUN" = "1" ]]; then
  echo ""
  echo -e "  ${YELLOW}Это был сухой прогон. Ничего не изменено.${NC}"
  echo -e "  ${YELLOW}Для реальной установки запусти без --dry-run${NC}"
else
  echo ""
  echo -e "  ${GREEN}Дальнейшие шаги:${NC}"
  echo "  1. Активируй окружение: source ~/.bashrc"
  echo "  2. Настрой API-ключ:  nano ~/.local/share/kilo/auth.json"
  echo "  3. Копируй SSH-ключи: ~/.ssh/id_ed25519 (приватный)"
  echo "  4. Запусти Kilo:      npx kilo"
  echo "  5. Проверка:          make verify"
  echo ""
  echo -e "  Лог установки: ${YELLOW}$LOG_FILE${NC}"
  echo -e "  Бэкап:         ${YELLOW}$BACKUP_DIR${NC}"
  echo ""
  echo -e "  ${GREEN}Для удаления: make uninstall${NC}"
fi
