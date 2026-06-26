# Project Context
Проект: K_I_L_O — Установщик экосистемы Kilo AI CLI.
ОС: Linux Mint 22.3 (Cinnamon 64-bit).
Стек: Shell (Bash), Makefile, Python, Dockerfile.
Инструменты: Только терминал (sed, awk, grep). GUI не использовать.

# Core Rules
- Все изменения в `install.sh` и `scripts/lib.sh` должны быть POSIX/Bash совместимы.
- Всегда используй функции бэкапа из `lib.sh` перед изменением системных файлов.
- Сохраняй структуру целей в `Makefile`.
