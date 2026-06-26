# Fix Mode Context
- Приоритет: сначала понять причину, потом чинить.
- Используй `git log --oneline -5` и `git diff` для контекста.
- После фикса всегда запускай `make test` и `make lint`.
- Если фикс ломает тесты — не коммить, исправь сначала.
- Для shell-скриптов: проверь ShellCheck (`make lint-shell`) перед коммитом.
- Для Python: проверь ruff и mypy.
