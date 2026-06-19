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

## Pre-flight скрипт `scripts/preflight.sh`

**Размер:** 150 строк  
**Назначение:** Проверка системы перед установкой.

### Проверки

| № | Проверка | Критерий |
|---|----------|----------|
| 1 | ОС | Linux Mint 21+ / Ubuntu 22.04+ |
| 2 | sudo | Доступен (с паролем или без) |
| 3 | curl/wget | Наличие инструментов загрузки |
| 4 | Интернет | Доступность GitHub и NodeSource |
| 5 | Свободное место | >500 МБ (критично), >1 ГБ (рекомендуется) |
| 6 | Node.js | Версия 18+ (или будет установлен 22 LTS) |
| 7 | Git | Наличие (или будет установлен) |
| 8 | Конфликты | Проверка существующих ~/.kilo/ |
| 9 | Python | Версия 3.10+ (или будет установлен) |

### Функции

```bash
subheader "Операционная система"     # Детекция и проверка ОС
subheader "Права sudo"               # Проверка sudo
subheader "Инструменты загрузки"      # Проверка curl/wget
subheader "Подключение к интернету"   # Проверка GitHub, NodeSource
subheader "Свободное место"          # Проверка дискового пространства
subheader "Node.js"                  # Проверка Node.js
subheader "Git"                      # Проверка Git
subheader "Проверка конфликтов"      # Проверка существующих установок
subheader "Python"                   # Проверка Python
```

**Возврат:** `0` если все проверки пройдены, `1` если есть критические проблемы.

---

## Verify скрипт `scripts/verify.sh`

**Размер:** 205 строк  
**Назначение:** Пост-установочная верификация.

### Проверки

| № | Проверка | Что проверяет |
|---|----------|---------------|
| 1 | Manifest | Наличие manifest.json, дата, количество файлов |
| 2 | Конфигурация Kilo | ~/.kilo/kilo.jsonc, package.json, agents/, commands/, tools/, instructions/, skills/ |
| 3 | Глобальная конфигурация | ~/.config/kilo/kilo.jsonc, AGENTS.md, agents/, instructions/ |
| 4 | Корневой AGENTS.md | ~/AGENTS.md |
| 5 | Node.js | node, npm, npx |
| 6 | KiloCode CLI | `npx kilo --version` |
| 7 | npm-зависимости | package.json + node_modules в ~/.kilo/ и ~/.config/kilo/ |
| 8 | Аутентификация | auth.json, API-ключи |
| 9 | SSH | id_ed25519 ключ |
| 10 | Shell-конфиги | .bashrc, .profile — дополнения KiloCode |
| 11 | Целостность | SHA256 checksum-проверка по manifest.json |

### Функции

```bash
check_file <path>          # Проверка существования файла
check_dir <path>           # Проверка существования директории + подсчёт файлов
check_cmd <cmd>            # Проверка наличия команды
check_npm_deps <dir> <name> # Проверка npm-зависимостей
```

**Возврат:** `0` если все проверки пройдены (предупреждения допускаются), `1` при критических ошибках.

---

## Install скрипт `install.sh`

**Размер:** 473 строки  
**Назначение:** Главный установщик.

### Аргументы

```bash
./install.sh                    # Полная установка
./install.sh --dry-run           # Сухой прогон
./install.sh --resume-from=5     # Продолжить с шага 5
./install.sh --skip-preflight    # Без предпроверки
```

### 12 шагов установки

| Шаг | Функция | Описание |
|-----|---------|----------|
| 1 | `detect_os` | Детекция ОС (Linux Mint / Ubuntu) |
| 2 | `install_system_deps` | Node.js 22 LTS, Python 3, cmake |
| 3 | `install_kilocode` | `npm install -g @kilocode/cli` |
| 4 | `create_dirs` | `~/.kilo/`, `~/.config/kilo/`, `~/.ssh/` |
| 5 | `install_dot_kilo` | Копирование `src/dot-kilo/` → `~/.kilo/` (с бэкапом) |
| 6 | `install_dot_config_kilo` | Копирование `src/dot-config-kilo/` → `~/.config/kilo/` (с бэкапом) |
| 7 | `install_auth` | Шаблон `auth.json` → `~/.local/share/kilo/auth.json` |
| 8 | `install_ssh` | SSH config + публичный ключ |
| 9 | `install_shell_config` | Дополнения в `.bashrc` + `.profile` |
| 10 | `install_npm_deps` | `npm install` в `~/.kilo/` и `~/.config/kilo/` |
| 11 | `configure_git` | `git config --global init.defaultBranch master` |
| 12 | `verify_installation` | Финальная проверка |

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

## Uninstall скрипт `uninstall.sh`

**Размер:** 160 строк  
**Назначение:** Полное удаление KiloCode.

### Аргументы

```bash
./uninstall.sh              # Полное удаление (с подтверждением)
./uninstall.sh --dry-run    # Просмотр что будет удалено
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
restore_shell_file <path> <label>
# 1. Ищет бэкап в BACKUP_DIR
# 2. Если бэкапа нет — удаляет блок KiloCode через sed
# 3. Если есть бэкап — восстанавливает файл из бэкапа
```
