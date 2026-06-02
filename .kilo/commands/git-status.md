---
description: Показать состояние репозитория — статус, изменения, ветки, последние коммиты
---

# Git Status

## Текущее состояние
```bash
git status
git diff --stat
```

## Недавние коммиты
```bash
git log --oneline --graph --all -15
```

## Ветки
```bash
git branch -a
```

## Если нужен полный diff
```bash
git diff
```
