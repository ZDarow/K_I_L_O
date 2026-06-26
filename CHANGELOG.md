# Changelog

<!-- markdownlint-disable MD024 — повторяющиеся заголовки свойственны Keep a Changelog -->

Все значимые изменения проекта K_I_L_O документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
проект следует [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] — 2026-06-26

### Добавлено
- **16 инструментов автоматизации**: ruff, mypy, bandit, gitleaks, act, codespell, pip-audit, commitizen, deptry, vulture, gitlint, json5, pytest-xdist, pytest-sugar, pytest-timeout
- **24 pre-commit хука** (было 11): добавлены check-json, check-toml, check-ast, detect-private-key, debug-statements, check-docstring-first, mixed-line-ending, ruff, ruff-format, mypy, codespell, bandit, gitleaks
- **12 линтеров в `make lint`** (было 6): shellcheck, yamllint, markdownlint, json5, actionlint, shfmt, bandit, ruff, mypy, codespell, deptry, vulture
- **11 Makefile-целей**: lint-python-security, lint-secrets, lint-ruff, lint-types, lint-deps, lint-commits, lint-deps-unused, lint-deadcode, lint-git-commits, lint-spelling, changelog, bump (итого 38 целей)
- **Агент `obd2-specialist`** — автомобильная диагностика OBD2 (v1.1.0)
- **Агент `python-senior`** — Senior Python-разработчик (v1.0.0)
- `docs/TECHNICAL_REFERENCE.md` — исчерпывающая техническая документация (1309 строк, 5 разделов, 3 Mermaid-диаграммы)
- `.actrc` — конфигурация act для локального CI
- `[tool.pytest.ini_options]` — центральная конфигурация pytest (timeout=60, xdist-ready)
- `[tool.mypy]` — строгая проверка типов Python
- `[tool.commitizen]` — conventional commits с автогенерацией CHANGELOG
- `.gitleaksignore` — игнорирование 4 ложных срабатываний в документации
- `.gitlint` — кастомные лимиты commit message (120 символов)

### Изменено
- `gui/server.py`: привязка к `127.0.0.1` (безопасность), удалён неиспользуемый `shlex`, исправлен `log_message()`
- `pyproject.toml`: ruff расширен до правил UP/RUF/SIM/COM, добавлены mypy/pytest/commitizen секции
- `.pre-commit-config.yaml`: 12→24 хука, добавлены mypy, codespell
- `Makefile`: переработан `lint`, добавлены 11 новых целей, обновлён .PHONY
- `.markdownlint.yml`: добавлены языки mermaid/makefile/dockerfile/ini/text
- `.github/workflows/ci.yml`: actionlint теперь использует `golang-go` + явный путь к файлу
- **README.md**: обновлён список агентов (10→11), добавлены ссылки на TECHNICAL_REFERENCE.md
- **CHANGELOG.md**: добавлен раздел v1.3.0

### Удалено
- `.bandit` INI-файл → конфигурация перенесена в `[tool.bandit]` в pyproject.toml
- `[tool.bandit]` из pyproject.toml → обратно в `.bandit` YAML (т.к. pyproject.toml не поддерживается bandit)

### Исправлено
- `gui/server.py`: CORS `localhost:8088`, исправлен `shell=False`, таймауты, N802 подавлены
- CI `lint-actions` job: добавлен `golang-go` и `actionlint .github/workflows/ci.yml` (явный путь)
- `Makefile`: `lint-python-security` теперь использует `.bandit` конфиг
- `ag` → `grep` в README (инструмент не установлен по умолчанию)

### Полная верификация
- `pre-commit run --all-files`: 24/24 ✅
- `make lint`: 12/12 ✅
- `make test`: 35/35 ✅
- `act ci`: 8/9 ✅ (docker-in-docker ожидаемо)

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
