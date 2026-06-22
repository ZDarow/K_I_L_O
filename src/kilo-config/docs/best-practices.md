# KiloCode: Best Practices и продвинутая настройка

На основе официальной документации app.kilo.ai и экосистемы плагинов.

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

## 4. Кастомные инструменты (Custom Tools)

Можно создавать кастомные инструменты на JS/TS:

`.kilo/tools/disk-usage.ts`:
```typescript
import { tool } from "@kilocode/plugin";
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

`.kilo/tools/system-info.ts`:
```typescript
import { tool } from "@kilocode/plugin";
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

## 5. LSP — автодополнение и диагностика

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

## 6. Переменные окружения и файлы в конфиге

```json
{
  "model": "{env:KILO_MODEL}",
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "{file:~/.secrets/anthropic-key}"
      }
    }
  }
}
```

## 7. Watcher — игнорирование шумных директорий

```json
{
  "watcher": {
    "ignore": ["node_modules/**", "dist/**", ".git/**", "build/**"]
  }
}
```

## 8. Полезные ссылки

- Официальная документация: https://app.kilo.ai/docs/
- GitHub: https://github.com/ZDarow/K_I_L_O

## 9. Агенты для работы с файловой системой и документацией

Проект включает специализированных агентов для Linux:

| Агент | Назначение | Права |
|-------|-----------|-------|
| `dev` | Универсальный ассистент разработки | bash+edit |
| `doc-scribe` | Документация: README, API-гайды, ADR, changelog | read-only fs |
| `sys-inspector` | Health check: CPU, RAM, диск, сеть, процессы | bash+read-only |
| `log-analyzer` | Анализ логов: парсинг, агрегация, отчёты | bash+read-only |
| `debugger` | Отладка ошибок, стектрейсов, root cause | bash+read-only |

Примеры вызова:
```
@doc-scribe Создай README по коду в src/
@sys-inspector Проверь здоровье системы
@log-analyzer Найди топ-5 ошибок за сегодня
@debugger Проанализируй ошибку в логе
```
