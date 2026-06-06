#!/usr/bin/env bash
# ============================================
# KiloCode CLI — Uninstall
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib.sh"

# Восстанавливаем BACKUP_DIR из манифеста установки (если есть)
if [ -f "$MANIFEST_FILE" ]; then
    saved_backup=$(python3 -c "
import json, sys
try:
    with open('$MANIFEST_FILE') as f:
        m = json.load(f)
    print(m.get('configs', {}).get('backup_dir', ''))
except:
    pass
" 2>/dev/null || true)
    if [ -n "$saved_backup" ] && [ -d "$saved_backup" ]; then
        BACKUP_DIR="$saved_backup"
    fi
fi

# Сухой прогон
if [ "${1:-}" = "--dry-run" ]; then
    INSTALL_DRY_RUN=1
fi

echo -e "${RED}"
echo "╔══════════════════════════════════════════╗"
echo "║  KiloCode CLI — Деинсталляция            ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

if [ "${INSTALL_DRY_RUN:-0}" != "1" ]; then
    echo -e "${YELLOW}ВНИМАНИЕ: Будут удалены все файлы KiloCode и BLE-проект.${NC}"
    echo -e "${YELLOW}Бэкапы изменённых файлов сохранены в: $BACKUP_DIR${NC}"
    echo ""
    read -rp "Продолжить? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Отменено."
        exit 0
    fi
fi

header "Удаление конфигурации Kilo"

# Определяем что удалять
DIRS_TO_REMOVE=(
    "$HOME/.kilo"
    "$HOME/.config/kilo"
)

FILES_TO_REMOVE=(
    "$HOME/.local/share/kilo/auth.json"
    "$HOME/.local/share/kilo/manifest.json"
)

for dir in "${DIRS_TO_REMOVE[@]}"; do
    if [ -d "$dir" ]; then
        if dry_run "rm -rf $dir"; then
            continue
        fi
        rm -rf "$dir"
        log "Удалено: $dir"
    else
        info "Не найдено: $dir"
    fi
done

for file in "${FILES_TO_REMOVE[@]}"; do
    if [ -f "$file" ]; then
        if dry_run "rm -f $file"; then
            continue
        fi
        rm -f "$file"
        log "Удалено: $file"
    else
        info "Не найдено: $file"
    fi
done

header "Удаление BLE-проекта"

if [ -d "$HOME/ble-project" ]; then
    if dry_run "rm -rf $HOME/ble-project"; then
        :
    else
        rm -rf "$HOME/ble-project"
        log "Удалено: ~/ble-project"
    fi
else
    info "Не найдено: ~/ble-project"
fi

header "Восстановление shell-конфигурации"

restore_shell_file() {
    local path="$1"
    local label="$2"
    if [ ! -f "$path" ]; then
        info "Не найдено: $path"
        return
    fi

    local bak
    # Ищем бэкап в директории бэкапов
    bak="$BACKUP_DIR/$(echo "$path" | sed "s|^$HOME/||")"
    if [ ! -f "$bak" ]; then
        # Если бэкапа нет — просто удаляем блок KiloCode
        if dry_run "sed -i '/# ---- KiloCode CLI/,/^# ----/d' $path"; then
            return
        fi
        if grep -q "KiloCode CLI" "$path" 2>/dev/null; then
            sed -i '/# ============.*KiloCode/,/# ============/d' "$path"
            # Убираем лишние пустые строки
            sed -i '/^$/N;/^\n$/D' "$path" 2>/dev/null || true
            log "Блок KiloCode удалён из $label"
        else
            info "Блок KiloCode не найден в $label"
        fi
    else
        # Восстанавливаем из бэкапа
        if dry_run "cp $bak $path"; then
            return
        fi
        cp "$bak" "$path"
        log "Восстановлен из бэкапа: $label"
    fi
}

restore_shell_file "$HOME/.bashrc" .bashrc
restore_shell_file "$HOME/.profile" .profile

header "Проверка после удаления"

# Проверяем, что всё удалено
MISSED=0
for dir in "${DIRS_TO_REMOVE[@]}"; do
    if [ -d "$dir" ]; then
        warn "Не удалось удалить: $dir"
        MISSED=$((MISSED + 1))
    fi
done

if [ "$MISSED" -eq 0 ]; then
    log "Деинсталляция завершена"
else
    warn "Деинсталляция завершена с $MISSED ошибками"
fi

echo ""
if [ "${INSTALL_DRY_RUN:-0}" = "1" ]; then
    echo -e "  ${YELLOW}Это был сухой прогон. Ничего не удалено.${NC}"
else
    echo -e "  ${GREEN}Для повторной установки: ./install.sh${NC}"
fi
