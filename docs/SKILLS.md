# Навыки (Skills) Kilo

Навыки — специализированные модули знаний для агентов Kilo.

В текущей версии проекта навыки отсутствуют. Все ранее разработанные
BLE-навыки (ble-engineering, apk-reverse-engineer, apk-modifier,
wireshark-specialist, frida-specialist) перемещены в `ble-backup/`
для последующей доработки.

---

## Структура навыка

Каждый навык располагается в `.kilo/skills/<name>/` и содержит:

```
skills/<name>/
├── SKILL.md              # Основной файл навыка
├── README.md             # Краткое описание
├── scripts/              # Скрипты автоматизации
├── references/           # Справочные материалы
└── templates/            # Шаблоны отчётов
```

---

## Создание нового навыка

1. Создай директорию `.kilo/skills/<name>/`
2. Напиши `SKILL.md` в формате Kilo Skill
3. Добавь скрипты, references, templates по необходимости
4. Обнови `docs/SKILLS.md`
