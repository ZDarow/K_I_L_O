# Скрипты установщика

---

## Общая библиотека `scripts/lib.sh`

**Размер:** 197 строк  
**Назначение:** Общие функции, используемые всеми скриптами установщика.

### Функции

#### Цвета и логирование

```bash
# Цветовые переменные
RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, NC, BOLD

# Функции логирования
log()      # [✓] — успех
warn()     # [!] — предупреждение
error()    # [✗] — ошибка
header()   # ━━━ заголовок ━━━
subheader()  # → подзаголовок
info()     # INFO: информация
log_to_file() # запись в лог-файл
```

#### Проверки

```bash
check_cmd <cmd>     # Проверка наличия команды (с версией)
require_cmd <cmd>   # Обязательная команда (exit 1 если нет)
```

#### Бэкап

```bash
backup_file <path>      # Создание бэкапа файла/директории
backup_and_copy <src> <dest>  # Бэкап + копирование
```

#### Dry-run

```bash
dry_run <description>   # Проверка режима сухого прогона
run_cmd <desc> <cmd>    # Выполнение команды с логированием
run_sudo <desc> <cmd>   # Выполнение через sudo с логированием
```

#### Manifest (JSON-манифест установки)

```bash
manifest_init                       # Создание manifest.json
manifest_add_file <path>            # Добавление файла с checksum
manifest_set_config <key> <val>     # Установка конфигурации
```

#### Обработка ошибок

```bash
cleanup <signal>        # Очистка при прерывании
error_handler <line> <cmd> <code>  # Обработчик ошибок
trap_install            # Установка trap'ов (SIGINT, SIGTERM, ERR)
```

### Конфигурационные переменные

```bash
KILO_VERSION="1.1.0"
MANIFEST_DIR="$HOME/.local/share/kilo"
MANIFEST_FILE="$MANIFEST_DIR/manifest.json"
BACKUP_DIR="/tmp/kilo-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/kilo-install-$(date +%Y%m%d-%H%M%S).log"
```

---

## Pre-flight (`install.sh --check`)

**Размер:** 150 строк  
**Назначение:** Проверка системы перед установкой.

### Проверки pre-flight

| № | Проверка | Критерий |
|---|----------|----------|
| 1 | ОС | Linux Mint / Ubuntu |
| 2 | sudo | Доступен (с паролем или без) |
| 3 | curl | Наличие инструмента загрузки |
| 4 | Интернет | Доступность GitHub |
| 5 | Свободное место | >500 МБ |
| 6 | Node.js | Установлен (или будет предложена установка 22 LTS) |
| 7 | Git | Установлен (или будет предложена установка) |

### Функции pre-flight

```bash
subheader "ОС"              # Детекция ОС
subheader "sudo"            # Проверка sudo
subheader "Интернет"        # Проверка GitHub
subheader "Node.js"         # Проверка Node.js
subheader "Git"             # Проверка Git
subheader "Диск"            # Проверка дискового пространства
```

**Возврат:** `0` если все проверки пройдены, `1` если есть критические проблемы.

---

## Verify (`install.sh --verify`)

**Размер:** ~70 строк  
**Назначение:** Пост-установочная верификация.

### Проверки verify

| № | Проверка | Что проверяет |
|---|----------|---------------|
| 1 | Конфигурация | ~/.kilo/kilo.jsonc, ~/.config/kilo/kilo.jsonc, AGENTS.md, manifest.json |
| 2 | Node.js | node, npm |
| 3 | KiloCode CLI | `npx kilo --version` |
| 4 | npm-зависимости | node_modules в ~/.kilo/ и ~/.config/kilo/ |
| 5 | Аутентификация | auth.json, наличие API-ключей |
| 6 | SSH | id_ed25519 (опционально) |
| 7 | Manifest | Файлы учтены в manifest.json |

### Функции verify

```bash
check_cmd <cmd>            # Проверка наличия команды
```

**Возврат:** `0` если все проверки пройдены (предупреждения допускаются), `1` при критических ошибках.

---

## Install скрипт `install.sh`

**Размер:** 450 строк  
**Назначение:** Главный установщик.

### Аргументы

```bash
./install.sh                    # Полная установка
./install.sh --dry-run           # Сухой прогон
./install.sh --resume-from=5     # Продолжить с шага 5
./install.sh --skip-preflight    # Без предпроверки
```

### 10 шагов установки

| Шаг | Функция | Описание |
|-----|---------|----------|
| 1 | `detect_os` | Детекция ОС |
| 2 | `install_system_deps` | Node.js 22 LTS, Python 3, git, curl, wget |
| 3 | `install_kilocode` | Запуск `npx kilo --version` / `npm install -g @kilocode/cli` |
| 4 | `create_dirs` | `~/.kilo/`, `~/.config/kilo/`, `~/.local/share/kilo/` |
| 5 | `install_kilo_config` | Копирование `src/kilo-config/` → `~/.kilo/` (с бэкапом) |
| 6 | `install_global_config` | Копирование `src/global-config/` → `~/.config/kilo/` (с бэкапом) |
| 7 | `install_auth` | Шаблон `auth.json` → `~/.local/share/kilo/auth.json` |
| 8 | `install_shell_config` | Дополнения в `.bashrc` + `.profile` |
| 9 | `install_npm_deps` | `npm install` в `~/.kilo/` и `~/.config/kilo/` |
| 10 | `configure_git` | `git config --global init.defaultBranch master` |

### Механизм resume

```bash
# Переменная RESUME_FROM позволяет пропустить выполненные шаги
step() {
    local num="$1"
    if [ "$num" -lt "$RESUME_FROM" ]; then
        echo "[ПРОПУСК] Шаг $num"
        return 0
    fi
    # выполнение шага
}
```

---

## Uninstall (`install.sh --uninstall`)

```bash
./install.sh --uninstall              # Полное удаление (с подтверждением)
./install.sh --uninstall --dry-run    # Просмотр что будет удалено
```

### Что удаляется

| Компонент | Путь |
|-----------|------|
| Проектная конфигурация | `~/.kilo/` |
| Глобальная конфигурация | `~/.config/kilo/` |
| Аутентификация | `~/.local/share/kilo/auth.json` |
| Манифест | `~/.local/share/kilo/manifest.json` |
| Shell-блоки | Из `.bashrc` и `.profile` (блоки KiloCode CLI) |

### Восстановление shell-конфигов

```bash
# 1. Ищет бэкап в BACKUP_DIR
# 2. Если бэкапа нет — удаляет блок KiloCode через sed
# 3. Если есть бэкап — восстанавливает файл из бэкапа
```
