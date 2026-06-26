# K_I_L_O — Установщик экосистемы Kilo AI CLI

**Репозиторий:** [https://github.com/ZDarow/K_I_L_O](https://github.com/ZDarow/K_I_L_O)

[![CI](https://github.com/ZDarow/K_I_L_O/actions/workflows/ci.yml/badge.svg)](https://github.com/ZDarow/K_I_L_O/actions/workflows/ci.yml)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.12+-blue?logo=python)](https://www.python.org/)

Полная конфигурация AI-агента **Kilo** для Linux Mint / Ubuntu: русскоязычные правила,
системные настройки, CI/CD, тестирование и автоматизация.

---

## Возможности

- **Установка Kilo CLI** — AI-агент для командной строки
- **11 предустановленных AI-агентов** — dev, git-specialist, debugger, doc-scribe, log-analyzer, planner, reviewer, sys-inspector, python-senior, ble-specialist, obd2-specialist
- **9 команд быстрого доступа** — сборка Flutter, Git, ревью кода, планирование, тестирование
- **Двухуровневая конфигурация** — проектная (`~/.kilo/`) + глобальная (`~/.config/kilo/`) с иерархией приоритетов
- **SSH + Git** — преднастроенная конфигурация для GitHub/GitLab
- **Система бэкапов и манифестов** — отслеживание всех установленных файлов
- **24 pre-commit хука** — автоматическая проверка кода перед каждым коммитом (через pre-commit.ci)
- **16 инструментов линтинга** — shellcheck, yamllint, markdownlint, actionlint, shfmt, ruff, mypy, bandit, gitleaks, codespell, json5, commitizen, gitlint, pip-audit, deptry, vulture
- **12 CI job'ов** — GitHub Actions + локальный прогон через `act`
- **Docker-тестирование** — изолированная установка в Linux Mint контейнере
- **BLE Bumble Virtual Radio** — виртуальное BLE-устройство для тестов без HCI
- **Web-GUI** — SPA-интерфейс для мониторинга (0 зависимостей, встроенный HTTP-сервер)
- **Google Bumble** — фреймворк для BLE-тестирования без физического адаптера
- **VS Code интеграция** — `.vscode/` (settings, tasks, launch, extensions) + `.kilocode/rules/` (6 режимов)

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
| `make help` | Справка по всем целям |
| `make check` | Pre-flight: ОС, sudo, диск, интернет, Node.js |
| `make install` | Полная установка (с предпроверкой) |
| `make verify` | Пост-проверка: файлы, checksums, команды |
| `make dry-run` | Сухой прогон — что будет сделано |
| `make uninstall` | Полное удаление всех компонентов |
| `make backup` | Бэкап текущих конфигов в `/tmp/` |
| `make clean` | Очистка логов установки |
| `make lint` | Запустить все 12 линтеров |
| `make test` | Запустить все тесты (BATS + pytest) |
| `make gui-start` | Запустить веб-интерфейс (localhost:8088) |
| `make ble-bumble-ping` | Проверить виртуальное BLE-устройство |

Установщик также поддерживает флаги:
- `./install.sh --dry-run` — просмотр без изменений
- `./install.sh --resume-from=5` — продолжить с шага 5
- `./install.sh --skip-preflight` — без предпроверки

---

## Что устанавливается

### 1. Kilo CLI + Проектная конфигурация (`~/.kilo/`)
- `@kilocode/cli` (глобально через npm)
- 11 агентов (dev, git-specialist, debugger, doc-scribe, log-analyzer, planner, reviewer, sys-inspector, python-senior, ble-specialist, obd2-specialist)
- 9 команд (flutter-build, git-*, plan, review, test, debug)
- Инструкции на русском

### 2. Глобальная конфигурация (`~/.config/kilo/`)
- AGENTS.md — правила высшего приоритета для всех сессий Kilo
- Агент `russian-dev`
- TUI-конфигурация

### 3. Системные компоненты
- Node.js 22 LTS (через NodeSource)
- Python 3.12+, uv (менеджер пакетов вместо pip/venv)
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
├── Makefile                  # Точка входа (38 целей)
├── install.sh                # Установщик (install / --check / --verify / --uninstall)
├── pyproject.toml            # Python-зависимости и инструментарий (uv)
├── uv.lock                   # Lock-файл зависимостей (52 пакета)
│
├── scripts/
│   ├── lib.sh                # Общие функции (цвета, backup, manifest)
│   ├── bumble/               # Google Bumble Virtual Radio (BLE без HCI)
│   │   └── virtual_ble.py    #   3 сценария: ping / scan / gatt-server
│   └── ble-project/          # ESP32 + Android BLE инструменты
│
├── src/                      # Исходники для установки
│   ├── kilo-config/          #   → ~/.kilo/
│   ├── global-config/        #   → ~/.config/kilo/
│   ├── local-share/          #   → ~/.local/share/kilo/
│   ├── bashrc-append.sh      #   → ~/.bashrc
│   └── profile-append.sh     #   → ~/.profile
│
├── gui/                      # Веб-интерфейс
│   ├── server.py             #   REST API (5 эндпоинтов, 0 зависимостей)
│   └── index.html            #   SPA (тёмная тема, консоль, Make-цели)
│
├── tests/                    # Тесты
│   ├── test_gui.py           #   29 pytest-тестов
│   ├── test_install.bats     #   BATS-тесты установщика
│   ├── test_lib.bats         #   BATS-тесты lib.sh
│   ├── test_preflight.bats   #   BATS-тесты pre-flight
│   ├── test_sync.bats        #   BATS-тесты синхронизации
│   ├── test_uninstall.bats   #   BATS-тесты удаления
│   └── test_verify.bats      #   BATS-тесты верификации
│
├── docs/                     # Документация
│   ├── TECHNICAL_REFERENCE.md #   Полный технический справочник (1309 строк)
│   ├── ARCHITECTURE.md        #   Архитектура
│   ├── CONFIGURATION.md       #   Конфигурация
│   ├── SCRIPTS.md             #   Скрипты установщика
│   ├── DEVELOPMENT.md         #   Инструкция для разработчиков
│   ├── GUIDE.md               #   Полное руководство пользователя
│   └── TROUBLESHOOTING.md     #   Устранение проблем
│
├── docker/                   # Docker-тестирование
│   └── Dockerfile            #   Linux Mint образ
│
├── .kilo/                    # Dev-конфигурация Kilo (11 агентов, 9 команд)
├── .kilocode/                # VS Code Kilo rules (6 режимов)
├── .vscode/                  # VS Code конфигурация (settings, tasks, launch, extensions)
│
├── .github/                  # GitHub
│   ├── workflows/
│   │   ├── ci.yml            #   12 CI job'ов
│   │   └── release.yml       #   Авто-релиз при git tag
│   ├── dependabot.yml        #   Авто-обновление зависимостей
│   └── CODEOWNERS            #   Кодовая собственность
│
├── .pre-commit-config.yaml   # 24 pre-commit хука
├── .gitlint                  # Линтинг commit message
├── .bandit                   # Python security scanner
├── .gitattributes            # Нормализация файлов
├── CITATION.cff              # Цитирование
├── AGENTS.md                 # Правила для Kilo-сессий
├── LICENSE                   # MIT License
├── .gitignore
└── README.md
```

---

## Агенты Kilo

| Агент | Тип | Описание |
|-------|-----|----------|
| `dev` | primary | Универсальный — Linux, CI/CD, автоматизация, общее ПО |
| `git-specialist` | primary | Управление репозиториями, CI/CD, Git-протоколы |
| `debugger` | subagent | Анализ ошибок, стектрейсов, root cause |
| `doc-scribe` | subagent | Технический писатель: README, API, ADR |
| `log-analyzer` | subagent | Анализ логов, агрегация, отчёты |
| `planner` | subagent | Планирование реализации (STANDARD/HARD/CRO/CI) |
| `reviewer` | subagent | Ревью кода |
| `sys-inspector` | subagent | Инспекция Linux системы |
| `python-senior` | subagent | Senior Python-разработчик (асинхронность, FastAPI, pytest) |
| `ble-specialist` | subagent | Эксперт по BLE/GATT реверс-инжинирингу |
| `obd2-specialist` | subagent | Автомобильная диагностика OBD2, ELM327, CAN |
| `russian-dev` | deprecated | Мержирован в dev |

---

## После установки

### 1. Настройка API-ключа

```bash
nano ~/.local/share/kilo/auth.json
```

```json
{
  "kilo": {
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

## Документация

| Файл | Описание |
|------|----------|
| `docs/TECHNICAL_REFERENCE.md` | Исчерпывающая техническая документация (1309 строк, 5 разделов, 3 Mermaid-диаграммы) |
| `docs/ARCHITECTURE.md` | Архитектура проекта и схема модулей |
| `docs/CONFIGURATION.md` | Документация по конфигурации Kilo |
| `docs/DEVELOPMENT.md` | Руководство разработчика |
| `docs/GUIDE.md` | Руководство пользователя |
| `docs/SCRIPTS.md` | Документация по скриптам |
| `docs/TROUBLESHOOTING.md` | Устранение неполадок |
| `docs/KILO-VSCODE.md` | Интеграция с VS Code |
| `AGENTS.md` | Инструкции для AI-агентов |
| `CHANGELOG.md` | История изменений проекта |
| `CITATION.cff` | Цитирование проекта |

---

## Удаление

```bash
make uninstall      # Полное удаление (с подтверждением)
make uninstall-dry-run  # Просмотреть что будет удалено
```

---

## Лицензия

MIT © 2025 ZDarow. См. [LICENSE](LICENSE).
