#!/usr/bin/env bash
# ============================================
# KiloCode CLI — Установщик для Linux Mint
# Репозиторий: https://github.com/ZDarow/K_I_L_O
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib.sh"
SRC_DIR="$SCRIPT_DIR/src"

# ─── Аргументы ─────────────────────────────
MODE="install"
INSTALL_DRY_RUN=0
RESUME_FROM=1
SKIP_PREFLIGHT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check | -c)
      MODE="check"
      shift
      ;;
    --verify | -v)
      MODE="verify"
      shift
      ;;
    --uninstall | -u)
      MODE="uninstall"
      shift
      ;;
    --dry-run | -n)
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
      echo "Использование: install.sh [опции]"
      echo "  --check, -c       Проверка системы (pre-flight)"
      echo "  --verify, -v      Проверка установки"
      echo "  --uninstall, -u   Удаление KiloCode"
      echo "  --dry-run, -n     Сухой прогон установки"
      echo "  --skip-preflight  Без pre-flight проверки"
      echo "  --resume-from=N   Начать с шага N"
      exit 0
      ;;
    *)
      warn "Неизвестно: $1"
      shift
      ;;
  esac
done

trap_install

# ══════════════════════════════════════════════════════════════
# ФУНКЦИИ
# ══════════════════════════════════════════════════════════════

# ─── Pre-flight проверка ──────────────────────
check_system() {
  local ALL_OK=true
  header "Pre-flight проверка"

  subheader "ОС"
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    # shellcheck disable=SC2153
    echo "  $NAME $VERSION_ID ($(uname -m))"
  fi

  subheader "sudo"
  if sudo -n true 2>/dev/null; then
    echo "  sudo доступен"
  else warn "  sudo требует пароль"; fi

  subheader "Интернет"
  curl -s --max-time 5 https://github.com >/dev/null 2>&1 \
    && echo "  GitHub доступен" \
    || warn "  GitHub недоступен"

  subheader "Node.js"
  if command -v node &>/dev/null; then
    local v
    v=$(node --version)
    echo "  $v"
  else warn "  не установлен"; fi

  subheader "Git"
  command -v git &>/dev/null && echo "  Git $(git --version | cut -d' ' -f3)" || warn "  не установлен"

  subheader "Диск"
  local avail
  avail=$(df "$HOME" | awk 'NR==2 {print $4}')
  local mb=$((avail / 1024))
  if [[ $mb -lt 500 ]]; then
    error "  Меньше 500МБ ($mb МБ)"
    ALL_OK=false
  else echo "  $mb МБ свободно"; fi

  echo
  $ALL_OK && log "Всё в порядке" || {
    error "Критические проблемы"
    exit 1
  }
}

# ─── Проверка установки ──────────────────────
verify_installation() {
  local ALL_OK=true WARNINGS=0
  header "Верификация"

  subheader "Конфигурация"
  for f in "$HOME/.kilo/kilo.jsonc" "$HOME/.kilo/package.json" \
    "$HOME/.config/kilo/kilo.jsonc" "$HOME/.config/kilo/AGENTS.md" \
    "$HOME/AGENTS.md" "$HOME/.local/share/kilo/manifest.json"; do
    [[ -f "$f" ]] && log "  $f" || {
      warn "  $f — нет"
      WARNINGS=$((WARNINGS + 1))
    }
  done

  subheader "Node.js"
  check_cmd node
  check_cmd npm

  subheader "KiloCode"
  if npx --yes kilo --version &>/dev/null 2>&1; then
    log "  Доступен"
  else
    warn "  Нет"
    WARNINGS=$((WARNINGS + 1))
  fi

  subheader "npm-зависимости"
  for d in "$HOME/.kilo" "$HOME/.config/kilo"; do
    if [[ -d "$d/node_modules" ]]; then
      local n
      n=$(find "$d/node_modules" -mindepth 1 -maxdepth 1 -type d | wc -l)
      log "  $d: $n пакетов"
    else
      warn "  $d: node_modules нет"
      WARNINGS=$((WARNINGS + 1))
    fi
  done

  subheader "API-ключи"
  if python3 -c "import json; d=json.load(open('$HOME/.local/share/kilo/auth.json')); print(len([k for k in d if d[k].get('key','') and d[k]['key']!='YOUR_API_KEY_HERE']))" &>/dev/null; then
    log "  Ключи настроены"
  else
    warn "  Ключи не настроены"
    WARNINGS=$((WARNINGS + 1))
  fi

  subheader "SSH"
  [[ -f "$HOME/.ssh/id_ed25519" ]] && log "  Ключ есть" || {
    warn "  Ключа нет"
    WARNINGS=$((WARNINGS + 1))
  }

  subheader "Manifest"
  if [[ -f "$HOME/.local/share/kilo/manifest.json" ]]; then
    local files
    files=$(python3 -c "import json; print(len(json.load(open('$HOME/.local/share/kilo/manifest.json')).get('files',[])))" 2>/dev/null || echo "0")
    log "  $files файлов учтено"
  else
    warn "  Manifest нет"
    WARNINGS=$((WARNINGS + 1))
  fi

  echo
  if $ALL_OK && [[ $WARNINGS -eq 0 ]]; then
    log "Установка корректна"
  elif $ALL_OK; then
    warn "Есть $WARNINGS предупреждений"
  else
    error "Критические ошибки"
    exit 1
  fi
}

# ─── Удаление ────────────────────────────────
do_uninstall() {
  header "Удаление KiloCode"

  if [[ $INSTALL_DRY_RUN != 1 ]]; then
    warn "Будут удалены все файлы KiloCode. Бэкап: $BACKUP_DIR"
    read -rp "Продолжить? (yes/no): " c
    [[ "$c" != "yes" ]] && {
      echo "Отменено."
      exit 0
    }
  fi

  for d in "$HOME/.kilo" "$HOME/.config/kilo"; do
    if [[ -d "$d" ]]; then
      dry_run "rm -rf $d" || {
        rm -rf "$d"
        log "  Удалено: $d"
      }
    else info "  Нет: $d"; fi
  done

  for f in "$HOME/.local/share/kilo/auth.json" "$HOME/.local/share/kilo/manifest.json"; do
    if [[ -f "$f" ]]; then
      dry_run "rm -f $f" || {
        rm -f "$f"
        log "  Удалено: $f"
      }
    else info "  Нет: $f"; fi
  done

  header "Shell-конфиги"
  for rc in ".bashrc" ".profile"; do
    local path="$HOME/$rc"
    if [[ ! -f "$path" ]]; then
      info "  Нет: $path"
      continue
    fi
    local bak="$BACKUP_DIR/$rc"
    if [[ -f "$bak" ]]; then
      dry_run "cp $bak $path" || {
        cp "$bak" "$path"
        log "  Восстановлен: $rc"
      }
    elif grep -q "KiloCode CLI" "$path" 2>/dev/null; then
      dry_run "sed -i '/KiloCode/,/=====/d' $path" || {
        sed -i '/# ===.*KiloCode/,/# ===/d' "$path"
        log "  Блок KiloCode удалён из $rc"
      }
    else info "  Блока KiloCode нет в $rc"; fi
  done

  echo
  if [[ $INSTALL_DRY_RUN = 1 ]]; then
    warn "Сухой прогон. Ничего не удалено."
  else log "Удаление завершено"; fi
}

# ─── Шаг с resume ────────────────────────────
step() {
  local num="$1" desc="$2"
  shift 2
  if [[ $num -lt $RESUME_FROM ]]; then
    echo "  ${YELLOW}[ПРОПУСК]${NC} Шаг $num (resume-from=$RESUME_FROM)"
    return 0
  fi
  header "Шаг $num: $desc"
  "$@" || true
  if [[ $INSTALL_DRY_RUN = 0 ]]; then manifest_set_config "last_step" "$num" || true; fi
}

# ─── Шаги установки ──────────────────────────
detect_os() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "  ОС: $NAME $VERSION_ID"
    echo "  Архитектура: $(uname -m)"
  else warn "Не удалось определить ОС"; fi
}

install_system_deps() {
  dry_run "установка системных пакетов" && return 0
  if ! command -v node &>/dev/null; then
    warn "Устанавливаю Node.js 22 LTS..."
    run_sudo "NodeSource" curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    run_sudo "Node.js" apt-get install -y nodejs
  fi
  log "Node.js $(node --version)"
  run_sudo "packages" apt-get install -y -qq python3 python3-pip git curl wget build-essential || true
  [[ $INSTALL_DRY_RUN = 0 ]] && manifest_set_config "packages" "nodejs python3 git"
}

install_kilocode() {
  command -v npx &>/dev/null || {
    warn "npx не найден"
    return 0
  }
  dry_run "npx --yes kilo --version" && return 0
  npx --yes kilo --version &>/dev/null 2>&1 && log "KiloCode уже доступен" || {
    npm install -g @kilocode/cli 2>&1 | tail -3 | tee -a "$LOG_FILE" || true
  }
}

create_dirs() {
  dry_run "mkdir -p \$HOME/.kilo \$HOME/.config/kilo \$HOME/.local/share/kilo" && return 0
  mkdir -p "$HOME/.kilo" "$HOME/.config/kilo" "$HOME/.local/share/kilo" "$HOME/.npm"
  log "Директории созданы"
}

install_kilo_config() {
  [[ -d "$SRC_DIR/kilo-config" ]] || {
    warn "src/kilo-config/ нет"
    return 0
  }
  dry_run "cp -r $SRC_DIR/kilo-config/* \$HOME/.kilo/" && return 0
  [[ -f "$HOME/.kilo/kilo.jsonc" ]] && backup_file "$HOME/.kilo"
  local count=0
  while IFS= read -r -d '' f; do
    local rel="${f#"$SRC_DIR/kilo-config/"}"
    mkdir -p "$HOME/.kilo/$(dirname "$rel")"
    cp "$f" "$HOME/.kilo/$rel"
    manifest_add_file "$HOME/.kilo/$rel"
    count=$((count + 1))
  done < <(find "$SRC_DIR/kilo-config" -type f ! -name 'package-lock.json' -print0)
  log "~/.kilo/: $count файлов"
}

install_global_config() {
  [[ -d "$SRC_DIR/global-config" ]] || {
    warn "src/global-config/ нет"
    return 0
  }
  dry_run "cp -r $SRC_DIR/global-config/* \$HOME/.config/kilo/" && return 0
  [[ -f "$HOME/.config/kilo/kilo.jsonc" ]] && backup_file "$HOME/.config/kilo"
  local count=0
  while IFS= read -r -d '' f; do
    local rel="${f#"$SRC_DIR/global-config/"}"
    mkdir -p "$HOME/.config/kilo/$(dirname "$rel")"
    cp "$f" "$HOME/.config/kilo/$rel"
    manifest_add_file "$HOME/.config/kilo/$rel"
    count=$((count + 1))
  done < <(find "$SRC_DIR/global-config" -type f ! -name 'package-lock.json' -print0)
  log "~/.config/kilo/ : $count файлов"
}

install_auth() {
  [[ -f "$SRC_DIR/local-share/auth.template.json" ]] || {
    warn "auth template нет"
    return 0
  }
  dry_run "cp $SRC_DIR/local-share/auth.template.json \$HOME/.local/share/kilo/auth.json" && return 0
  if [[ ! -f "$HOME/.local/share/kilo/auth.json" ]]; then
    cp "$SRC_DIR/local-share/auth.template.json" "$HOME/.local/share/kilo/auth.json"
    manifest_add_file "$HOME/.local/share/kilo/auth.json"
    warn "Замени API-ключ в ~/.local/share/kilo/auth.json"
  else log "auth.json уже есть"; fi
}

install_shell_config() {
  for pair in "bashrc-append.sh .bashrc" "profile-append.sh .profile"; do
    set -- $pair
    local src_file="$1" rc_file="$2"
    [[ -f "$SRC_DIR/$src_file" ]] || continue
    dry_run "добавить в $rc_file" && continue
    if ! grep -q "KiloCode CLI" "$HOME/$rc_file" 2>/dev/null; then
      backup_file "$HOME/$rc_file" >/dev/null
      {
        echo
        echo "# ===== KiloCode CLI — установлено K_I_L_O ====="
        cat "$SRC_DIR/$src_file"
      } >>"$HOME/$rc_file"
      manifest_add_file "$HOME/$rc_file"
      log "Дополнения в $rc_file"
    else log "$rc_file уже содержит KiloCode"; fi
  done
}

install_npm_deps() {
  dry_run "npm install" && return 0
  for d in "$HOME/.kilo" "$HOME/.config/kilo"; do
    [[ -f "$d/package.json" ]] || continue
    (cd "$d" && npm install 2>&1 | tail -3 | tee -a "$LOG_FILE") \
      && log "npm-зависимости $(basename "$d") установлены" \
      || warn "npm install в $(basename "$d") с ошибками"
  done
}

configure_git() {
  dry_run "git config" && return 0
  local name email
  name="$(git config --global user.name 2>/dev/null || true)"
  email="$(git config --global user.email 2>/dev/null || true)"
  if [[ -n "$name" && -n "$email" ]]; then
    log "Git: $name <$email>"
  else warn "Настрой git config --global user.name/email"; fi
  git config --global init.defaultBranch master 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════
# ВЫПОЛНЕНИЕ
# ══════════════════════════════════════════════════════════════

case "$MODE" in
  check)
    check_system
    exit 0
    ;;
  verify)
    verify_installation
    exit 0
    ;;
  uninstall)
    do_uninstall
    exit 0
    ;;
esac

# ─── Install mode ─────────────────────────────
if [[ $INSTALL_DRY_RUN = 1 ]]; then
  echo -e "${YELLOW}╔══════════════════════════════╗${NC}"
  echo -e "${YELLOW}║  KiloCode — СУХОЙ ПРОГОН    ║${NC}"
  echo -e "${YELLOW}╚══════════════════════════════╝${NC}"
  echo "  Файлы не будут изменены."
else
  echo -e "${BLUE}╔══════════════════════════════╗${NC}"
  echo -e "${BLUE}║  KiloCode CLI — Установщик   ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════╝${NC}"
fi

[[ $SKIP_PREFLIGHT = 0 ]] && check_system

if [[ $INSTALL_DRY_RUN = 0 ]]; then
  manifest_init
  manifest_set_config "src_dir" "$SRC_DIR"
  manifest_set_config "os" "$(uname -s)"
  manifest_set_config "backup_dir" "$BACKUP_DIR"
fi

step 1 "Детекция ОС" detect_os
step 2 "Системные зависимости" install_system_deps
step 3 "KiloCode CLI" install_kilocode
step 4 "Директории" create_dirs
step 5 "Проектная конфигурация (~/.kilo/)" install_kilo_config
step 6 "Глобальная конфигурация (~/.config/kilo/)" install_global_config
step 7 "Аутентификация" install_auth
step 8 "Shell-конфиги" install_shell_config
step 9 "npm-зависимости" install_npm_deps
step 10 "Git" configure_git

# ─── Завершение ──────────────────────────────
header "Готово"
if [[ $INSTALL_DRY_RUN = 1 ]]; then
  echo -e "  ${YELLOW}Сухой прогон. Для установки запусти без --dry-run${NC}"
else
  echo -e "  ${GREEN}Дальнейшие шаги:${NC}"
  echo "  1. source ~/.bashrc"
  echo "  2. Настрой API-ключ в ~/.local/share/kilo/auth.json"
  echo "  3. npx kilo"
  echo "  4. install.sh --verify"
  echo "  5. install.sh --uninstall (для удаления)"
  echo "  Лог: $LOG_FILE"
  echo "  Бэкап: $BACKUP_DIR"
fi
