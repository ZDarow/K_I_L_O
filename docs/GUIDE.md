# Руководство пользователя KiloCode + K_I_L_O

Полное руководство по установке, настройке и использованию экосистемы KiloCode AI CLI.

---

## Часть 1: Установка

### 1.1. Подготовка

Убедитесь, что система соответствует требованиям:

```bash
# Проверка ОС
cat /etc/os-release
# Должно быть: Linux Mint 21+ или Ubuntu 22.04+

# Проверка sudo
sudo -v

# Проверка интернета
curl -I https://github.com
```

### 1.2. Установка из репозитория

```bash
# Клонирование
git clone https://github.com/ZDarow/K_I_L_O.git /tmp/kilo-install
cd /tmp/kilo-install

# Pre-flight проверка
make check

# Установка
make install

# Активация
source ~/.bashrc
```

### 1.3. Флаги установки

```bash
# Сухой прогон (посмотреть что будет сделано)
./install.sh --dry-run

# Продолжить с 5-го шага (если установка прервалась)
./install.sh --resume-from=5

# Без pre-flight проверки
./install.sh --skip-preflight
```

### 1.4. Проверка установки

```bash
make verify
```

Ожидаемый результат:

```text
━━━ Верификация установки ━━━

  → Manifest установки
  [✓] Manifest найден: /home/user/.local/share/kilo/manifest.json
  Дата установки: 2025-06-19T00:30:00+03:00
  Файлов в манифесте: 142

  → Конфигурация Kilo
  [✓] /home/user/.kilo/kilo.jsonc
  [✓] /home/user/.kilo/package.json
  [✓] /home/user/.kilo/agents (14 файлов)
  ...

  → Node.js экосистема
  [✓] node установлен: v22.x.x
  [✓] npm установлен: 10.x.x
  ...
```

---

## Часть 2: Первоначальная настройка

### 2.1. API-ключ

KiloCode требует API-ключ для работы с AI-моделями:

```bash
nano ~/.local/share/kilo/auth.json
```

Замените содержимое на:

```json
{
  "kilo": {
    "type": "api",
    "key": "sk-ваш_ключ_от_provider"
  }
}
```

**Где взять ключ:**
- OpenRouter: <https://openrouter.ai/keys>
- OpenAI: <https://platform.openai.com/api-keys>
- Anthropic: <https://console.anthropic.com/>

### 2.2. SSH-ключи

Если у вас есть приватный ключ — скопируйте его:

```bash
cp /путь/к/id_ed25519 ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
```

Добавьте публичный ключ на GitHub:

```bash
cat ~/.ssh/id_ed25519.pub
# Скопируйте вывод и добавьте в GitHub: Settings → SSH and GPG keys
```

### 2.3. Настройка Git

```bash
git config --global user.name "Ваше Имя"
git config --global user.email "email@example.com"
```

---

## Часть 3: Запуск KiloCode

### 3.1. Запуск агента по умолчанию (dev)

```bash
npx kilo
```

Или после `source ~/.bashrc`:

```bash
kilo
```

### 3.2. Вызов конкретного агента

```bash
npx kilo --agent git-specialist
```

Внутри KiloCode:

```text
/agent git-specialist "Покажи статус репозитория"
/agent planner "Спланируй реализацию новой функциональности"
/agent reviewer "Проверь код на ошибки"
```

### 3.3. Вызов команд

```text
/flutter-build
/git-status
/git-commit
/git-branch
```

---

## Часть 4: Работа с агентами

### 4.1. dev — универсальный агент (по умолчанию)

Основной агент с полной автономией. Объединяет экспертизу в разработке, Git, отладке, планировании и управлении проектами.

**Примеры запросов:**

```text
"Настрой новый проект"
"Проанализируй логи и найди ошибку"
"Создай Git-ветку и сделай коммит"
"Напиши тесты для модуля"
"Проверь состояние системы"
"Установи Python-пакет"
```

### 4.2. planner — планирование

```text
"Спланируй реализацию новой функциональности"
"Сравни два подхода: REST vs GraphQL"
"Сложное исправление: race condition в многопоточном коде"
"Настрой CI/CD для Flutter-приложения"
```

### 4.3. debugger — отладка

```text
"Проанализируй ошибку: crash при запуске приложения"
"Найди root cause: утечка памяти"
"Отладь: неверный ответ от API"
```

### 4.4. doc-scribe — документация

```text
"Создай README для проекта"
"Напиши API-документацию"
"Составь архитектурный ADR"
```

### 4.5. log-analyzer — анализ логов

```text
"Найди ошибки в логах приложения"
"Проанализируй системные логи"
"Покажи частоту ошибок по часам"
```

### 4.6. sys-inspector — система

```text
"Покажи информацию о системе"
"Проверь использование диска и памяти"
"Найди процессы, нагружающие CPU"
"Проверь состояние сетевых интерфейсов"
```

### 4.7. reviewer — ревью кода

```text
"Проверь код на ошибки"
"Найди баги в Python-модуле"
"Оцени архитектуру приложения"
```

---

## Часть 5: Flutter-разработка

### 5.1. Сборка проекта

```text
# Зависимости
flutter pub get

# Анализ
flutter analyze

# Тесты
flutter test

# Сборка
flutter build apk              # Android APK
flutter build appbundle        # Android App Bundle
flutter build linux            # Linux (требует GTK+3, cmake)
flutter build web              # Web
```

### 5.2. Команда flutter-build

```text
/flutter-build
# Выполняет: pub get → analyze → test → build apk
```

---

## Часть 6: Git-работа

### 6.1. Статус

```text
/git-status
# Покажет: статус, diff, последние коммиты, ветки
```

### 6.2. Коммит

```text
/git-commit
# 1. Покажет diff
# 2. Спросит подтверждение
# 3. Создаст коммит
```

### 6.3. Ветки

```text
/git-branch feature/new-auth-service
/git-branch switch main
```

---

## Часть 7: Управление конфигурацией

### 7.1. Проектная конфигурация (`~/.kilo/`)

```text
ls ~/.kilo/               # Все файлы
ls ~/.kilo/agents/        # Агенты
ls ~/.kilo/commands/      # Команды
ls ~/.kilo/tools/         # Инструменты
ls ~/.kilo/skills/        # Навыки
ls ~/.kilo/instructions/  # Инструкции
```

### 7.2. Глобальная конфигурация (`~/.config/kilo/`)

```text
ls ~/.config/kilo/
cat ~/.config/kilo/AGENTS.md   # Правила высшего приоритета
```

### 7.3. Добавление своего агента

Создайте файл `~/.kilo/agents/my-agent.md`:

```yaml
---
name: my-agent
description: "Мой агент"
version: 1.0.0
mode: primary
steps: 100
color: "#00AA00"
---

# My Agent

...
```

### 7.4. Добавление своей команды

Создайте файл `~/.kilo/commands/my-command.md`:

```yaml
---
description: "Описание"
version: 1.0.0
agent: dev
---

# My Command

1. Шаг 1
2. Шаг 2
```

---

## Часть 8: Обслуживание

### 8.1. Бэкап

```text
make backup
# Создаёт бэкап в /tmp/kilo-backup-YYYYMMDD-HHMMSS/
```

### 8.2. Обновление конфигурации

```text
cd /tmp/kilo-install  # или ~/K_I_L_O
git pull
make install          # переустановит конфигурацию
```

### 8.3. Проверка целостности

```text
make verify
```

### 8.4. Очистка

```text
# Очистка логов установки
make clean

# Очистка npm-кэша
npm cache clean --force
```

### 8.5. Полное удаление

```text
make uninstall
# Подтвердите удаление: yes
```

---

## Часть 9: Советы и рекомендации

### Эффективное использование

1. **Начинайте с `/dev`** — это главный агент, он объединяет все возможности
2. **Используйте команды** — `/flutter-build`, `/git-status` быстрее, чем описание задачи словами
3. **Навыки загружаются автоматически** — при matching задаче агент сам подгружает нужный навык
4. **Проверяйте результат** — агент всегда выполняет верификацию (тесты, lint, сборка)
5. **Не бойтесь отдавать команды** — все разрешения уже выданы, агент автономен

### Типовые сценарии

```text
# Сценарий 1: Настройка нового проекта
"Создай новый проект с нуля"
"Настрой Git-репозиторий"
"Добавь зависимости"

# Сценарий 2: Анализ ошибок
"Проанализируй логи приложения"
"Найди root cause ошибки"
"Предложи исправление"
```

### Ошибки, которые стоит избегать

1. **Не обновляйте файлы в `.kilo/node_modules/`** — они управляются npm
2. **Не удаляйте `manifest.json`** — он нужен для verify и uninstall
3. **Не редактируйте `~/.config/kilo/AGENTS.md` без понимания** — это правила высшего приоритета
4. **Не используйте `sudo` для KiloCode** — CLI работает от пользователя

---

## Часть 10: Ссылки

- **Репозиторий:** <https://github.com/ZDarow/K_I_L_O>
- **Arduino CLI:** <https://arduino.github.io/arduino-cli/>

---

## Приложение A: Структура manifest.json

```json
{
  "version": "1.1.0",
  "installed_at": "2025-06-19T00:30:00+03:00",
  "dry_run": false,
  "files": [
    {"path": "/home/user/.kilo/kilo.jsonc", "checksum": "sha256..."},
    {"path": "/home/user/.kilo/agents/dev.md", "checksum": "sha256..."},
    ...
  ],
  "configs": {
    "src_dir": "/tmp/kilo-install/src",
    "os": "Linux",
    "host": "my-host",
    "backup_dir": "/tmp/kilo-backup-20250619-003000",
    "packages": "nodejs python3 git",
    "last_step": 12,
    "status": "complete",
    "completed_at": "2025-06-19T00:35:00+03:00"
  },
  "checksums": {}
```

## Приложение B: Таблица соответствия

| Команда KiloCode | CLI-эквивалент | Описание |
|-----------------|---------------|----------|
| `/flutter-build` | `flutter pub get && flutter analyze && flutter test && flutter build` | Сборка Flutter |
| `/git-status` | `git status && git log --oneline -15` | Статус Git |
| `/git-commit` | `git add -A && git commit` | Коммит |
| `/git-branch` | `git checkout -b <name>` | Работа с ветками |
