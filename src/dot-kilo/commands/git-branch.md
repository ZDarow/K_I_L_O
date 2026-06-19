---
description: Управление ветками — создание, переключение, слияние, удаление
version: 1.0.0
agent: git-specialist
---

# Git Branch

## Создать новую ветку
```bash
git checkout -b feature/<name>
```

## Переключиться
```bash
git checkout <branch>
# или
git switch <branch>
```

## Слияние
```bash
git checkout <target>
git merge <source>       # требуется подтверждение
```

## Перебазирование
```bash
git checkout <feature>
git rebase <main>        # требуется подтверждение
```

## Удалить (если слита)
```bash
git branch -d <branch>   # локальная
git push origin --delete <branch>  # удалённая (требуется подтверждение)
```

## Формат названий
- `feature/<name>` — новая функциональность
- `fix/<name>` — исправление
- `docs/<name>` — документация
- `chore/<name>` — обслуживание
