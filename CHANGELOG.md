# Changelog

<!-- markdownlint-disable MD024 — повторяющиеся заголовки свойственны Keep a Changelog -->

Все значимые изменения проекта K_I_L_O документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
проект следует [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] — 2026-06-25

### Добавлено
- Агент `ble-specialist` — эксперт по BLE/GATT реверс-инжинирингу
- CI job: Docker-тест реальной установки (`make install && make verify`)
- CI job: Lint BLE-скриптов (`ble-project/scripts/`)
- Makefile цель `git-hooks` — установка pre-commit хуков
- Makefile цель `sync-global` — синхронизация `src/global-config/` → `.config/kilo/`
- `.githooks/pre-commit` — проверка shellcheck, секретов, синтаксиса Python, YAML
- CHANGELOG.md, первый git-тег `v1.2.0`

### Изменено
- `.kilo/docs/best-practices.md`: `Bun.$` → `child_process.execSync` для совместимости с `@kilocode/plugin`
- `docs/GUIDE.md`, `docs/CONFIGURATION.md`, `docs/DEVELOPMENT.md`: `agents/` → `agent/`
- `README.md`: добавлен `ble-specialist`, счёт агентов 9→10
- `src/bashrc-append.sh`: удалён нерабочий алиас `kilocode`
- Permission-модель: документально описаны различия проектного и глобального конфигов

### Удалено
- Чужеродная документация Gemini-Kit (4 файла из `.kilo/docs/` + 4 зеркала из `src/kilo-config/docs/`):
  `README.md`, `API.md`, `FEATURES.md`, `WORKFLOWS.md`
- Deprecated агент `russian-dev` из `src/kilo-config/agent/`

### Исправлено
- `install.sh`: GPG-верификация NodeSource (предотвращение supply chain attack)
- `auth.template.json`, `tui.json`, `GUIDE.md`: `opencode` → `kilo`
- `.config/kilo/package.json`: 7.3.16 → 7.3.40
- `best-practices.md` (2 копии): все `opencode` → `kilo`
- Placeholder API-ключи: заменены на `process.env.API_KEY || "<YOUR_API_KEY>"`
- `docs/solutions/templates/solution-template.md`: удалены дубликаты (4→2 копии)

## [1.1.0] — 2026-06-22

### Добавлено
- Полная структура BLE-проекта (`ble-project/`) — ESP32, Android, BlueZ, GATT
- Скилл `android-ble-debug` для диагностики BLE на Android
- CI: 7 джобов (shellcheck, yamllint, markdownlint, actionlint, bats, dry-run, pre-flight, manifest-sync)
- Docker-образ на Linux Mint 22 для тестирования
- 6 bats-тестов: install, lib, preflight, sync, uninstall, verify
- `scripts/lib.sh`: manifest, dry-run, backup, run_sudo с чёрным списком команд

### Изменено
- Реструктуризация репозитория: установщик + конфигурационный фреймворк
- `src/dot-kilo/` → `src/kilo-config/`, `src/dot-config-kilo/` → `src/global-config/`
- `@kilocode/plugin` синхронизирован до 7.3.40 во всех package.json
- `Makefile version`: `bash -c 'source scripts/lib.sh && show_version'`

## [1.0.0] — 2026-06-19

### Добавлено
- Начальная структура установщика KiloCode CLI для Linux Mint
- 8 агентов: dev, debugger, doc-scribe, git-specialist, log-analyzer, planner, reviewer, sys-inspector
- 9 команд: debug, flutter-build, git-branch, git-commit, git-status, git, plan, review, test
- Проектная (`src/kilo-config/`) и глобальная (`src/global-config/`) конфигурации
- `install.sh` — 10-шаговый установщик с resume, dry-run, backup
- Makefile: 24 цели (install, lint, test, docker, sync)
- Лицензия MIT
