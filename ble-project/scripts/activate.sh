#!/usr/bin/env bash
# Активация окружения BLE Engineering
# Использование: source ./scripts/activate.sh

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ ! -f "$DIR/.venv/bin/activate" ]; then
    echo "Ошибка: .venv не найден. Выполни: python3 -m venv $DIR/.venv"
    return 1
fi

source "$DIR/.venv/bin/activate"
echo "BLE Engineering env activated (Python $(python --version 2>/dev/null | cut -d' ' -f2))"
echo "Для деактивации: deactivate"
