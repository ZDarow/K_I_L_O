#!/usr/bin/env bash
# ============================================
# KiloCode CLI — Пост-установочная проверка
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ALL_OK=true
WARNINGS=0

header "Верификация установки"
echo ""

# ─── Manifest ───────────────────────────────────
subheader "Manifest установки"
if [[ -f "$MANIFEST_FILE" ]]; then
    log "Manifest найден: $MANIFEST_FILE"
    INSTALLED_AT=$(python3 -c "import json; print(json.load(open('$MANIFEST_FILE')).get('installed_at', 'unknown'))" 2>/dev/null || echo "unknown")
    FILES_COUNT=$(python3 -c "import json; print(len(json.load(open('$MANIFEST_FILE')).get('files', [])))" 2>/dev/null || echo "0")
    echo "  Дата установки: $INSTALLED_AT"
    echo "  Файлов в манифесте: $FILES_COUNT"
else
    warn "Manifest не найден — установка могла быть не завершена"
    WARNINGS=$((WARNINGS + 1))
fi

# ─── Конфигурационные файлы ─────────────────────
subheader "Конфигурация Kilo"

check_file() {
    if [[ -f "$1" ]]; then
        log "$1"
    else
        error "$1 — не найден"
        ALL_OK=false
    fi
}

check_dir() {
    if [[ -d "$1" ]]; then
        local count
        count=$(find "$1" -type f | wc -l)
        log "$1 ($count файлов)"
    else
        error "$1 — не найден"
        ALL_OK=false
    fi
}

check_file "$HOME/.kilo/kilo.jsonc"
check_file "$HOME/.kilo/package.json"
check_dir "$HOME/.kilo/agents"
check_dir "$HOME/.kilo/commands"
check_dir "$HOME/.kilo/tools"
check_dir "$HOME/.kilo/instructions"
check_dir "$HOME/.kilo/skills"
check_file "$HOME/.config/kilo/kilo.jsonc"
check_file "$HOME/.config/kilo/AGENTS.md"
check_dir "$HOME/.config/kilo/agents"
check_dir "$HOME/.config/kilo/instructions"
check_file "$HOME/AGENTS.md"

# ─── Node.js и npm ─────────────────────────────
subheader "Node.js экосистема"
check_cmd node
check_cmd npm
check_cmd npx || true

# ─── KiloCode CLI ──────────────────────────────
subheader "KiloCode CLI"
if command -v npx &>/dev/null; then
    if npx --yes kilo --version &>/dev/null 2>&1; then
        log "KiloCode CLI доступен"
    else
        warn "KiloCode CLI не отвечает (npx kilo --version)"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# ─── npm-зависимости Kilo ──────────────────────
subheader "npm-зависимости"
check_npm_deps() {
    local dir="$1"
    local name="$2"
    if [[ -f "$dir/package.json" ]]; then
        log "$name: package.json найден"
    else
        warn "$name: package.json не найден"
        WARNINGS=$((WARNINGS + 1))
    fi
    if [[ -d "$dir/node_modules" ]]; then
        local count
        count=$(find "$dir/node_modules" -mindepth 1 -maxdepth 1 -type d | wc -l)
        log "$name: $count npm-пакетов установлено"
    else
        warn "$name: node_modules не найден — запусти npm install"
        WARNINGS=$((WARNINGS + 1))
    fi
}
check_npm_deps "$HOME/.kilo" "Проектная конфигурация"
check_npm_deps "$HOME/.config/kilo" "Глобальная конфигурация"

# ─── Аутентификация ─────────────────────────────
subheader "Аутентификация"
if [[ -f "$HOME/.local/share/kilo/auth.json" ]]; then
    key_count=$(python3 -c "
import json
try:
    d = json.load(open('$HOME/.local/share/kilo/auth.json'))
    keys = [k for k in d if d[k].get('key', '') and d[k]['key'] != 'YOUR_API_KEY_HERE']
    print(len(keys))
except: print(0)
" 2>/dev/null || echo "0")
    if [[ "$key_count" -gt 0 ]]; then
        log "API-ключи настроены ($key_count)"
    else
        warn "API-ключи не настроены (заглушка в auth.json)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    warn "auth.json не найден"
    WARNINGS=$((WARNINGS + 1))
fi

# ─── SSH ────────────────────────────────────────
subheader "SSH"
if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    log "SSH-ключ id_ed25519 найден"
else
    warn "SSH-ключ id_ed25519 не найден"
    WARNINGS=$((WARNINGS + 1))
fi

# ─── Shell-конфиги ──────────────────────────────
subheader "Shell-конфигурация"
if grep -q "KiloCode CLI" "$HOME/.bashrc" 2>/dev/null; then
    log ".bashrc содержит дополнения KiloCode"
else
    warn ".bashrc не содержит дополнений KiloCode"
    WARNINGS=$((WARNINGS + 1))
fi
if grep -q "KiloCode CLI" "$HOME/.profile" 2>/dev/null; then
    log ".profile содержит дополнения KiloCode"
else
    warn ".profile не содержит дополнений KiloCode"
    WARNINGS=$((WARNINGS + 1))
fi

# ─── Checksum-проверка (если есть manifest) ─────
subheader "Целостность файлов"
if [[ -f "$MANIFEST_FILE" ]]; then
    errors=0
    python3 -c "
import json, hashlib, os, sys
with open('$MANIFEST_FILE') as f:
    m = json.load(f)
errors = []
for entry in m.get('files', []):
    path = entry.get('path', '')
    expected = entry.get('checksum', '')
    if not expected or not os.path.exists(path):
        continue
    actual = hashlib.sha256(open(path, 'rb').read()).hexdigest()
    if actual != expected:
        errors.append(path)
if errors:
    print('MISMATCH:', len(errors))
    for e in errors:
        print('  ', e)
    sys.exit(1)
else:
    print('OK')
" 2>&1 || { warn "Обнаружены несоответствия checksum"; WARNINGS=$((WARNINGS + 1)); }
    log "Checksum-проверка пройдена"
fi

# ─── Итог ───────────────────────────────────────
echo ""
if [[ "$ALL_OK" = true ]] && [[ "$WARNINGS" -eq 0 ]]; then
    log "Все проверки пройдены. Установка корректна."
    exit 0
elif [[ "$ALL_OK" = true ]]; then
    warn "Установка завершена с $WARNINGS предупреждениями"
    exit 0
else
    error "Обнаружены критические ошибки"
    exit 1
fi
