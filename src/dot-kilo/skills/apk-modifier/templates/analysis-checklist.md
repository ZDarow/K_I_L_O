# APK Analysis Checklist

## Pre-Analysis
- [ ] Проверено законное право на модификацию (собственное приложение / письменное разрешение)
- [ ] APK не повреждён (file, unzip -t)
- [ ] Создана резервная копия оригинального APK
- [ ] Определён тип защиты (APKiD / manual)
- [ ] Выбраны инструменты под тип упаковщика

## Decompile
- [ ] apktool: ресурсы + smali
- [ ] jadx: Java-исходники
- [ ] native libs извлечены (lib/armeabi-v7a, arm64-v8a, x86)
- [ ] strings извлечены и проиндексированы
- [ ] AndroidManifest.xml проанализирован:
  - [ ] Permissions
  - [ ] Activities (exported/internet)
  - [ ] Services
  - [ ] Receivers (exported)
  - [ ] Content providers

## Analysis
- [ ] Идентифицированы точки входа (MainActivity, Launcher)
- [ ] Найдены проверки лицензии/триала/регистрации
- [ ] Найдены сетевые endpoint'ы
- [ ] Выявлены hardcoded credentials
- [ ] Выявлены ключи шифрования
- [ ] Определена схема SSL pinning (TrustManager, OkHttp, TrustKit, native)
- [ ] Найдены obfuscated strings (native libs / custom)
- [ ] Проанализирован код аутентификации

## Modification Planning
- [ ] Определены целевые smali-файлы для патча
- [ ] Определены ресурсы для инъекции
- [ ] Определены native libs для модификации
- [ ] Составлен план обхода защиты (Frida / smali patching)

## Implementation
- [ ] Smali-патчи применены
- [ ] Ресурсы заменены/добавлены
- [ ] AndroidManifest.xml изменён
- [ ] Native libs пропатчены (если нужно)
- [ ] Frida-скрипты написаны для runtime-проверки

## Build & Sign
- [ ] apktool build без ошибок
- [ ] zipalign -p -f 4
- [ ] apksigner sign
- [ ] apksigner verify — OK
- [ ] Установка через adb install — OK
- [ ] Запуск на тестовом устройстве — OK
- [ ] Проверка модификации — OK
- [ ] Проверка стабильности (10+ мин работы) — OK

## Post-Analysis
- [ ] Отчёт о модификации заполнен
- [ ] Артефакты сохранены
- [ ] Исходный APK восстановлен (если не нужна модификация)
