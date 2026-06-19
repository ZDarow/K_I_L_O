#!/bin/bash
#
# Скрипт анализа AndroidManifest.xml
# Использование: ./analyze-manifest.sh <apk_file|manifest_dir>
#

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Проверка аргументов
if [ $# -lt 1 ]; then
  echo -e "${RED}Ошибка: Не указан файл APK или директория${NC}"
  echo "Использование: $0 <apk_file|manifest_dir> [output_file]"
  exit 1
fi

INPUT="$1"
OUTPUT_FILE="${2:-manifest_analysis_report.txt}"
TEMP_MANIFEST=""

# Функция очистки
cleanup() {
  if [ -n "$TEMP_MANIFEST" ] && [ -f "$TEMP_MANIFEST" ]; then
    rm -f "$TEMP_MANIFEST"
  fi
}
trap cleanup EXIT

# Определение типа входа и извлечение AndroidManifest.xml
if [[ "$INPUT" == *.apk ]]; then
  echo -e "${BLUE}📦 Извлечение AndroidManifest.xml из APK...${NC}"
  TEMP_MANIFEST=$(mktemp)
  unzip -p "$INPUT" AndroidManifest.xml >"$TEMP_MANIFEST" 2>/dev/null || {
    # Если не удалось извлечь напрямую, используем apktool
    echo -e "${YELLOW}Прямое извлечение не удалось, используем apktool...${NC}"
    TEMP_DIR=$(mktemp -d)
    apktool d "$INPUT" -o "$TEMP_DIR" -f >/dev/null 2>&1
    if [ -f "${TEMP_DIR}/AndroidManifest.xml" ]; then
      cp "${TEMP_DIR}/AndroidManifest.xml" "$TEMP_MANIFEST"
    else
      echo -e "${RED}✗ Не удалось извлечь AndroidManifest.xml${NC}"
      exit 1
    fi
    rm -rf "$TEMP_DIR"
  }
  MANIFEST="$TEMP_MANIFEST"
  APK_FILE="$INPUT"
elif [ -d "$INPUT" ]; then
  # Ищем AndroidManifest.xml в директории
  if [ -f "${INPUT}/AndroidManifest.xml" ]; then
    MANIFEST="${INPUT}/AndroidManifest.xml"
  elif [ -f "${INPUT}_decompiled/AndroidManifest.xml" ]; then
    MANIFEST="${INPUT}_decompiled/AndroidManifest.xml"
  else
    echo -e "${RED}✗ AndroidManifest.xml не найден в директории${NC}"
    exit 1
  fi
elif [ -f "$INPUT" ] && [[ "$(basename "$INPUT")" == "AndroidManifest.xml" ]]; then
  MANIFEST="$INPUT"
else
  echo -e "${RED}✗ Неверный формат входа${NC}"
  exit 1
fi

# Проверка файла
if [ ! -f "$MANIFEST" ] || [ ! -s "$MANIFEST" ]; then
  echo -e "${RED}✗ Файл AndroidManifest.xml пуст или не найден${NC}"
  exit 1
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Анализ AndroidManifest.xml                       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Инициализация отчёта
cat >"$OUTPUT_FILE" <<HEADER
================================================================================
ОТЧЁТ ОБ АНАЛИЗЕ AndroidManifest.xml
Файл: $MANIFEST
Дата: $(date)
================================================================================

HEADER

# Функция для подсчёта
count_pattern() {
  grep -c "$1" "$MANIFEST" 2>/dev/null || echo "0"
}

# Функция для поиска и вывода
find_pattern() {
  grep "$1" "$MANIFEST" 2>/dev/null || echo "Не найдено"
}

# 1. Основная информация
echo -e "${MAGENTA}━━━ 1. Основная информация ━━━${NC}"
echo "" >>"$OUTPUT_FILE"
echo "## Основная информация" >>"$OUTPUT_FILE"
echo ""

# Package name
PACKAGE=$(grep -oP 'package="\K[^"]+' "$MANIFEST" 2>/dev/null | head -1)
if [ -n "$PACKAGE" ]; then
  echo -e "${CYAN}Package name:${NC} $PACKAGE"
  echo "Package: $PACKAGE" >>"$OUTPUT_FILE"
else
  echo -e "${CYAN}Package name:${NC} Не определён"
  echo "Package: Не определён" >>"$OUTPUT_FILE"
fi

# Version info
VERSION_CODE=$(grep -oP 'versionCode="\K[^"]+' "$MANIFEST" 2>/dev/null | head -1)
VERSION_NAME=$(grep -oP 'versionName="\K[^"]+' "$MANIFEST" 2>/dev/null | head -1)
echo -e "${CYAN}Version Code:${NC} ${VERSION_CODE:-N/A}"
echo -e "${CYAN}Version Name:${NC} ${VERSION_NAME:-N/A}"
echo "Version Code: ${VERSION_CODE:-N/A}" >>"$OUTPUT_FILE"
echo "Version Name: ${VERSION_NAME:-N/A}" >>"$OUTPUT_FILE"

# SDK versions
MIN_SDK=$(grep -oP 'minSdkVersion="\K[^"]+' "$MANIFEST" 2>/dev/null | head -1)
TARGET_SDK=$(grep -oP 'targetSdkVersion="\K[^"]+' "$MANIFEST" 2>/dev/null | head -1)
echo -e "${CYAN}Min SDK:${NC} ${MIN_SDK:-N/A}"
echo -e "${CYAN}Target SDK:${NC} ${TARGET_SDK:-N/A}"
echo "Min SDK: ${MIN_SDK:-N/A}" >>"$OUTPUT_FILE"
echo "Target SDK: ${TARGET_SDK:-N/A}" >>"$OUTPUT_FILE"

echo ""

# 2. Разрешения
echo -e "${MAGENTA}━━━ 2. Разрешения ━━━${NC}"
echo "" >>"$OUTPUT_FILE"
echo "## Разрешения" >>"$OUTPUT_FILE"
echo ""

TOTAL_PERMS=$(count_pattern '<uses-permission')
echo -e "${CYAN}Всего разрешений:${NC} $TOTAL_PERMS"
echo "Всего разрешений: $TOTAL_PERMS" >>"$OUTPUT_FILE"
echo "" >>"$OUTPUT_FILE"

# Bluetooth разрешения
echo -e "${YELLOW}📡 Bluetooth-разрешения:${NC}"
echo "### Bluetooth-разрешения" >>"$OUTPUT_FILE"
echo ""

BT_PERMS=$(find_pattern -i 'bluetooth')
if [ "$BT_PERMS" != "Не найдено" ]; then
  echo "$BT_PERMS"
  echo "$BT_PERMS" >>"$OUTPUT_FILE"
  echo -e "${GREEN}   ✓ Найдено${NC}"
else
  echo -e "${YELLOW}   ⚠ Не найдено${NC}"
  echo "Не найдено" >>"$OUTPUT_FILE"
fi
echo "" >>"$OUTPUT_FILE"

# Опасные разрешения
echo -e "${YELLOW}⚠️  Разрешения высокого риска:${NC}"
echo "### Разрешения высокого риска" >>"$OUTPUT_FILE"
echo ""

DANGEROUS_PERMS=(
  "ACCESS_FINE_LOCATION"
  "ACCESS_COARSE_LOCATION"
  "READ_CONTACTS"
  "WRITE_CONTACTS"
  "READ_SMS"
  "WRITE_SMS"
  "RECEIVE_SMS"
  "READ_CALL_LOG"
  "WRITE_CALL_LOG"
  "CAMERA"
  "RECORD_AUDIO"
  "READ_EXTERNAL_STORAGE"
  "WRITE_EXTERNAL_STORAGE"
  "READ_PHONE_STATE"
  "SYSTEM_ALERT_WINDOW"
  "BIND_ACCESSIBILITY_SERVICE"
  "PACKAGE_USAGE_STATS"
)

for perm in "${DANGEROUS_PERMS[@]}"; do
  found=$(find_pattern "$perm")
  if [ "$found" != "Не найдено" ]; then
    echo -e "${RED}   • $perm${NC}"
    echo "• $perm" >>"$OUTPUT_FILE"
  fi
done
echo "" >>"$OUTPUT_FILE"

# Все разрешения
echo -e "${CYAN}📋 Полный список разрешений:${NC}"
echo "### Все разрешения" >>"$OUTPUT_FILE"
echo ""
find_pattern '<uses-permission' | sed 's/.*android:name="/  • /g' | sed 's/".*//g'
find_pattern '<uses-permission' >>"$OUTPUT_FILE"
echo "" >>"$OUTPUT_FILE"

# 3. Компоненты приложения
echo -e "${MAGENTA}━━━ 3. Компоненты приложения ━━━${NC}"
echo "" >>"$OUTPUT_FILE"
echo "## Компоненты приложения" >>"$OUTPUT_FILE"
echo ""

# Activity
ACTIVITY_COUNT=$(count_pattern '<activity')
echo -e "${CYAN}Activity:${NC} $ACTIVITY_COUNT"
echo "Activity: $ACTIVITY_COUNT" >>"$OUTPUT_FILE"
echo "" >>"$OUTPUT_FILE"
echo "#### Activity:" >>"$OUTPUT_FILE"
find_pattern '<activity[^>]*android:name=' | grep -oP 'android:name="\K[^"]+' | while read -r name; do
  echo "  • $name"
  echo "  • $name" >>"$OUTPUT_FILE"
done
echo ""

# Service
SERVICE_COUNT=$(count_pattern '<service')
echo -e "${CYAN}Service:${NC} $SERVICE_COUNT"
echo "Service: $SERVICE_COUNT" >>"$OUTPUT_FILE"
echo "" >>"$OUTPUT_FILE"
echo "#### Services:" >>"$OUTPUT_FILE"
find_pattern '<service[^>]*android:name=' | grep -oP 'android:name="\K[^"]+' | while read -r name; do
  echo "  • $name"
  echo "  • $name" >>"$OUTPUT_FILE"
done
echo ""

# Receiver
RECEIVER_COUNT=$(count_pattern '<receiver')
echo -e "${CYAN}Receiver:${NC} $RECEIVER_COUNT"
echo "Receiver: $RECEIVER_COUNT" >>"$OUTPUT_FILE"
echo "" >>"$OUTPUT_FILE"
echo "#### Receivers:" >>"$OUTPUT_FILE"
find_pattern '<receiver[^>]*android:name=' | grep -oP 'android:name="\K[^"]+' | while read -r name; do
  echo "  • $name"
  echo "  • $name" >>"$OUTPUT_FILE"
done
echo ""

# Provider
PROVIDER_COUNT=$(count_pattern '<provider')
echo -e "${CYAN}Provider:${NC} $PROVIDER_COUNT"
echo "Provider: $PROVIDER_COUNT" >>"$OUTPUT_FILE"
echo "" >>"$OUTPUT_FILE"
echo "#### Providers:" >>"$OUTPUT_FILE"
find_pattern '<provider[^>]*android:name=' | grep -oP 'android:name="\K[^"]+' | while read -r name; do
  echo "  • $name"
  echo "  • $name" >>"$OUTPUT_FILE"
done
echo ""

# 4. Intent Filters
echo -e "${MAGENTA}━━━ 4. Intent Filters ━━━${NC}"
echo "" >>"$OUTPUT_FILE"
echo "## Intent Filters" >>"$OUTPUT_FILE"
echo ""

echo -e "${CYAN}📋 Action:${NC}"
echo "### Actions" >>"$OUTPUT_FILE"
echo ""
find_pattern '<action android:name=' | grep -oP 'android:name="\K[^"]+' | sort -u | while read -r action; do
  echo "  • $action"
  echo "  • $action" >>"$OUTPUT_FILE"
done
echo ""

echo -e "${CYAN}📋 Category:${NC}"
echo "### Categories" >>"$OUTPUT_FILE"
echo ""
find_pattern '<category android:name=' | grep -oP 'android:name="\K[^"]+' | sort -u | while read -r category; do
  echo "  • $category"
  echo "  • $category" >>"$OUTPUT_FILE"
done
echo ""

# 5. Специфичные для Bluetooth компоненты
echo -e "${MAGENTA}━━━ 5. Bluetooth-специфичные компоненты ━━━${NC}"
echo "" >>"$OUTPUT_FILE"
echo "## Bluetooth-компоненты" >>"$OUTPUT_FILE"
echo ""

echo -e "${CYAN}📡 Bluetooth в компонентах:${NC}"
echo "### Bluetooth в названиях компонентов" >>"$OUTPUT_FILE"
echo ""
bt_components=$(grep -i 'bluetooth\|ble\|gatt\|serial' "$MANIFEST" | grep -oP 'android:name="\K[^"]+' | sort -u)
if [ -n "$bt_components" ]; then
  echo "$bt_components" | while read -r comp; do
    echo "  • $comp"
    echo "  • $comp" >>"$OUTPUT_FILE"
  done
  echo -e "${GREEN}   ✓ Найдено${NC}"
else
  echo -e "${YELLOW}   ⚠ Не найдено${NC}"
  echo "Не найдено" >>"$OUTPUT_FILE"
fi
echo "" >>"$OUTPUT_FILE"

# 6. Анализ приложений-спутников
echo -e "${MAGENTA}━━━ 6. Связанные приложения ━━━${NC}"
echo "" >>"$OUTPUT_FILE"
echo "## Связанные приложения" >>"$OUTPUT_FILE"
echo ""

echo -e "${CYAN}📋 Uses-library:${NC}"
echo "### Uses-library" >>"$OUTPUT_FILE"
find_pattern '<uses-library' | grep -oP 'android:name="\K[^"]+' | while read -r lib; do
  echo "  • $lib"
  echo "  • $lib" >>"$OUTPUT_FILE"
done
echo ""

echo -e "${CYAN}📋 Queries (Android 11+):${NC}"
echo "### Queries" >>"$OUTPUT_FILE"
find_pattern '<package android:name=' | grep -oP 'android:name="\K[^"]+' | while read -r pkg; do
  echo "  • $pkg"
  echo "  • $pkg" >>"$OUTPUT_FILE"
done
echo ""

# Итоги
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Анализ завершён!${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Отчёт сохранён: ${OUTPUT_FILE}${NC}"
echo ""

# Добавляем сводку в отчёт
cat >>"$OUTPUT_FILE" <<FOOTER

================================================================================
СВОДКА
================================================================================
Package: ${PACKAGE:-N/A}
Version: ${VERSION_NAME:-N/A} (${VERSION_CODE:-N/A})
Min SDK: ${MIN_SDK:-N/A} | Target SDK: ${TARGET_SDK:-N/A}

Компоненты:
  Activity: $ACTIVITY_COUNT
  Service: $SERVICE_COUNT
  Receiver: $RECEIVER_COUNT
  Provider: $PROVIDER_COUNT

Разрешения:
  Всего: $TOTAL_PERMS
  Bluetooth: $(echo "$BT_PERMS" | grep -c '.' 2>/dev/null || echo 0)

================================================================================
КОНЕЦ ОТЧЁТА
================================================================================
FOOTER
