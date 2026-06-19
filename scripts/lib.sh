#!/usr/bin/env bash
# ============================================
# KiloCode CLI — общие функции для скриптов
# ============================================

set -euo pipefail

# ---- Цвета ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# ---- Конфигурация ----
KILO_VERSION="1.1.0"
MANIFEST_DIR="$HOME/.local/share/kilo"
MANIFEST_FILE="$MANIFEST_DIR/manifest.json"
BACKUP_DIR="/tmp/kilo-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/kilo-install-$(date +%Y%m%d-%H%M%S).log"

# ---- Логирование ----
log()      { echo -e "${GREEN}[✓]${NC} $1"; }
warn()     { echo -e "${YELLOW}[!]${NC} $1"; }
error()    { echo -e "${RED}[✗]${NC} $1"; }
header()   { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }
subheader(){ echo -e "  ${CYAN}→${NC} $1"; }
info()     { echo -e "  ${BOLD}INFO:${NC} $1"; }

log_to_file() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

# ---- Проверки ----
check_cmd() {
    if command -v "$1" &>/dev/null; then
        local ver
        ver=$("$1" --version 2>&1 | head -1)
        log "$1 установлен: $ver"
        return 0
    else
        warn "$1 не найден"
        return 1
    fi
}

require_cmd() {
    if ! command -v "$1" &>/dev/null; then
        error "Обязательная команда не найдена: $1"
        exit 1
    fi
}

# ---- Бекап ----
backup_file() {
    local src="$1"
    if [[ -f "$src" ]] || [[ -d "$src" ]]; then
        local dest
        dest="${BACKUP_DIR}/${src#${HOME}/}"
        mkdir -p "$(dirname "$dest")"
        cp -r "$src" "$dest"
        log_to_file "Backup: $src → $dest"
        echo "$dest"
    fi
}

backup_and_copy() {
    local src="$1"
    local dest="$2"
    if [[ -e "$dest" ]]; then
        backup_file "$dest" >/dev/null
    fi
    mkdir -p "$(dirname "$dest")"
    cp -r "$src" "$dest"
    log "Установлено: $dest"
}

# ---- Dry-run ----
dry_run() {
    if [[ "${INSTALL_DRY_RUN:-0}" = "1" ]]; then
        echo -e "  ${YELLOW}[DRY-RUN]${NC} $1"
        return 0
    fi
    return 1
}

run_cmd() {
    local desc="$1"
    shift
    if dry_run "[SKIP] $desc: $*"; then
        return 0
    fi
    log_to_file "RUN: $*"
    "$@" 2>&1 | tee -a "$LOG_FILE" || {
        error "Ошибка: $desc"
        log_to_file "FAILED: $*"
        return 1
    }
}

run_sudo() {
    local desc="$1"
    shift
    if dry_run "[SKIP] $desc: sudo $*"; then
        return 0
    fi
    log_to_file "RUN: sudo $*"
    sudo "$@" 2>&1 | tee -a "$LOG_FILE" || {
        error "Ошибка: $desc"
        log_to_file "FAILED: sudo $*"
        return 1
    }
}

# ---- Manifest ----
manifest_init() {
    mkdir -p "$MANIFEST_DIR"
    cat > "$MANIFEST_FILE" <<EOF
{
  "version": "$KILO_VERSION",
  "installed_at": "$(date -Iseconds)",
  "dry_run": ${INSTALL_DRY_RUN:-0},
  "files": [],
  "configs": {},
  "checksums": {}
}
EOF
}

manifest_add_file() {
    local path="$1"
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        manifest_init
    fi
    local csum=""
    if [[ -f "$path" ]]; then
        csum=$(sha256sum "$path" | cut -d' ' -f1)
    fi
    local tmpf
    tmpf=$(mktemp) || return 1
    python3 -c "
import json, sys
manifest_path, file_path, checksum, tmp_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(manifest_path) as f:
    m = json.load(f)
m['files'].append({'path': file_path, 'checksum': checksum})
with open(tmp_path, 'w') as f:
    json.dump(m, f, indent=2)
" "$MANIFEST_FILE" "$path" "$csum" "$tmpf" 2>/dev/null || true
    mv "$tmpf" "$MANIFEST_FILE"
}

manifest_set_config() {
    local key="$1"
    local val="$2"
    local tmpf
    tmpf=$(mktemp) || return 1
    python3 -c "
import json, sys
manifest_path, tmp_path = sys.argv[1], sys.argv[2]
key, val = sys.argv[3], sys.argv[4]
with open(manifest_path) as f:
    m = json.load(f)
m['configs'][key] = val
with open(tmp_path, 'w') as f:
    json.dump(m, f, indent=2)
" "$MANIFEST_FILE" "$tmpf" "$key" "$val" 2>/dev/null || true
    mv "$tmpf" "$MANIFEST_FILE"
}

# ---- Обработка ошибок ----
cleanup() {
    echo ""
    warn "Установка прервана (сигнал $1)"
    log_to_file "INTERRUPTED: signal $1"
    exit 1
}

error_handler() {
    local line=$1
    local cmd=$2
    local code=$3
    error "Ошибка на строке $line: команда '$cmd' завершилась с кодом $code"
    log_to_file "ERROR: line $line, command '$cmd', exit code $code"
}

trap_install() {
    trap 'cleanup SIGINT' SIGINT SIGTERM
    trap 'error_handler ${LINENO} "$BASH_COMMAND" $?' ERR
}

# ---- Справка ----
show_version() {
    echo "KiloCode CLI Installer v$KILO_VERSION"
}
