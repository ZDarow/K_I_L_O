#!/bin/bash
#
# Скрипт поиска Bluetooth-кода в декомпилированном APK
# Использование: ./search-bluetooth.sh <decompiled_dir>
#

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Проверка аргументов
if [ $# -lt 1 ]; then
  echo -e "${RED}Ошибка: Не указана директория${NC}"
  echo "Использование: $0 <decompiled_dir> [output_file]"
  exit 1
fi

SEARCH_DIR="$1"
OUTPUT_FILE="${2:-bluetooth_analysis_report.txt}"

# Проверка существования директории
if [ ! -d "$SEARCH_DIR" ]; then
  echo -e "${RED}Ошибка: Директория не найдена: $SEARCH_DIR${NC}"
  exit 1
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Поиск Bluetooth-кода в декомпилированном APK        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Инициализация отчёта
cat >"$OUTPUT_FILE" <<HEADER
================================================================================
ОТЧЁТ ОБ АНАЛИЗЕ BLUETOOTH-КОДА
Директория: $SEARCH_DIR
Дата: $(date)
================================================================================

HEADER

# Функция для поиска и записи результатов
search_and_report() {
  local description="$1"
  local pattern="$2"
  local dir="$3"
  local file_pattern="${4:-*}"

  echo -e "${CYAN}📋 $description${NC}"
  echo "" >>"$OUTPUT_FILE"
  echo "=== $description ===" >>"$OUTPUT_FILE"

  if [ -d "$dir" ]; then
    local results=$(grep -r "$pattern" "$dir" --include="$file_pattern" 2>/dev/null | head -50)
    if [ -n "$results" ]; then
      echo "$results" >>"$OUTPUT_FILE"
      echo -e "${GREEN}   ✓ Найдено совпадений: $(echo "$results" | wc -l)${NC}"
    else
      echo "Не найдено" >>"$OUTPUT_FILE"
      echo -e "${YELLOW}   ⚠ Не найдено${NC}"
    fi
  else
    echo "Директория не найдена: $dir" >>"$OUTPUT_FILE"
    echo -e "${RED}   ✗ Директория не найдена${NC}"
  fi
  echo ""
}

# Определяем директории
JAVA_DIR="$SEARCH_DIR"
if [ -d "${SEARCH_DIR}_java" ]; then
  JAVA_DIR="${SEARCH_DIR}_java"
fi

DECOMPILED_DIR="$SEARCH_DIR"
if [ -d "${SEARCH_DIR}_decompiled" ]; then
  DECOMPILED_DIR="${SEARCH_DIR}_decompiled"
fi

echo -e "${BLUE}=== Поиск в Java файлах ===${NC}"
echo "Директория Java: $JAVA_DIR" >>"$OUTPUT_FILE"
echo ""

# Classic Bluetooth
echo -e "${YELLOW}━━━ Classic Bluetooth ━━━${NC}"
echo "" >>"$OUTPUT_FILE"
echo "## Classic Bluetooth" >>"$OUTPUT_FILE"
echo ""

search_and_report "BluetoothAdapter" "BluetoothAdapter" "$JAVA_DIR" "*.java"
search_and_report "BluetoothDevice" "BluetoothDevice" "$JAVA_DIR" "*.java"
search_and_report "BluetoothSocket" "BluetoothSocket" "$JAVA_DIR" "*.java"
search_and_report "BluetoothServerSocket" "BluetoothServerSocket" "$JAVA_DIR" "*.java"
search_and_report "BluetoothProfile" "BluetoothProfile" "$JAVA_DIR" "*.java"
search_and_report "createRfcommSocket" "createRfcommSocket" "$JAVA_DIR" "*.java"

# Bluetooth Low Energy
echo -e "${YELLOW}━━━ Bluetooth Low Energy (BLE) ━━━${NC}"
echo "" >>"$OUTPUT_FILE"
echo "## Bluetooth Low Energy (BLE)" >>"$OUTPUT_FILE"
echo ""

search_and_report "BluetoothLeScanner" "BluetoothLeScanner" "$JAVA_DIR" "*.java"
search_and_report "ScanCallback" "ScanCallback" "$JAVA_DIR" "*.java"
search_and_report "BluetoothGatt" "BluetoothGatt" "$JAVA_DIR" "*.java"
search_and_report "connectGatt" "connectGatt" "$JAVA_DIR" "*.java"
search_and_report "BluetoothGattCallback" "BluetoothGattCallback" "$JAVA_DIR" "*.java"
search_and_report "BluetoothGattCharacteristic" "BluetoothGattCharacteristic" "$JAVA_DIR" "*.java"
search_and_report "BluetoothGattService" "BluetoothGattService" "$JAVA_DIR" "*.java"
search_and_report "readCharacteristic" "readCharacteristic" "$JAVA_DIR" "*.java"
search_and_report "writeCharacteristic" "writeCharacteristic" "$JAVA_DIR" "*.java"

# UUID
echo -e "${YELLOW}━━━ UUID сервисов и характеристик ━━━${NC}"
echo "" >>"$OUTPUT_FILE"
echo "## UUID" >>"$OUTPUT_FILE"
echo ""

echo -e "${CYAN}📋 Поиск UUID в формате XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX${NC}"
echo "" >>"$OUTPUT_FILE"
echo "### UUID (полный формат)" >>"$OUTPUT_FILE"

if [ -d "$JAVA_DIR" ]; then
  uuid_results=$(grep -roE "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}" "$JAVA_DIR" --include="*.java" 2>/dev/null | sort -u)
  if [ -n "$uuid_results" ]; then
    echo "$uuid_results" >>"$OUTPUT_FILE"
    echo -e "${GREEN}   ✓ Найдено UUID: $(echo "$uuid_results" | wc -l)${NC}"
  else
    echo "Не найдено" >>"$OUTPUT_FILE"
    echo -e "${YELLOW}   ⚠ Не найдено${NC}"
  fi
fi

echo ""
echo -e "${CYAN}📋 Поиск UUID.fromString()${NC}"
search_and_report "UUID.fromString" "UUID.fromString" "$JAVA_DIR" "*.java"

# Поиск в Smali
echo -e "${YELLOW}━━━ Анализ Smali кода ━━━${NC}"
echo "" >>"$OUTPUT_FILE"
echo "## Smali анализ" >>"$OUTPUT_FILE"
echo ""

if [ -d "$DECOMPILED_DIR" ]; then
  echo -e "${CYAN}📋 Bluetooth в Smali${NC}"
  echo "" >>"$OUTPUT_FILE"
  echo "### Bluetooth в Smali" >>"$OUTPUT_FILE"

  smali_results=$(grep -r "bluetooth" "$DECOMPILED_DIR" --include="*.smali" 2>/dev/null | head -30)
  if [ -n "$smali_results" ]; then
    echo "$smali_results" >>"$OUTPUT_FILE"
    echo -e "${GREEN}   ✓ Найдено совпадений: $(echo "$smali_results" | wc -l)${NC}"
  else
    echo "Не найдено" >>"$OUTPUT_FILE"
    echo -e "${YELLOW}   ⚠ Не найдено${NC}"
  fi
fi

# Анализ AndroidManifest.xml
echo -e "${YELLOW}━━━ AndroidManifest.xml ━━━${NC}"
echo "" >>"$OUTPUT_FILE"
echo "## AndroidManifest.xml" >>"$OUTPUT_FILE"
echo ""

MANIFEST="${DECOMPILED_DIR}/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  echo -e "${CYAN}📋 Bluetooth-разрешения${NC}"
  echo "" >>"$OUTPUT_FILE"
  echo "### Bluetooth-разрешения" >>"$OUTPUT_FILE"

  bt_perms=$(grep -i "bluetooth" "$MANIFEST" 2>/dev/null)
  if [ -n "$bt_perms" ]; then
    echo "$bt_perms" >>"$OUTPUT_FILE"
    echo -e "${GREEN}   ✓ Найдено разрешений: $(echo "$bt_perms" | wc -l)${NC}"
  else
    echo "Не найдено" >>"$OUTPUT_FILE"
    echo -e "${YELLOW}   ⚠ Не найдено${NC}"
  fi

  echo ""
  echo -e "${CYAN}📋 Все разрешения${NC}"
  echo "" >>"$OUTPUT_FILE"
  echo "### Все разрешения" >>"$OUTPUT_FILE"

  all_perms=$(grep "<uses-permission" "$MANIFEST" 2>/dev/null)
  if [ -n "$all_perms" ]; then
    echo "$all_perms" >>"$OUTPUT_FILE"
  fi

  echo ""
  echo -e "${CYAN}📋 Сервисы и компоненты${NC}"
  echo "" >>"$OUTPUT_FILE"
  echo "### Компоненты" >>"$OUTPUT_FILE"

  echo "Activity: $(grep -c '<activity' "$MANIFEST" 2>/dev/null || echo 0)" >>"$OUTPUT_FILE"
  echo "Service: $(grep -c '<service' "$MANIFEST" 2>/dev/null || echo 0)" >>"$OUTPUT_FILE"
  echo "Receiver: $(grep -c '<receiver' "$MANIFEST" 2>/dev/null || echo 0)" >>"$OUTPUT_FILE"

  echo -e "${GREEN}   ✓ Анализ завершён${NC}"
else
  echo "AndroidManifest.xml не найден" >>"$OUTPUT_FILE"
  echo -e "${RED}   ✗ AndroidManifest.xml не найден${NC}"
fi

# Итоги
echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Анализ завершён!${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Отчёт сохранён: ${OUTPUT_FILE}${NC}"
echo ""

# Добавляем итоги в отчёт
cat >>"$OUTPUT_FILE" <<FOOTER

================================================================================
КОНЕЦ ОТЧЁТА
================================================================================
FOOTER

echo -e "${CYAN}📊 Краткая сводка:${NC}"
echo "  Classic Bluetooth находок: $(grep -c "BluetoothAdapter\|BluetoothDevice\|BluetoothSocket" "$JAVA_DIR" -r --include="*.java" 2>/dev/null || echo 0)"
echo "  BLE находок: $(grep -c "BluetoothGatt\|BluetoothLeScanner" "$JAVA_DIR" -r --include="*.java" 2>/dev/null || echo 0)"
echo "  UUID найдено: $(grep -roE "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}" "$JAVA_DIR" --include="*.java" 2>/dev/null | wc -l || echo 0)"
