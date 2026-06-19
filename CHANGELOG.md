# История изменений

Все значимые изменения проекта K_I_L_O документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/),
и проект следует [Semantic Versioning](https://semver.org/).

---

## [1.2.0] — 2026-06-19

### Добавлено
- CI/CD: GitHub Actions workflow (6 джобов)
- Unit-тесты для bash-скриптов (bats, 39 тестов)
- Docker-контейнер для тестирования установки
- CHANGELOG.md
- Makefile цели: lint, test, docker-build, docker-test, sync, sync-check
- Линтеры: shellcheck (.shellcheckrc), yamllint (.yamllint.yml)

### Исправлено
- Полная синхронизация src/dot-kilo/ и .kilo/ (переименовано agents/ → agent/)
- Добавлены shebang в src/bashrc-append.sh и src/profile-append.sh
- Исправлены trailing spaces в src/dot-kilo/docs/solutions/schema.yaml
- Обновлён .gitignore (новые директории: .github/, tests/, docs/, Dockerfile, CHANGELOG.md)

---

## [1.1.0] — 2026-06-19

### Добавлено
- Полная документация проекта: ARCHITECTURE, AGENTS, COMMANDS, CONFIGURATION, SCRIPTS, DEVELOPMENT, TROUBLESHOOTING, GUIDE
- CI/CD: GitHub Actions workflow (линтер shell-скриптов, YAML, Markdown, тесты bats, dry-run, проверка синхронизации)
- Unit-тесты для bash-скриптов на bats: lib.sh, preflight.sh, verify.sh, install.sh, uninstall.sh, sync check
- Линтеры: shellcheck (.shellcheckrc), yamllint (.yamllint.yml)
- Docker-контейнер для тестирования установки (Dockerfile)
- CHANGELOG.md
- Makefile цели: lint, test, docker-build, docker-test

### Исправлено
- Синхронизация src/dot-kilo/ и .kilo/ (агенты, команды, навыки, инструменты, конфиги)
- .gitignore: добавлены новые директории (.github/, tests/, Dockerfile)
- Обновлён README.md с актуальной информацией

---

## [1.0.0] — 2026-06-08

### Добавлено
- Стандартизация конфигураций агентов, навыков и команд
- Dependabot конфигурация для автоматических обновлений npm
- Правила Git в AGENTS.md (commit на русском, ветки на английском)
- Правила чёткости инструкций и анти-двусмысленности
- Расширенные правила безопасности (запрет опасных команд)

### Исправлено
- Убрана жёстко заданная модель из конфига
- Убран local вне функции в verify.sh
- Все функции определены до вызовов step
- Исправлены критические баги в скриптах
- Исправлены разрешения bash, .gitignore, дубликаты и порядок правил в kilo.jsonc
- Исправлен год и автор в лицензии MIT

---

## [0.9.0] — 2026-06-06

### Добавлено
- Добавлена лицензия MIT
- Импорт компонентов из z-setup: агенты, навыки, TUI, docs, compaction
- Улучшена понятность репозитория
- Добавлена полная инфраструктура автоматизации установки

### Изменено
- Реструктуризация репозитория в установщик KiloCode CLI для Linux Mint

---

## [0.8.0] — 2026-05-07

### Добавлено
- Начальная настройка: Kilo-конфигурация, агенты и инструменты для разработки

### Исправлено
- Запрещены git-коммиты, пуш и синхронизация без явного согласия пользователя
- Установлен высший приоритет конфигурации для всех сессий
- Добавлены правила чёткости инструкций и анти-двусмысленности в AGENTS.md и kilo.jsonc

---

## Формат версионирования

- **MAJOR** — несовместимые изменения API/архитектуры
- **MINOR** — новая функциональность (документация, тесты, CI/CD, инструменты)
- **PATCH** — исправления багов, оптимизации

Текущая версия: **1.1.0**
