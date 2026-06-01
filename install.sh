#!/usr/bin/env bash
set -euo pipefail

# ============================================
# KiloCode CLI — Установщик для Linux Mint
# Репозиторий: https://github.com/ZDarow/K_I_L_O
# ============================================

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Директория скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"

# Лог-файл
LOG_FILE="/tmp/kilo-install-$(date +%Y%m%d-%H%M%S).log"

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✗]${NC} $1"; }
header() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }

# Проверка успешности шага
check_cmd() {
    if command -v "$1" &>/dev/null; then
        log "$1 установлен: $($1 --version 2>&1 | head -1)"
        return 0
    else
        warn "$1 не найден"
        return 1
    fi
}

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║  KiloCode CLI — Установщик для Linux Mint ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo "Лог: $LOG_FILE"
echo ""

# ─── Шаг 1: Детекция ОС ───────────────────────────────
header "Детекция системы"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "  ОС: $NAME $VERSION_ID"
    echo "  Архитектура: $(uname -m)"
else
    warn "Не удалось определить ОС"
fi

# ─── Шаг 2: Установка системных зависимостей ──────────
header "Установка системных зависимостей"

sudo apt-get update -qq 2>&1 | tee -a "$LOG_FILE"

# Node.js (через NodeSource)
if ! command -v node &>/dev/null; then
    warn "Node.js не найден. Устанавливаю Node.js 22 LTS..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 2>&1 | tee -a "$LOG_FILE"
    sudo apt-get install -y nodejs 2>&1 | tee -a "$LOG_FILE"
    log "Node.js $(node --version) установлен"
else
    log "Node.js $(node --version)"
fi

# Python и инструменты
sudo apt-get install -y -qq \
    python3 python3-pip python3-venv python3-dev \
    git curl wget build-essential \
    bluez bluez-tools bluez-hcidump \
    tshark cmake \
    libglib2.0-dev \
    2>&1 | tee -a "$LOG_FILE"
log "Системные пакеты установлены"

# ─── Шаг 3: Установка KiloCode CLI ─────────────────────
header "Установка KiloCode CLI"

if command -v npx &>/dev/null; then
    # Проверяем, доступен ли kilo
    if npx --yes kilo --version &>/dev/null 2>&1; then
        log "KiloCode CLI уже доступен"
    else
        warn "Устанавливаю KiloCode CLI через npm..."
        npm install -g @kilocode/cli 2>&1 | tail -5 | tee -a "$LOG_FILE" || true
    fi
else
    warn "npx не найден. Установка KiloCode CLI отложена."
fi

# ─── Шаг 4: Создание структуры директорий ──────────────
header "Создание структуры директорий"

mkdir -p "$HOME/.kilo"
mkdir -p "$HOME/.config/kilo"
mkdir -p "$HOME/.local/share/kilo"
mkdir -p "$HOME/.ssh"
mkdir -p "$HOME/.npm"
mkdir -p "$HOME/ble-project"
log "Директории созданы"

# ─── Шаг 5: Копирование конфигурации Kilo (проектная) ─
header "Установка проектной конфигурации Kilo (~/.kilo/)"

if [ -d "$SRC_DIR/dot-kilo" ]; then
    cp -r "$SRC_DIR/dot-kilo/"* "$HOME/.kilo/"
    log "Конфигурация ~/.kilo/ установлена ($(find "$HOME/.kilo" -type f | wc -l) файлов)"
else
    warn "Источник src/dot-kilo/ не найден, пропускаю"
fi

# ─── Шаг 6: Копирование глобальной конфигурации Kilo ──
header "Установка глобальной конфигурации Kilo (~/.config/kilo/)"

if [ -d "$SRC_DIR/dot-config-kilo" ]; then
    cp -r "$SRC_DIR/dot-config-kilo/"* "$HOME/.config/kilo/"
    log "Конфигурация ~/.config/kilo/ установлена ($(find "$HOME/.config/kilo" -type f | wc -l) файлов)"
else
    warn "Источник src/dot-config-kilo/ не найден, пропускаю"
fi

# ─── Шаг 7: Установка шаблона auth.json ──────────────
header "Настройка аутентификации"

if [ -f "$SRC_DIR/dot-local-share-kilo/auth.template.json" ]; then
    if [ ! -f "$HOME/.local/share/kilo/auth.json" ]; then
        cp "$SRC_DIR/dot-local-share-kilo/auth.template.json" "$HOME/.local/share/kilo/auth.json"
        warn "Шаблон auth.json установлен. Замени API-ключ в ~/.local/share/kilo/auth.json"
    else
        log "auth.json уже существует, пропускаю"
    fi
fi

# ─── Шаг 8: Настройка SSH ─────────────────────────────
header "Настройка SSH"

if [ -d "$SRC_DIR/dot-ssh" ]; then
    # SSH config
    if [ -f "$SRC_DIR/dot-ssh/config" ] && [ ! -f "$HOME/.ssh/config" ]; then
        cp "$SRC_DIR/dot-ssh/config" "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
        log "SSH config установлен"
    fi

    # Публичный ключ
    if [ -f "$SRC_DIR/dot-ssh/id_ed25519.pub" ] && [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
        cp "$SRC_DIR/dot-ssh/id_ed25519.pub" "$HOME/.ssh/id_ed25519.pub"
        chmod 644 "$HOME/.ssh/id_ed25519.pub"
        log "SSH публичный ключ установлен"
        warn "Приватный ключ (~/.ssh/id_ed25519) нужно скопировать вручную!"
    fi

    chmod 700 "$HOME/.ssh" 2>/dev/null || true
fi

# ─── Шаг 9: Обновление .bashrc и .profile ─────────────
header "Обновление shell-конфигурации"

# .bashrc
BASHRC_APPEND="$SRC_DIR/bashrc-append.sh"
if [ -f "$BASHRC_APPEND" ]; then
    if ! grep -q "KiloCode CLI" "$HOME/.bashrc" 2>/dev/null; then
        cat "$BASHRC_APPEND" >> "$HOME/.bashrc"
        log "Дополнения добавлены в ~/.bashrc"
    else
        log "~/.bashrc уже содержит дополнения KiloCode"
    fi
fi

# .profile
PROFILE_APPEND="$SRC_DIR/profile-append.sh"
if [ -f "$PROFILE_APPEND" ]; then
    if ! grep -q "KiloCode CLI" "$HOME/.profile" 2>/dev/null; then
        cat "$PROFILE_APPEND" >> "$HOME/.profile"
        log "Дополнения добавлены в ~/.profile"
    else
        log "~/.profile уже содержит дополнения KiloCode"
    fi
fi

# ─── Шаг 10: Установка BLE-проекта ────────────────────
header "Настройка BLE Engineering проекта"

if [ -d "$SCRIPT_DIR/ble-project" ]; then
    # Копируем всё кроме .venv
    rsync -a --exclude='.venv' "$SCRIPT_DIR/ble-project/" "$HOME/ble-project/" 2>/dev/null || \
    cp -r "$SCRIPT_DIR/ble-project/"* "$HOME/ble-project/" 2>/dev/null || true
    log "BLE-проект установлен"
fi

# Создаём пустые поддиректории BLE
mkdir -p "$HOME/ble-project"/{logs,gatt,protocol,firmware,android,bluez,docs}

# ─── Шаг 11: Установка зависимостей Kilo npm ──────────
header "Установка npm-зависимостей Kilo"

if [ -f "$HOME/.kilo/package.json" ]; then
    cd "$HOME/.kilo" && npm install 2>&1 | tail -3 | tee -a "$LOG_FILE"
    log "npm-зависимости ~/.kilo/ установлены"
fi

if [ -f "$HOME/.config/kilo/package.json" ]; then
    cd "$HOME/.config/kilo" && npm install 2>&1 | tail -3 | tee -a "$LOG_FILE"
    log "npm-зависимости ~/.config/kilo/ установлены"
fi

# ─── Шаг 12: Настройка Git ────────────────────────────
header "Настройка Git"

git config --global user.name "ZDarow" 2>/dev/null || true
git config --global user.email "zdarow@github.com" 2>/dev/null || true
git config --global init.defaultBranch master
log "Git глобальная конфигурация установлена"

# ─── Шаг 13: Проверки ─────────────────────────────────
header "Проверка установки"

echo ""
echo -e "  ${GREEN}KiloCode CLI — проверка:${NC}"
check_cmd node
check_cmd npm
check_cmd npx
check_cmd git
check_cmd python3 || true
check_cmd bluetoothctl || true

echo ""
echo -e "  ${GREEN}Конфигурационные файлы:${NC}"
for f in "$HOME/.kilo/kilo.jsonc" "$HOME/.config/kilo/kilo.jsonc" "$HOME/.config/kilo/AGENTS.md" "$HOME/AGENTS.md"; do
    if [ -f "$f" ]; then
        log "  $f"
    else
        warn "  $f — не найден"
    fi
done

# ─── Завершение ───────────────────────────────────────
header "Установка завершена"

echo ""
echo -e "  ${GREEN}Дальнейшие шаги:${NC}"
echo "  1. Активируй окружение: source ~/.bashrc"
echo "  2. Настрой API-ключ:  nano ~/.local/share/kilo/auth.json"
echo "  3. Копируй SSH-ключи: ~/.ssh/id_ed25519 (приватный)"
echo "  4. Запусти Kilo:      npx kilo"
echo "  5. BLE-окружение:     cd ~/ble-project && source scripts/activate.sh"
echo ""
echo -e "  Лог установки: ${YELLOW}$LOG_FILE${NC}"
echo ""
