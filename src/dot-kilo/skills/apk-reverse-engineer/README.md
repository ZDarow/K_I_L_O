# 🔍 APK Reverse Engineer Skill

Специалист по декомпиляции APK и анализу Android-приложений с фокусом на поиск Bluetooth-соединений.

## 📁 Структура

```
apk-reverse-engineer/
├── SKILL.md                          # Основная документация skill
├── README.md                         # Этот файл
├── scripts/
│   ├── decompile-apk.sh              # Скрипт декомпиляции APK
│   ├── search-bluetooth.sh           # Поиск Bluetooth-кода
│   ├── analyze-manifest.sh           # Анализ AndroidManifest.xml
│   └── frida-bluetooth-hook.js       # Frida скрипт для мониторинга
└── templates/
    ├── apk-analysis-report-template.md  # Шаблон отчёта
    └── analysis-checklist.md            # Чеклист анализа
```

## 🚀 Быстрый старт

### 1. Установка инструментов

```bash
# Ubuntu/Debian
sudo apt-get install apktool jadx unzip openjdk-17-jdk

# Arch Linux
sudo pacman -S apktool jadx unzip jdk17-openjdk

# macOS
brew install apktool jadx unzip

# Frida (опционально)
pip install frida-tools
```

### 2. Запуск анализа

```bash
cd ~/.qwen/skills/apk-reverse-engineer/scripts

# Полная декомпиляция
./decompile-apk.sh /path/to/app.apk

# Поиск Bluetooth-кода
./search-bluetooth.sh app_decompiled

# Анализ AndroidManifest.xml
./analyze-manifest.sh app.apk
```

### 3. Динамический анализ (опционально)

```bash
# Подключить устройство и запустить Frida
frida -U -f com.example.app -l frida-bluetooth-hook.js --no-pause
```

## 📖 Использование

### Сценарий 1: Быстрый анализ на наличие Bluetooth

```bash
# Декомпиляция и поиск
./decompile-apk.sh app.apk
./search-bluetooth.sh app

# Проверка отчёта
cat bluetooth_analysis_report.txt
```

### Сценарий 2: Полный анализ с отчётом

```bash
# Декомпиляция
./decompile-apk.sh app.apk

# Поиск Bluetooth
./search-bluetooth.sh app

# Анализ манифеста
./analyze-manifest.sh app

# Заполнить шаблон отчёта
cp ../templates/apk-analysis-report-template.md reports/app_analysis.md
```

### Сценарий 3: Динамический анализ

```bash
# Установить APK на устройство
adb install app.apk

# Запустить Frida мониторинг
frida -U -f com.example.app -l frida-bluetooth-hook.js --no-pause

# Взаимодействовать с приложением для сбора логов
```

## 🔑 Ключевые классы для поиска

### Classic Bluetooth
- `android.bluetooth.BluetoothAdapter`
- `android.bluetooth.BluetoothDevice`
- `android.bluetooth.BluetoothSocket`

### Bluetooth Low Energy
- `android.bluetooth.le.BluetoothLeScanner`
- `android.bluetooth.BluetoothGatt`
- `android.bluetooth.BluetoothGattCallback`
- `android.bluetooth.BluetoothGattCharacteristic`

## 📊 Форматы UUID

| Тип | Формат | Пример |
|-----|--------|--------|
| Полный | XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX | `0000110A-0000-1000-8000-00805F9B34FB` |
| 16-bit | 0xXXXX | `0x110A` |
| 32-bit | 0xXXXXXXXX | `0x0000110A` |

## 🛡️ Безопасность

⚠️ **Используйте только для:**
- Анализа собственных приложений
- Авторизованного тестирования безопасности
- Образовательных целей

## 📚 Дополнительные ресурсы

- [Android Bluetooth API](https://developer.android.com/guide/topics/connectivity/bluetooth)
- [BLE Developer Guide](https://developer.android.com/guide/topics/connectivity/bluetooth-le)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security-testing-guide/)

## 📝 Лицензия

Инструменты созданы для образовательных целей и авторизованного тестирования безопасности.

---

**Версия:** 1.0.0  
**Дата:** 2026-03-15
