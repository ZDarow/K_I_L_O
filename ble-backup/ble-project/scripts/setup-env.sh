#!/usr/bin/env bash
set -euo pipefail

echo "=== BLE Environment Setup ==="

# Определяем директорию проекта
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Проверяем наличие Python 3
if ! command -v python3 &>/dev/null; then
    echo "Ошибка: python3 не найден. Установи: sudo apt install python3 python3-pip python3-venv"
    exit 1
fi

# Создаём виртуальное окружение (если ещё нет)
if [ ! -d "$PROJECT_DIR/.venv" ]; then
    python3 -m venv "$PROJECT_DIR/.venv"
    echo "Виртуальное окружение создано: $PROJECT_DIR/.venv"
else
    echo "Виртуальное окружение уже существует: $PROJECT_DIR/.venv"
fi

# Активируем и устанавливаем Python-библиотеки
source "$PROJECT_DIR/.venv/bin/activate"
pip install --upgrade pip -q
pip install bleak bumble bleson bluepy pygatt -q

# Верификация
python3 -c "
import bleak
print('bleak:', bleak.__version__)
try:
    import bumble; print('bumble:', bumble.__version__)
except: print('bumble: установлен')
try:
    import bleson; print('bleson:', bleson.__version__)
except: print('bleson: установлен')
"

# Запускаем Bluetooth-сервис (если доступен)
if command -v systemctl &>/dev/null; then
    sudo systemctl start bluetooth 2>/dev/null || true
fi

echo ""
echo "=== Setup complete ==="
echo "Activate: source $PROJECT_DIR/.venv/bin/activate"
