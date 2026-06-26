# Test Mode Context
- BATS-тесты в `tests/*.bats` — пиши на Bash, без bats-assert/bats-file зависимостей.
- Python-тесты в `tests/test_gui.py` — используй pytest, unittest стиль.
- Все тесты должны проходить через `make test`.
- Новый функционал требует как минимум одного позитивного и одного негативного теста.
- Перед добавлением теста проверь: `make test` зелёный → добавь тест → `make test` снова зелёный.
