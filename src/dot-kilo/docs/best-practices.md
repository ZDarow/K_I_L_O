# OpenCode: Best Practices и продвинутая настройка

На основе официальной документации opencode.ai и экосистемы плагинов.

## 1. Управление контекстом (Compaction)

```json
{
  "compaction": {
    "auto": true,        // авто-сжатие при заполнении контекста
    "prune": true,       // удалять старые выводы инструментов
    "reserved": 10000,   // резерв токенов для операции сжатия
    "tail_turns": 2      // сколько последних витков сохранять
  }
}
```

- `auto: true` — критично для длинных сессий
- `prune: true` — экономит ~30% токенов
- Плагин `opencode-dynamic-context-pruning` — ещё больше оптимизирует

## 2. Permissions (безопасность)

Рекомендуемая схема:

```json
{
  "permission": {
    "read": "allow",
    "edit": "allow",
    "bash": "ask",        // спрашивать перед bash-командами
    "webfetch": "allow",
    "websearch": "allow",
    "skill": "allow"
  }
}
```

Для агента `plan` всё на `deny`/`ask` — он только анализирует.

Для агента `review` — `edit: deny, bash: deny`.

## 3. MCP-серверы для автоматизации ОС

### Базовые:

| MCP сервер | Назначение |
|------------|------------|
| `@modelcontextprotocol/server-filesystem` | Полный доступ к файловой системе |
| `@modelcontextprotocol/server-everything` | Тестовый набор инструментов |
| `@modelcontextprotocol/server-github` | GitHub API (PR, issues, репозитории) |
| `@modelcontextprotocol/server-postgres` | PostgreSQL базы данных |
| `@modelcontextprotocol/server-sqlite` | SQLite базы данных |

### Удалённые MCP:

| MCP сервер | URL | Назначение |
|------------|-----|------------|
| Context7 | `https://mcp.context7.com/mcp` | Поиск по документациям |
| Grep by Vercel | `https://mcp.grep.app` | Поиск кода на GitHub |
| Sentry | `https://mcp.sentry.dev/mcp` | Мониторинг ошибок |

### Конфигурация:

```json
{
  "mcp": {
    "filesystem": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "/"]
    }
  }
}
```

## 4. Плагины для продуктивности

### Для ОС-автоматизации и уведомлений:

| Плагин | Назначение |
|--------|------------|
| `opencode-notifier` | Десктопные уведомления о завершении задач |
| `opencode-notificator` | Звуковые оповещения и уведомления |
| `opencode-pty` | Фоновые процессы в PTY (интерактивный ввод) |
| `opencode-shell-strategy` | Предотвращает зависание TTY-команд |
| `opencode-scheduler` | Планировщик задач (launchd/systemd) |
| `opencode-worktree` | Git worktree для изоляции изменений |

### Для контекста и памяти:

| Плагин | Назначение |
|--------|------------|
| `opencode-supermemory` | Постоянная память между сессиями |
| `opencode-dynamic-context-pruning` | Оптимизация токенов (удаляет устаревшие выводы) |
| `opencode-type-inject` | Авто-инъекция TypeScript типов |
| `oh-my-opencode` | Набор фоновых агентов, LSP/AST/MCP инструментов |
| `opencode-conductor` | Protocol-Driven Workflow: Context → Spec → Plan → Code |

### Для мониторинга:

| Плагин | Назначение |
|--------|------------|
| `opencode-wakatime` | Трекинг времени через Wakatime |
| `opencode-helicone-session` | Трекинг запросов к LLM через Helicone |

## 5. Custom Tools — взаимодействие с ОС

Можно создавать кастомные инструменты на JS/TS/Python:

`.opencode/tools/disk-usage.ts`:
```typescript
import { tool } from "@opencode-ai/plugin";
export default tool({
  description: "Показать использование диска",
  args: {
    path: tool.schema.string().describe("Путь к директории").optional(),
  },
  async execute(args) {
    const target = args.path || ".";
    const result = await Bun.$`du -sh ${target}`.text();
    return result.trim();
  },
});
```

`.opencode/tools/system-info.ts`:
```typescript
import { tool } from "@opencode-ai/plugin";
export default tool({
  description: "Информация о системе (ОС, RAM, CPU, диски)",
  args: {},
  async execute() {
    const os = await Bun.$`uname -a`.text();
    const mem = await Bun.$`free -h`.text();
    const disk = await Bun.$`df -h /`.text();
    return `OS: ${os.trim()}\nRAM:\n${mem.trim()}\nDisk:\n${disk.trim()}`;
  },
});
```

## 6. LSP — автодополнение и диагностика

```json
{
  "lsp": {
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"]
    },
    "go": { "command": "gopls" },
    "python": { "command": "basedpyright-langserver", "args": ["--stdio"] },
    "rust": { "command": "rust-analyzer" }
  }
}
```

Экспериментальный LSP-инструмент (даёт definition, references, hover):
```bash
OPENCODE_EXPERIMENTAL_LSP_TOOL=true opencode
```

## 7. Плагины через npm в opencode.json

```json
{
  "plugin": [
    "opencode-notifier",
    "opencode-supermemory",
    "opencode-shell-strategy",
    "opencode-dynamic-context-pruning"
  ]
}
```

Устанавливаются автоматически через Bun при старте.

## 8. Переменные окружения и файлы в конфиге

```json
{
  "model": "{env:OPENCODE_MODEL}",
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "{file:~/.secrets/anthropic-key}"
      }
    }
  }
}
```

## 9. Watcher — игнорирование шумных директорий

```json
{
  "watcher": {
    "ignore": ["node_modules/**", "dist/**", ".git/**", "build/**"]
  }
}
```

## 10. Полезные ссылки

- Официальная документация: https://opencode.ai/docs/
- Экосистема плагинов: https://opencode.ai/docs/ecosystem/
- GitHub: https://github.com/anomalyco/opencode
- Discord: https://opencode.ai/discord
- Awesome OpenCode: https://github.com/awesome-opencode/awesome-opencode

## 11. Агенты для работы с файловой системой и документацией

Проект включает специализированных агентов для Linux:

| Агент | Назначение | Права |
|-------|-----------|-------|
| `@fs-manager` | Управление файлами, правами, симлинками, поиск дубликатов | bash+edit |
| `@doc-scribe` | Документация: README, API-гайды, ADR, changelog | read-only fs |
| `@sys-inspector` | Health check: CPU, RAM, диск, сеть, процессы | bash+read-only |
| `@log-analyzer` | Анализ логов: парсинг, агрегация, отчёты | bash+read-only |
| `@backup-manager` | Бэкапы: rsync, tar, ротация, снапшоты | bash+edit |

Примеры вызова:
```
@fs-manager Найди битые симлинки в проекте
@doc-scribe Создай README по коду в src/
@sys-inspector Проверь здоровье системы
@log-analyzer Найди топ-5 ошибок за сегодня
@backup-manager Сделай бэкап проекта
```
