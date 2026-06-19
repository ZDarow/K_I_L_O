# Расширение Kilo Code для VS Code

Документация по настройке расширения Kilo Code в Visual Studio Code.
Официальный сайт: <https://www.kilo.ai/docs>

---

## Установка

**ID в Marketplace:** `kilocode.kilo-code`

```bash
code --install-extension kilocode.kilo-code
```

Или через GUI: Extensions (`Ctrl+Shift+X`) → поиск «Kilo Code» → **Install Pre-Release Version**.

Альтернативные источники:
- **VSIX:** <https://github.com/Kilo-Org/kilocode/releases/latest>
- **Open VSX:** <https://open-vsx.org/extension/kilocode/Kilo-Code>

---

## Конфигурационные файлы

Расширение читает настройки из JSONC-файлов в двух уровнях:

| Файл | Уровень | Приоритет |
|------|---------|-----------|
| `~/.config/kilo/kilo.jsonc` | Глобальный | Низкий (применяется ко всем проектам) |
| `.kilo/kilo.jsonc` (или `./kilo.jsonc`) | Проектный | Высокий (переопределяет глобальный) |

Оба файла имеют одинаковую схему: `https://app.kilo.ai/config.json`

---

## Структура `kilo.jsonc`

### Основные поля

```jsonc
{
  "$schema": "https://app.kilo.ai/config.json",
  "username": "Universal Dev",
  "default_agent": "dev",
  "instructions": [
    "AGENTS.md",
    ".kilo/instructions/*.md"
  ],
  "auto_collapse_reasoning": true,
  "terminal_command_display": "collapsed",   // "expanded" | "collapsed"
  "compaction": {
    "auto": true,
    "prune": true,
    "reserved": 10000,
    "tail_turns": 2
  }
}
```

| Поле | Тип | Описание |
|------|-----|----------|
| `username` | string | Отображаемое имя пользователя |
| `default_agent` | string | Агент по умолчанию (из `.kilo/agent/*.md`) |
| `instructions` | string[] | Глобальные файлы инструкций |
| `auto_collapse_reasoning` | bool | Авто-сворачивание блоков рассуждений |
| `terminal_command_display` | string | Режим отображения терминальных блоков: `expanded` или `collapsed` |
| `compaction.auto` | bool | Автоматическая компактизация истории |
| `compaction.prune` | bool | Удалять старые сообщения при компактизации |
| `compaction.reserved` | number | Минимальное количество токенов после компактизации |
| `compaction.tail_turns` | number | Сохранять последние N оборотов диалога |

---

### Система разрешений (Permissions)

Три уровня для каждого инструмента:

| Значение | Поведение |
|----------|-----------|
| `"allow"` | Без подтверждения |
| `"ask"` | С подтверждением |
| `"deny"` | Запрещено |

Если правило не задано — по умолчанию `"ask"`.

**Доступные инструменты:**

```jsonc
"permission": {
  "read":              "allow",   // чтение файлов
  "glob":              "allow",   // поиск по маске
  "grep":              "allow",   // поиск содержимого
  "edit":              "allow",   // редактирование файлов
  "write":             "allow",   // создание файлов
  "question":          "allow",   // вопросы пользователю
  "todowrite":         "allow",   // todo-лист
  "webfetch":          "allow",   // загрузка URL
  "websearch":         "allow",   // веб-поиск
  "skill":             "allow",   // навыки (SKILL.md)
  "lsp":               "allow",   // Language Server Protocol

  "external_directory": "ask",   // файлы вне проекта

  // Под-агенты
  "task": {
    "*": "allow"
  },

  // Agent Manager сессии
  "agent_manager": {
    "*": "allow"
  },

  // Shell-команды — гибкие правила
  "bash": {
    "sudo apt*":            "ask",
    "sudo rm *":            "deny",
    "sudo rm -rf /*":       "deny",
    "sudo dd *":            "deny",
    "sudo mkfs*":           "deny",
    "sudo poweroff":        "deny",
    "sudo reboot":          "deny",
    "sudo shutdown":        "deny",
    "sudo kill -9 *":       "deny",
    "*":                    "allow"
  },

  // Доступ к внешним директориям
  "external_directory": {
    "*": "allow"
  }
}
```

Правила для `bash` поддерживают glob-паттерны. Проверка происходит от наиболее специфичного к наименее специфичному — первое совпадение определяет действие.

**MCP инструменты** используют именованные ключи: `{server}_{tool}` (например, `github_create_pull_request`). Поддерживаются glob-паттерны: `github_*`.

---

### Экспериментальные настройки

```jsonc
{
  "experimental": {
    "codebase_search": true,          // поиск по codebase
    "batch_tool": false,              // батч-инструменты
    "openTelemetry": true,            // телеметрия
    "disable_paste_summary": false,   // отключить суммаризацию вставок
    "mcp_timeout": 30000,             // таймаут MCP (мс)
    "speech_to_text_model": "openai/whisper-large-v3-turbo"
  }
}
```

Доступные экспериментальные режимы в UI Settings → Experimental:
- **Share mode** — `manual`, `auto`, `disabled` (расшаривание сессий)
- **LSP integration** — передача диагностик LSP агенту
- **Paste summary** — суммаризация больших вставок
- **Batch tool** — группировка вызовов инструментов
- **OpenTelemetry** — телеметрия с OTLP экспортом

---

### Переменные окружения

Чувствительные данные (API-ключи) рекомендуется передавать через переменные окружения, а не хранить в `kilo.jsonc`:

```bash
export KILO_PROVIDER_OPENAI_API_KEY="sk-..."
export KILO_PROVIDER_ANTHROPIC_API_KEY="sk-ant-..."
```

---

### Специфичные настройки VS Code

Эти настройки задаются в `settings.json` VS Code, а не в `kilo.jsonc`:

```jsonc
{
  // Корпоративный прокси
  "http.proxy": "http://proxy.example.com:8080",
  "http.noProxy": ["localhost", "127.0.0.1", ".example.internal"],
  "http.proxyStrictSSL": true,

  // Дополнительные сертификаты CA (PEM-файл)
  "kilo-code.new.extraCaCerts": "/path/to/corporate-ca.pem",

  // Рендеринг Markdown в diff
  "kilo-code.new.diff.renderMarkdown": true
}
```

---

## Полезные ссылки

| Ресурс | URL |
|--------|-----|
| Документация | <https://www.kilo.ai/docs> |
| Настройки | <https://www.kilo.ai/docs/getting-started/settings> |
| Auto-Approve (разрешения) | <https://www.kilo.ai/docs/getting-started/settings/auto-approving-actions> |
| Установка | <https://www.kilo.ai/docs/getting-started/installing> |
| VS Code extension | <https://www.kilo.ai/docs/code-with-ai/platforms/vscode> |
| GitHub | <https://github.com/Kilo-Org/kilocode> |
| GitHub Releases (VSIX) | <https://github.com/Kilo-Org/kilocode/releases> |
| Open VSX Registry | <https://open-vsx.org/extension/kilocode/Kilo-Code> |
| Discord | <https://kilo.ai/discord> |
