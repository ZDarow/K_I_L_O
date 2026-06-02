---
description: Build Flutter project — pub get, analyze, test, build APK/Linux
---

# Flutter Build

1. Обнови зависимости: `flutter pub get`
2. Запусти линтинг: `flutter analyze`
3. Запусти тесты: `flutter test`
4. Собери под нужную платформу:
   - **Android:** `flutter build apk` или `flutter build appbundle`
   - **Linux:** `flutter build linux` (требует GTK+3, cmake)
   - **iOS:** `flutter build ios`
   - **Web:** `flutter build web`
5. Если ошибки — исправляй и повторяй, пока не пройдёт

## Полезные флаги
- `--debug` — быстрая отладка
- `--release` — релиз
- `--split-per-abi` — раздельная сборка по ABI (Android)
- `--target-platform android-arm64` — конкретная архитектура
