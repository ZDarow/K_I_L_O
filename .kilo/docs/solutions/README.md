# Solutions - Knowledge Base

Persistent storage for solved problems and reusable patterns.

## Purpose

Capture and organize solutions to problems so they can be reused across sessions. Each solution includes symptoms, root cause analysis, and prevention strategies.

## Components

| Directory | Description |
|-----------|-------------|
| `patterns/` | Critical patterns and anti-patterns (23 patterns) |
| `integrations/` | Integration guides and solutions |
| `templates/` | Solution document templates |

## Component Details

### Schema (`schema.yaml`)
YAML validation schema for solution documents. Defines required fields, problem types, severity levels, and component types.

### Patterns (`patterns/critical-patterns.md`)
23 critical patterns learned from repeated mistakes. Every agent must consult before generating code.

### Templates (`solution-template.md`, `exploration-template.md`)
Standard templates for documenting problems and explorations.

## Usage

```bash
# Search for solutions
./scripts/compound-search.sh "keyword"

# Validate solutions
./scripts/validate-compound.sh
```

## Changelog

### 2024-12-24
- Integrated from Antigravity Compound Engineering Plugin
- Added 23 critical patterns
- Added integrations directory with compound plugin guide
