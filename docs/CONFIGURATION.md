# Конфигурация проекта K_I_L_O

---

## Файлы конфигурации

### 1. `kilo.jsonc` — Главный конфигурационный файл KiloCode

Расположение: `.kilo/kilo.jsonc` (dev) / `~/.kilo/kilo.jsonc` (целевая система)

**Структура:**

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
  "compaction": {
    "auto": true,
    "prune": true,
    "reserved": 10000,
    "tail_turns": 2
  },
  "permission": {
    "read": "allow",
    "glob": "allow",
    "grep": "allow",
    "edit": "allow",
    "write": "allow",
    "question": "allow",
    "todowrite": "allow",
    "webfetch": "allow",
    "websearch": "allow",
    "skill": "allow",
    "task": {
      "*": "allow"
    },
    "bash": {
      "sudo apt*": "ask",
      "sudo rm *": "deny",
      "sudo rm -rf /*": "deny",
      "sudo dd *": "deny",
      "sudo mkfs*": "deny",
      "sudo poweroff": "deny",
      "sudo reboot": "deny",
      "sudo shutdown": "deny",
      "sudo kill -9 *": "deny",
      "*": "allow"
    },
    "external_directory": {
      "*": "allow"
    }
  }
}
```

**Ключевые настройки:**

| Поле | Значение | Описание |
|------|----------|----------|
| `username` | Universal Dev | Имя пользователя |
| `default_agent` | dev | Агент по умолчанию |
| `instructions` | AGENTS.md, .kilo/instructions/*.md | Файлы с правилами |
| `auto_collapse_reasoning` | true | Авто-сворачивание размышлений |
| `compaction.auto` | true | Автоматическая компактизация |
| `compaction.prune` | true | Обрезка старых сообщений |
| `compaction.reserved` | 10000 | Резерв сообщений |
| `compaction.tail_turns` | 2 | Хвостовых оборотов |

### 2. `AGENTS.md` — Правила для агентов

Расположение: корень проекта + `~/.config/kilo/AGENTS.md` (глобальная)

Содержит:
- Языковые правила (русский язык)
- Git-правила (commit на русском, ветки на английском)
- Правила автономии (все разрешения выданы)
- Чёткость инструкций (анти-двусмысленность)
- Критерии завершения задачи
- Приоритет инструкций

**Критерии завершения задачи:**
1. Все файлы созданы/изменены
2. Все зависимости установлены
3. Команды проверки выполнены и не вернули ошибок
4. Пользователю отправлен итоговый отчёт

### 3. `tui.json` — TUI-конфигурация

Расположение: `.kilo/tui.json` / `~/.config/kilo/tui.json`

Конфигурация терминального интерфейса KiloCode:
- Цветовые схемы
- Раскладка панелей
- Поведение терминала

### 4. `package.json` — npm-зависимости

Расположение: `.kilo/package.json` / `~/.config/kilo/package.json`

```json
{
  "dependencies": {
    "@kilocode/plugin": "7.3.40"
  }
}
```

Обеспечивает работу TypeScript-инструментов через KiloCode Plugin SDK.

---

## Двухуровневая конфигурация

Проект использует двухуровневую систему конфигурации:

```text
Проектная конфигурация (~/.kilo/)
├── kilo.jsonc                 # Настройки проекта
├── agent/                    # Агенты проекта
├── commands/                  # Команды проекта
├── tools/                     # Инструменты проекта
├── instructions/              # Инструкции проекта
├── skills/                    # Навыки проекта
└── tui.json                   # TUI-конфигурация проекта

Глобальная конфигурация (~/.config/kilo/)
├── kilo.jsonc                 # Глобальные настройки
├── AGENTS.md                  # Глобальные правила (высший приоритет)
├── agent/                    # Глобальные агенты
├── instructions/              # Глобальные инструкции
└── tui.json                   # Глобальная TUI-конфигурация
```

Глобальная конфигурация имеет **высший приоритет** над проектной.

---

## Разрешения (Permissions)

Система разрешений в KiloCode построена на трёх уровнях:

1. **Инструменты (Tools)** — read, glob, grep, edit, write, question, todowrite, webfetch, skill, task — полный доступ
2. **Bash-команды** — все разрешены, кроме явно запрещённых (sudo rm, sudo dd, sudo mkfs, sudo poweroff, sudo reboot, sudo shutdown, sudo kill -9)
3. **Внешние директории** — полный доступ

### Различия проектного и глобального конфига

| Параметр | Проектный (`~/.kilo/kilo.jsonc`) | Глобальный (`~/.config/kilo/kilo.jsonc`) |
|----------|----------------------------------|----------------------------------------|
| `username` | `"Universal Dev"` | `"Разработчик"` |
| `instructions` | `AGENTS.md`, `.kilo/instructions/*.md` | `AGENTS.md`, `instructions/*.md`, `~/.config/kilo/AGENTS.md` |
| `permission.bash` | `"*": "allow"` + 7 deny-правил | 22 разрешённые команды + 7 deny |
| `permission.external_directory` | `"*": "allow"` — все директории | `/etc/*`, `/tmp/*` — ограниченный доступ |

**Важно:** Проектный конфиг даёт агенту максимальную свободу (`"*": "allow"` для bash и external_directory). Глобальный конфиг более консервативен — разрешает только явно перечисленные команды и ограничивает внешние директории. Это означает, что при работе в разных проектах агент может иметь разный уровень доступа.

---

## Инструкции времени выполнения

### `.kilo/instructions/ru-instructions.md`

Правила для русского языка:
- Ответы и пояснения на русском
- Код и идентификаторы на английском
- Комментарии в коде на русском (описывают «почему», а не «что»)
- commit messages на русском
- Названия веток на английском (kebab-case)
- Русская терминология (коммит, ветка, слияние, пул-реквест)
- Формат дат: ДД.ММ.ГГГГ
- Кавычки: «ёлочки» или „лапки"
