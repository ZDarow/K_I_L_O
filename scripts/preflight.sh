#!/usr/bin/env bash
# ============================================
# KiloCode CLI — Pre-flight проверка системы
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ALL_OK=true

header "Pre-flight проверка системы"
echo ""

# ─── ОС ────────────────────────────────────────
subheader "Операционная система"
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "  ОС: $NAME $VERSION_ID"
    echo "  Архитектура: $(uname -m)"
    
    # Проверяем Linux Mint или Ubuntu
    case "$ID" in
        linuxmint|ubuntu)
            # Версия должна быть 21+ для Mint или 22.04+ для Ubuntu
            MAJOR_VER=$(echo "$VERSION_ID" | cut -d. -f1)
            if [[ "$ID" = "linuxmint" ]] && [[ "$MAJOR_VER" -lt 21 ]]; then
                warn "Linux Mint < 21 может иметь несовместимые пакеты"
            fi
            if [[ "$ID" = "ubuntu" ]] && [[ "$MAJOR_VER" -lt 22 ]]; then
                warn "Ubuntu < 22.04 может иметь устаревшие пакеты"
            fi
            log "ОС поддерживается"
            ;;
        *)
            warn "ОС не тестировалась: $ID. Возможны проблемы совместимости."
            ;;
    esac
else
    warn "Не удалось определить ОС"
fi

# ─── Права sudo ─────────────────────────────────
subheader "Права sudo"
if command -v sudo &>/dev/null; then
    if sudo -n true 2>/dev/null; then
        log "sudo доступен (без пароля)"
    else
        warn "sudo требует пароль — установка запросит его"
    fi
else
    error "sudo не установлен"
    ALL_OK=false
fi

# ─── curl/wget ──────────────────────────────────
subheader "Инструменты загрузки"
if command -v curl &>/dev/null; then
    log "curl доступен"
else
    warn "curl не найден — будет установлен (требуется для NodeSource)"
fi

# ─── Интернет ───────────────────────────────────
subheader "Подключение к интернету"
if command -v curl &>/dev/null; then
    if curl -s --max-time 5 https://github.com >/dev/null 2>&1; then
        log "GitHub доступен"
    else
        warn "GitHub недоступен — установка npm-пакетов может не сработать"
    fi
    if curl -s --max-time 5 https://deb.nodesource.com >/dev/null 2>&1; then
        log "NodeSource доступен"
    else
        warn "NodeSource недоступен — установка Node.js может не сработать"
    fi
else
    warn "curl не найден, проверка интернета пропущена"
fi

# ─── Диск ───────────────────────────────────────
subheader "Свободное место"
if command -v df &>/dev/null; then
    AVAIL_KB=$(df "$HOME" | awk 'NR==2 {print $4}')
    AVAIL_MB=$((AVAIL_KB / 1024))
    if [[ "$AVAIL_MB" -lt 500 ]]; then
        error "Меньше 500 МБ свободно: ${AVAIL_MB}МБ. Установка может не завершиться."
        ALL_OK=false
    elif [[ "$AVAIL_MB" -lt 1000 ]]; then
        warn "Меньше 1 ГБ свободно: ${AVAIL_MB}МБ"
    else
        log "Свободно: ${AVAIL_MB}МБ"
    fi
fi

# ─── Node.js ────────────────────────────────────
subheader "Node.js"
if command -v node &>/dev/null; then
    NODE_VER=$(node --version | sed 's/v//')
    NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1)
    if [[ "$NODE_MAJOR" -lt 18 ]]; then
        warn "Node.js $NODE_VER устарел. Рекомендуется 18+"
    else
        log "Node.js $NODE_VER"
    fi
else
    warn "Node.js не установлен — будет установлен Node.js 22 LTS"
fi

# ─── Git ────────────────────────────────────────
subheader "Git"
if command -v git &>/dev/null; then
    log "Git $(git --version | cut -d' ' -f3)"
else
    warn "Git не установлен — будет установлен"
fi

# ─── Конфликты ──────────────────────────────────
subheader "Проверка конфликтов"
if [[ -f "$HOME/.kilo/kilo.jsonc" ]]; then
    warn "Уже существует ~/.kilo/kilo.jsonc — будет перезаписан (создан бэкап)"
fi

# ─── Python ─────────────────────────────────────
subheader "Python"
if command -v python3 &>/dev/null; then
    PY_VER=$(python3 --version 2>&1 | cut -d' ' -f2)
    PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
    PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
    if [[ "$PY_MAJOR" -lt 3 ]] || { [[ "$PY_MAJOR" -eq 3 ]] && [[ "$PY_MINOR" -lt 10 ]]; }; then
        warn "Python $PY_VER устарел. Рекомендуется 3.10+"
    else
        log "Python $PY_VER"
    fi
else
    warn "Python 3 не установлен — будет установлен"
fi

# ─── Итог ───────────────────────────────────────
echo ""
if [[ "$ALL_OK" = true ]]; then
    log "Все проверки пройдены"
    exit 0
else
    error "Обнаружены критические проблемы. Исправьте их перед установкой."
    exit 1
fi
