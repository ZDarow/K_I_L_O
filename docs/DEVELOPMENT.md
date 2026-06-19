# Разработка

---

## Локальная разработка

Этот репозиторий является **установщиком KiloCode CLI**, а также содержит **dev-конфигурацию** 
для разработки самого установщика с использованием KiloCode.

### Структура для разработчика

```text
K_I_L_O/                     # Рабочий репозиторий
├── .kilo/                   # Dev-конфигурация KiloCode (для разработки установщика)
│   ├── kilo.jsonc           #   Конфиг со всеми разрешениями
│   ├── agent/               #   Агенты (14 шт.)
│   ├── commands/            #   Команды (9 шт.)
│   ├── tools/               #   Инструменты (3 шт.)
│   ├── skills/              #   Навыки (5 шт.)
│   ├── instructions/        #   Инструкции (2 шт.)
│   └── node_modules/        #   npm-зависимости (@kilocode/plugin)
│
├── src/                     # Исходники, копируемые на целевую систему
│   ├── dot-kilo/            # → ~/.kilo/ (96 файлов)
│   ├── dot-config-kilo/     # → ~/.config/kilo/
│   ├── dot-local-share-kilo/# → ~/.local/share/kilo/
│   ├── dot-ssh/             # → ~/.ssh/
│   ├── bashrc-append.sh     # → ~/.bashrc
│   └── profile-append.sh    # → ~/.profile
│
├── scripts/                 # Скрипты установщика
├── install.sh               # Главный установщик
├── uninstall.sh             # Деинсталлятор
└── Makefile                 # Точка входа
```

### Важно: src/ vs .kilo/

В репозитории существует **два набора** конфигурации:

| Директория | Назначение |
|------------|-----------|
| `.kilo/` | **Dev-конфигурация** — используется при разработке установщика в KiloCode |
| `src/dot-kilo/` | **Исходники для установки** — копируются в `~/.kilo/` на целевой системе |

При внесении изменений в агенты/команды/инструменты/скиллы нужно синхронизировать 
оба набора, если изменения должны попасть в установку.

---

## Добавление нового агента

1. Создать `src/dot-kilo/agents/<name>.md` с YAML-фронтматером:
```markdown
---
name: <name>
description: "<описание>"
version: 1.0.0
mode: subagent
temperature: 0.3
---

# Agent Name

## Role
...
```

2. Скопировать в `.kilo/agent/<name>.md` для локальной разработки

3. Формат агента:
```yaml
---
name: <name>
description: "<описание>"
version: <версия>
mode: primary | subagent
temperature: <0.0-1.0>
steps: <шаги>        # только для primary
color: "<цвет>"      # только для primary
skills:              # только для subagent
  - <skill-name>
permission:          # опционально
  read: allow
  edit: allow
---
```

---

## Добавление новой команды

1. Создать `src/dot-kilo/commands/<name>.md`:
```yaml
---
description: "<описание>"
version: 1.0.0
agent: <agent-name>
---

# Command Name

...
```

2. Скопировать в `.kilo/commands/<name>.md`

---

## Добавление нового инструмента (TypeScript)

1. Создать `src/dot-kilo/tools/<name>.ts`:
```typescript
import { tool } from "@kilocode/plugin"

export default tool({
  description: "...",
  args: {
    param: tool.schema.string().describe("..."),
  },
  async execute(args, context) {
    return "result"
  },
})
```

2. Скопировать в `.kilo/tools/<name>.ts`

---

## Добавление нового навыка

1. Создать директорию `src/dot-kilo/skills/<name>/`
2. Создать `SKILL.md` — описание навыка
3. Добавить скрипты, шаблоны, референсы
4. Скопировать в `.kilo/skills/<name>/`

---

## Сборка и тестирование

```bash
# Pre-flight проверка
make check

# Установка (сухой прогон)
make dry-run

# Полная установка
make install

# Проверка после установки
make verify

# Создание бэкапа
make backup

# Полное удаление
make uninstall
```

### Тестирование скриптов

Проект не содержит автоматических тестов (unit-тестов). Ручное тестирование:

```bash
# Проверка preflight
bash scripts/preflight.sh

# Проверка verify
bash scripts/verify.sh

# Проверка установки в dry-run режиме
bash install.sh --dry-run

# Проверка удаления в dry-run режиме
bash uninstall.sh --dry-run
```

---

## Синхронизация с глобальной конфигурацией

Если вы изменили глобальную конфигурацию в `~/.config/kilo/`, 
нужно также обновить `src/dot-config-kilo/` в репозитории и наоборот.

```bash
# Синхронизация из глобальной в src
cp -r ~/.config/kilo/* src/dot-config-kilo/

# Синхронизация из src в глобальную
cp -r src/dot-config-kilo/* ~/.config/kilo/
```

---

## Git-commit для разрабоки

```bash
git status
git add -A
git commit -m "feat: добавлять новый агент для анализа логов"
```

**Типы коммитов:** feat, fix, refactor, docs, test, chore, style, perf, ci

---

## Инфраструктура качества

### CI/CD (GitHub Actions)

Файл: `.github/workflows/ci.yml`

**Проверки при push/PR:**
| Джоба | Инструмент | Что проверяет |
|-------|-----------|---------------|
| `lint-shell` | shellcheck | Синтаксис bash-скриптов |
| `lint-yaml` | yamllint | Синтаксис YAML-файлов |
| `lint-markdown` | markdownlint | Синтаксис Markdown |
| `test-bash` | bats | Unit-тесты для bash |
| `dry-run-install` | install.sh --dry-run | Работоспособность установщика |
| `check-manifest-sync` | diff | Синхронизация src/dot-kilo/ и .kilo/ |

### Линтеры

```bash
# ShellCheck — проверка bash-скриптов
sudo apt-get install -y shellcheck
make lint-shell

# yamllint — проверка YAML
pip3 install --user yamllint
make lint-yaml

# markdownlint — проверка Markdown
npm install -g markdownlint-cli
make lint-markdown

# Все линтеры разом
make lint
```

### Unit-тесты (bats)

```bash
# Установка bats
git clone https://github.com/bats-core/bats-core.git /tmp/bats
cd /tmp/bats && sudo ./install.sh /usr/local

# Запуск тестов
make test
# или
bats tests/
```

**Тестовые файлы:**

| Файл | Что тестирует |
|------|---------------|
| `tests/test_lib.bats` | scripts/lib.sh (логирование, проверки, бэкап, manifest, dry-run) |
| `tests/test_preflight.bats` | scripts/preflight.sh (структура, синтаксис) |
| `tests/test_verify.bats` | scripts/verify.sh (структура, синтаксис) |
| `tests/test_install.bats` | install.sh (12 шагов, dry-run, resume, функции) |
| `tests/test_uninstall.bats` | uninstall.sh (синтаксис, dry-run) |
| `tests/test_sync.bats` | Синхронизация src/dot-kilo/ и .kilo/ |

### Docker-контейнер

```bash
# Сборка образа
make docker-build

# Запуск тестов в контейнере
make docker-test

# Тестирование установки в чистой среде
make docker-install-test
```

### CHANGELOG.md

Файл `CHANGELOG.md` ведётся в формате [Keep a Changelog](https://keepachangelog.com/)
с версионированием [SemVer](<https://semver.org/>).

### Синхронизация src/dot-kilo/ и .kilo/

```bash
# Проверить расхождения
make sync-check

# Синхронизировать (копирует из .kilo/ в src/dot-kilo/)
make sync
```
