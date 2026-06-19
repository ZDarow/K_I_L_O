# K_I_L_O — Установщик экосистемы Kilo AI CLI

**Репозиторий:** [https://github.com/ZDarow/K_I_L_O](https://github.com/ZDarow/K_I_L_O)

Полная конфигурация AI-агента **Kilo** для Linux Mint / Ubuntu: русскоязычные правила,
системные настройки, CI/CD, тестирование и автоматизация.

---

## Возможности

- **Установка Kilo CLI** — AI-агент для командной строки
- **9 предустановленных агентов** — dev, git-specialist, debugger, doc-scribe, log-analyzer, planner, reviewer, sys-inspector и другие
- **9 команд быстрого доступа** — сборка Flutter, управление Git, ревью кода, планирование
- **Двухуровневая конфигурация** — проектная + глобальная с иерархией приоритетов
- **SSH + Git** — преднастроенная конфигурация для GitHub/GitLab
- **Система бэкапов и манифестов** — отслеживание всех установленных файлов

---

## Быстрая установка

```bash
git clone https://github.com/ZDarow/K_I_L_O.git /tmp/kilo-install
cd /tmp/kilo-install

make check     # Pre-flight проверка системы
make install   # Установка
make verify    # Проверка целостности
```

Единая команда (с pre-flight):
```bash
make install
```

После установки:
```bash
source ~/.bashrc
```

---

## Требования к системе

| Компонент | Требование |
|-----------|-----------|
| **ОС** | Linux Mint 21.x / 22.x или Ubuntu 22.04+ |
| **Права** | sudo (с паролем или без) |
| **Интернет** | Для загрузки зависимостей |
| **Диск** | ≥500 МБ свободно (рекомендуется ≥1 ГБ) |

---

## Makefile — точки входа

| Команда | Действие |
|---------|----------|
| `make check` | Pre-flight: ОС, sudo, диск, интернет, Node.js |
| `make install` | Полная установка (с предпроверкой) |
| `make verify` | Пост-проверка: файлы, checksums, команды |
| `make dry-run` | Сухой прогон — что будет сделано |
| `make uninstall` | Полное удаление всех компонентов |
| `make backup` | Бэкап текущих конфигов в `/tmp/` |
| `make clean` | Очистка логов установки |
| `make help` | Справка по целям |

Установщик также поддерживает флаги:
- `./install.sh --dry-run` — просмотр без изменений
- `./install.sh --resume-from=5` — продолжить с шага 5
- `./install.sh --skip-preflight` — без предпроверки

---

## Что устанавливается

### 1. Kilo CLI + Проектная конфигурация (`~/.kilo/`)
- `@kilocode/cli` (глобально через npm)
- 9 агентов (dev, git-specialist, debugger, doc-scribe, log-analyzer, planner, reviewer, sys-inspector и др.)
- 9 команд (flutter-build, git-*, plan, review, test, debug)
- Инструкции на русском

### 2. Глобальная конфигурация (`~/.config/kilo/`)
- AGENTS.md — правила высшего приоритета для всех сессий Kilo
- Агент `russian-dev`
- TUI-конфигурация

### 3. Системные компоненты
- Node.js 22 LTS (через NodeSource)
- Python 3.12+, pip, venv
- build-essential, curl, wget, git

### 4. Системные настройки
- SSH-конфигурация (GitHub, GitLab)
- Git config: user.name, user.email, init.defaultBranch
- PATH в `.profile`

---

## Структура репозитория

```text
K_I_L_O/
│
├── Makefile              # Точка входа: install, check, verify, uninstall
├── install.sh            # Главный установщик (12 шагов, resume, dry-run)
├── uninstall.sh          # Полный откат с восстановлением бэкапов
│
├── scripts/              # Скрипты автоматизации
│   ├── lib.sh            #   Общая библиотека (цвета, backup, manifest)
│   ├── preflight.sh      #   Pre-flight проверка системы
│   └── verify.sh         #   Пост-установочная валидация
│
├── src/                  # Исходники для установки на новую систему
│   ├── kilo-config/      #   → ~/.kilo/ (проектная конфигурация)
│   ├── global-config/    #   → ~/.config/kilo/
│   ├── local-share/      #   → ~/.local/share/kilo/
│   ├── ssh/              #   → ~/.ssh/
│   ├── bashrc-append.sh  #   → ~/.bashrc
│   └── profile-append.sh #   → ~/.profile
│
├── .kilo/                # Dev-конфигурация Kilo для разработки
├── ble-backup/           # Резервная копия BLE-компонентов
│
├── docs/                 # Документация
│   ├── ARCHITECTURE.md   #   Архитектура проекта
│   ├── AGENTS.md         #   Каталог агентов
│   ├── COMMANDS.md       #   Каталог команд
│   ├── CONFIGURATION.md  #   Конфигурация
│   ├── SCRIPTS.md        #   Скрипты установщика
│   ├── DEVELOPMENT.md    #   Инструкция для разработчиков
│   ├── GUIDE.md          #   Полное руководство пользователя
│   └── TROUBLESHOOTING.md # Устранение проблем
│
├── AGENTS.md             # Правила для Kilo-сессий
├── LICENSE               # MIT License
├── .gitignore
└── README.md
```

---

## Агенты Kilo

| Агент | Тип | Описание |
|-------|-----|----------|
| `dev` | primary | Универсальный — Linux, CI/CD, автоматизация, общее ПО |
| `git-specialist` | primary | Управление репозиториями, CI/CD |
| `debugger` | subagent | Анализ ошибок, стектрейсов, root cause |
| `doc-scribe` | subagent | Технический писатель: README, API, ADR |
| `log-analyzer` | subagent | Анализ логов, агрегация, отчёты |
| `planner` | subagent | Планирование реализации (STANDARD/HARD/CRO/CI) |
| `reviewer` | subagent | Ревью кода |
| `sys-inspector` | subagent | Инспекция Linux системы |
| `russian-dev` | deprecated | Мержирован в dev |

---

## После установки

### 1. Настройка API-ключа
```bash
nano ~/.local/share/kilo/auth.json
```
```json
{
  "opencode": {
    "type": "api",
    "key": "sk-..."
  }
}
```

### 2. SSH-ключи
Скопируй приватный ключ `id_ed25519` в `~/.ssh/`:
```bash
chmod 600 ~/.ssh/id_ed25519
```

### 3. Запуск Kilo
```bash
npx kilo
```

Или через алиас (после `source ~/.bashrc`):
```bash
kilo
```

---

## Полезные алиасы

```bash
kilo            # Запустить Kilo CLI
```

---

## Удаление

```bash
make uninstall      # Полное удаление (с подтверждением)
make uninstall-dry-run  # Просмотреть что будет удалено
```

---

## Лицензия

MIT © 2025 ZDarow. См. [LICENSE](LICENSE).
