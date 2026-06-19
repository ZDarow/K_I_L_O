# Команды KiloCode

Проект включает **5 команд** для автоматизации типовых задач.

---

## Flutter-команды

### 1. `flutter-build` — Сборка Flutter-проекта

**Агент:** `dev`

Полный цикл сборки Flutter-приложения:

1. `flutter pub get` — обновление зависимостей
2. `flutter analyze` — линтинг
3. `flutter test` — тесты
4. `flutter build apk` / `flutter build linux` — сборка под платформу

**Флаги:**
- `--debug` — быстрая отладка
- `--release` — релиз
- `--split-per-abi` — раздельная сборка по ABI (Android)
- `--target-platform android-arm64` — конкретная архитектура

---

## Git-команды

### 2. `git-branch` — Управление ветками

**Агент:** `git-specialist`

```bash
# Создать
git checkout -b feature/<name>

# Переключиться
git checkout <branch>          # или git switch <branch>

# Слияние (требуется подтверждение)
git checkout <target>
git merge <source>

# Перебазирование (требуется подтверждение)
git checkout <feature>
git rebase <main>

# Удалить (если слита)
git branch -d <branch>
git push origin --delete <branch>  # требуется подтверждение
```

**Формат названий веток:**
- `feature/<name>` — новая функциональность
- `fix/<name>` — исправление
- `docs/<name>` — документация
- `chore/<name>` — обслуживание

### 3. `git-commit` — Создание коммита

**Агент:** `git-specialist`

**Протокол:**
1. Показать `git diff --stat` и `git diff`
2. Добавить файлы: `git add -A`
3. Создать коммит: `git commit -m "<тип>: <описание>"`
4. **Обязательно подтверждение пользователя** перед коммитом и пушем

**Типы коммитов:**
- `feat:` — новая функциональность
- `fix:` — исправление ошибки
- `refactor:` — рефакторинг
- `docs:` — документация
- `test:` — тесты
- `chore:` — обслуживание
- `style:` — форматирование
- `perf:` — оптимизация
- `ci:` — CI/CD

### 4. `git-status` — Состояние репозитория

**Агент:** `git-specialist`

Показывает:
- `git status` — текущее состояние
- `git diff --stat` — изменения
- `git log --oneline --graph --all -15` — недавние коммиты
- `git branch -a` — все ветки

---

## Команда `test`

**Агент:** `dev`

Универсальная команда для работы с тестами. Поддерживает 4 режима:

| Режим | Триггер | Описание |
|-------|---------|----------|
| **RUN** | default | Запуск полного набора тестов |
| **FIX** | «fix», «failing», «broken» | Авто-исправление падающих тестов |
| **COVERAGE** | «coverage», «gaps» | Анализ пробелов в покрытии |
| **WRITE** | «write», «create», «add» | Генерация новых тестов |

**Авто-детекция фреймворка:**
| Фреймворк | Детекция | Команда |
|-----------|----------|---------|
| Jest | package.json → jest | `npm test` |
| Vitest | vitest.config.* | `npm run test` |
| pytest | pytest.ini / pyproject.toml | `pytest -v` |
| Flutter | pubspec.yaml | `flutter test` |
| Go | go.mod | `go test ./...` |
