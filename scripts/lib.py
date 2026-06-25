#!/usr/bin/env python3
"""KiloCode CLI — вспомогательные функции для Python-инструментария."""


def main() -> None:
    """Точка входа для kilo-ci.

    Используется pyproject.toml -> [project.scripts] kilo-ci.
    """
    print("KiloCode CLI v1.2.0 — утилита управления проектом")
    print("Использование: kilo-ci <command>")
    print("Команды:")
    print("  status    — статус проекта")
    print("  info      — информация о конфигурации")


if __name__ == "__main__":
    main()
