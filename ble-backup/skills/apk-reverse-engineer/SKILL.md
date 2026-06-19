---
name: apk-reverse-engineer
description: "Декомпиляция APK и анализ Android-приложений с фокусом на Bluetooth (BLE/Classic). Используй для реверс-инжиниринга, анализа трафика, поиска API"
version: 1.0.0
tags: [android, apk, reverse-engineering, bluetooth, ble, decompilation, security]
tools_required: [apktool, jadx, grep, strings, unzip, keytool]
---

# APK Reverse Engineer Skill

## Назначение

Этот skill предоставляет экспертизу по декомпиляции APK-файлов Android-приложений и поиску кода, связанного с Bluetooth-соединениями (Classic Bluetooth и BLE - Bluetooth Low Energy).

## Основные возможности

- Декомпиляция APK файлов
- Анализ AndroidManifest.xml
- Поиск Bluetooth-кода в декомпилированном коде
- Идентификация UUID сервисов BLE
- Анализ разрешений и компонентов приложения
- Поиск hardcoded credentials и endpoint'ов

## Необходимые инструменты

### Обязательные
```bash
# Ubuntu/Debian
sudo apt-get install apktool jadx unzip openjdk-17-jdk

# Arch Linux
sudo pacman -S apktool jadx unzip jdk17-openjdk

# macOS
brew install apktool jadx unzip
```

### Опциональные
```bash
# Frida для динамического анализа
pip install frida-tools

# Bytecode Viewer
# Скачать с https://github.com/Konloch/bytecode-viewer

# JEB Decompiler (коммерческий)
# https://www.pnfsoftware.com/jeb/
```

## Пошаговая методика анализа

### Шаг 1: Подготовка APK

```bash
# Проверка файла
file app.apk
unzip -l app.apk

# Извлечение AndroidManifest.xml без декомпиляции
unzip app.apk AndroidManifest.xml
aapt dump badging app.apk
```

### Шаг 2: Декомпиляция

```bash
# Декомпиляция ресурсов и кода с помощью apktool
apktool d app.apk -o app_decompiled

# Декомпиляция в Java с помощью jadx
jadx -d app_java app.apk

# Или через jadx-gui для интерактивного анализа
jadx-gui app.apk
```

### Шаг 3: Анализ AndroidManifest.xml

```bash
# Поиск Bluetooth-разрешений
grep -i "bluetooth" app_decompiled/AndroidManifest.xml

# Поиск всех разрешений
grep "<uses-permission" app_decompiled/AndroidManifest.xml

# Анализ компонентов (Activity, Service, Receiver)
grep -E "<(activity|service|receiver|provider)" app_decompiled/AndroidManifest.xml
```

### Шаг 4: Поиск Bluetooth-кода

#### Ключевые классы для поиска

**Classic Bluetooth:**
- `android.bluetooth.BluetoothAdapter`
- `android.bluetooth.BluetoothDevice`
- `android.bluetooth.BluetoothSocket`
- `android.bluetooth.BluetoothServerSocket`
- `android.bluetooth.BluetoothProfile`
- `android.bluetooth.BluetoothHeadset`
- `android.bluetooth.BluetoothA2dp`

**Bluetooth Low Energy (BLE):**
- `android.bluetooth.le.BluetoothLeScanner`
- `android.bluetooth.le.ScanCallback`
- `android.bluetooth.le.ScanFilter`
- `android.bluetooth.le.ScanSettings`
- `android.bluetooth.BluetoothGatt`
- `android.bluetooth.BluetoothGattCallback`
- `android.bluetooth.BluetoothGattCharacteristic`
- `android.bluetooth.BluetoothGattDescriptor`
- `android.bluetooth.BluetoothGattService`

#### Команды для поиска

```bash
# Поиск импортов Bluetooth-классов
grep -r "import android.bluetooth" app_java/

# Поиск создания BluetoothAdapter
grep -r "BluetoothAdapter" app_java/ --include="*.java"

# Поиск BLE-сканера
grep -r "BluetoothLeScanner\|startScan\|ScanCallback" app_java/ --include="*.java"

# Поиск GATT-операций
grep -r "BluetoothGatt\|connectGatt\|readCharacteristic\|writeCharacteristic" app_java/ --include="*.java"

# Поиск UUID сервисов
grep -roE "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}" app_java/

# Поиск строковых литералов Bluetooth
grep -r "bluetooth\|BLE\|GATT\|characteristic\|service" app_decompiled/ --include="*.smali"
```

### Шаг 5: Анализ строк

```bash
# Извлечение всех строк из APK
strings app.apk > strings_all.txt

# Поиск Bluetooth-related строк
strings app.apk | grep -iE "bluetooth|ble|gatt|uuid|service|characteristic"

# Поиск URL и endpoint'ов
strings app.apk | grep -oE "https?://[a-zA-Z0-9./_-]+"

# Поиск IP-адресов
strings app.apk | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"
```

### Шаг 6: Динамический анализ (опционально)

```bash
# Скрипт Frida для логирования Bluetooth-вызовов
frida -U -f com.example.app -l bluetooth_hook.js --no-pause
```

Пример `bluetooth_hook.js`:
```javascript
Java.perform(function() {
    var BluetoothAdapter = Java.use("android.bluetooth.BluetoothAdapter");

    BluetoothAdapter.enable.overload().implementation = function() {
        console.log("[+] BluetoothAdapter.enable() called");
        return this.enable();
    };

    var BluetoothGatt = Java.use("android.bluetooth.BluetoothGatt");
    BluetoothGatt.connect.overload().implementation = function() {
        console.log("[+] BluetoothGatt.connect() called");
        return this.connect();
    };
});
```

## Структура отчёта об анализе

```markdown
# Отчёт об анализе APK: [имя_файла.apk]

## Общая информация
- Package name: com.example.app
- Version: 1.0.0
- Min SDK: 21
- Target SDK: 33

## Bluetooth-разрешения
- BLUETOOTH
- BLUETOOTH_ADMIN
- BLUETOOTH_SCAN
- BLUETOOTH_CONNECT
- ACCESS_FINE_LOCATION

## Найденные Bluetooth-классы
### Classic Bluetooth
- [Список классов]

### Bluetooth Low Energy
- [Список классов]

## UUID сервисов
- [Список найденных UUID]

## Критические находки
- [Список потенциально уязвимых мест]

## Рекомендации
- [Рекомендации по безопасности]
```

## Безопасность и этика

⚠️ **ВАЖНО**: Используйте этот skill только для:
- Анализа собственных приложений
- Авторизованного тестирования безопасности
- Образовательных целей
- Reverse engineering легально полученных APK

Не используйте для:
- Обхода лицензионной защиты
- Кражи интеллектуальной собственности
- Несанкционированного доступа

## Полезные ресурсы

- [Android Bluetooth API Documentation](https://developer.android.com/guide/topics/connectivity/bluetooth)
- [BLE Developer Guide](https://developer.android.com/guide/topics/connectivity/bluetooth-le)
- [OWASP Mobile Security Testing Guide](https://owasp.org/www-project-mobile-security-testing-guide/)
- [Android Reverse Engineering Wiki](https://github.com/rednaga/APKiD/wiki)

## Примеры использования

### Пример 1: Быстрый анализ на наличие Bluetooth
```bash
apk-reverse-engineer analyze --quick app.apk
```

### Пример 2: Полный анализ с отчётом
```bash
apk-reverse-engineer analyze --full --report app.apk
```

### Пример 3: Поиск конкретного UUID
```bash
apk-reverse-engineer search-uuid "0000110A-0000-1000-8000-00805F9B34FB" app.apk
```

---

**Версия skill**: 1.0.0  
**Последнее обновление**: 2026-03-15  
**Автор**: APK Reverse Engineering Team
