# Codebase Map

High-level overview of Gemini-Kit project structure.

## Directory Structure

```
gemini-kit/
├── agents/           # 15 AI agent definitions
├── commands/         # 42 slash commands (.toml)
├── hooks/            # Lifecycle hooks (before-tool, after-tool, etc.)
├── src/              # TypeScript source code
│   └── tools/        # MCP tool implementations
├── docs/             # Documentation
│   ├── architecture/ # System architecture
│   ├── decisions/    # ADRs
│   ├── solutions/    # Knowledge Base
│   └── specs/        # Multi-session specifications
├── scripts/          # 50+ automation scripts
├── skills/           # Modular agent capabilities
├── plans/            # Implementation plans
└── todos/            # Tracked work items
```

## Key Components

| Component | Path | Purpose |
|-----------|------|---------|
| Extension Entry | `gemini-extension.json` | Extension manifest |
| Agent Config | `GEMINI.md` | Agent behavior protocol |
| MCP Tools | `src/tools/*.ts` | Tool implementations |
| Settings | `settings.json` | Extension settings |

## Data Flow

```
User Request → GEMINI.md → Agent Selection → Commands/Workflows → MCP Tools → Response
```

## Related

- [Compound System Architecture](compound-system.md)
- [API Reference](../API.md)
