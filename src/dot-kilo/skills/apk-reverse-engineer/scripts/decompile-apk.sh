#!/bin/bash
#
# Скрипт декомпиляции APK файлов
# Использование: ./decompile-apk.sh <apk_file> [output_dir]
#

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Проверка аргументов
if [ $# -lt 1 ]; then
    echo -e "${RED}Ошибка: Не указан APK файл${NC}"
    echo "Использование: $0 <apk_file> [output_dir]"
    exit 1
fi

APK_FILE="$1"
OUTPUT_DIR="${2:-$(basename "$APK_FILE" .apk)}"

# Проверка существования файла
if [ ! -f "$APK_FILE" ]; then
    echo -e "${RED}Ошибка: Файл не найден: $APK_FILE${NC}"
    exit 1
fi

# Проверка необходимых инструментов
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Ошибка: $1 не найден. Установите: $2${NC}"
        exit 1
    fi
}

echo -e "${BLUE}=== Проверка инструментов ===${NC}"
check_tool "apktool" "sudo apt-get install apktool"
check_tool "jadx" "sudo apt-get install jadx"
check_tool "unzip" "sudo apt-get install unzip"
check_tool "strings" "sudo apt-get install binutils"
echo -e "${GREEN}✓ Все инструменты найдены${NC}"

# Создание директорий
DECOMPILED_DIR="${OUTPUT_DIR}_decompiled"
JAVA_DIR="${OUTPUT_DIR}_java"
ANALYSIS_DIR="${OUTPUT_DIR}_analysis"

echo -e "${BLUE}=== Создание директорий ===${NC}"
mkdir -p "$DECOMPILED_DIR" "$JAVA_DIR" "$ANALYSIS_DIR"
echo -e "${GREEN}✓ Директории созданы${NC}"

# Шаг 1: Базовая информация
echo -e "${BLUE}=== Шаг 1: Базовая информация об APK ===${NC}"
echo -e "${YELLOW}Размер файла:${NC}"
ls -lh "$APK_FILE" | awk '{print $5}'

echo -e "${YELLOW}Содержимое APK:${NC}"
unzip -l "$APK_FILE" | head -30

echo -e "${YELLOW}Информация через aapt:${NC}"
if command -v aapt &> /dev/null; then
    aapt dump badging "$APK_FILE" 2>/dev/null | head -20
elif command -v aapt2 &> /dev/null; then
    aapt2 dump badging "$APK_FILE" 2>/dev/null | head -20
else
    echo "aapt/aapt2 не найден, пропускаем..."
fi

# Шаг 2: Декомпиляция через apktool
echo -e "${BLUE}=== Шаг 2: Декомпиляция через apktool ===${NC}"
echo -e "${YELLOW}Декомпиляция ресурсов и Smali...${NC}"
apktool d "$APK_FILE" -o "$DECOMPILED_DIR" -f

if [ -f "${DECOMPILED_DIR}/AndroidManifest.xml" ]; then
    echo -e "${GREEN}✓ AndroidManifest.xml извлечён${NC}"
else
    echo -e "${RED}✗ Не удалось извлечь AndroidManifest.xml${NC}"
fi

# Шаг 3: Декомпиляция в Java через jadx
echo -e "${BLUE}=== Шаг 3: Декомпиляция в Java через jadx ===${NC}"
echo -e "${YELLOW}Конвертация в Java исходники...${NC}"
jadx -d "$JAVA_DIR" -j "$(nproc)" --no-fs --no-debuginfo "$APK_FILE" 2>&1 | tail -5

if [ -d "${JAVA_DIR}/sources" ] || [ "$(ls -A $JAVA_DIR/*.java 2>/dev/null)" ]; then
    echo -e "${GREEN}✓ Java файлы декомпилированы${NC}"
else
    echo -e "${YELLOW}⚠ Возможно, jadx не нашёл Java файлы${NC}"
fi

# Шаг 4: Извлечение строк
echo -e "${BLUE}=== Шаг 4: Извлечение строк ===${NC}"
strings "$APK_FILE" > "${ANALYSIS_DIR}/strings_all.txt"
echo -e "${GREEN}✓ Все строки сохранены в ${ANALYSIS_DIR}/strings_all.txt${NC}"

# Поиск интересных строк
echo -e "${YELLOW}Поиск URL...${NC}"
strings "$APK_FILE" | grep -oE "https?://[a-zA-Z0-9./_-]+" | sort -u > "${ANALYSIS_DIR}/urls.txt" || true

echo -e "${YELLOW}Поиск IP-адресов...${NC}"
strings "$APK_FILE" | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sort -u > "${ANALYSIS_DIR}/ips.txt" || true

echo -e "${YELLOW}Поиск Bluetooth-строк...${NC}"
strings "$APK_FILE" | grep -iE "bluetooth|ble|gatt|uuid" > "${ANALYSIS_DIR}/bluetooth_strings.txt" || true

# Шаг 5: Быстрый анализ AndroidManifest.xml
echo -e "${BLUE}=== Шаг 5: Анализ AndroidManifest.xml ===${NC}"
if [ -f "${DECOMPILED_DIR}/AndroidManifest.xml" ]; then
    echo -e "${YELLOW}Разрешения:${NC}"
    grep "<uses-permission" "${DECOMPILED_DIR}/AndroidManifest.xml" | head -20
    
    echo -e "${YELLOW}Bluetooth-разрешения:${NC}"
    grep -i "bluetooth" "${DECOMPILED_DIR}/AndroidManifest.xml" || echo "Не найдено"
    
    echo -e "${YELLOW}Компоненты (Activity, Service):${NC}"
    grep -c "<activity" "${DECOMPILED_DIR}/AndroidManifest.xml" | xargs -I {} echo "Activity: {}"
    grep -c "<service" "${DECOMPILED_DIR}/AndroidManifest.xml" | xargs -I {} echo "Service: {}"
    grep -c "<receiver" "${DECOMPILED_DIR}/AndroidManifest.xml" | xargs -I {} echo "Receiver: {}"
fi

# Итоги
echo -e "${BLUE}=================================${NC}"
echo -e "${GREEN}✓ Декомпиляция завершена!${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""
echo -e "${YELLOW}Результаты:${NC}"
echo "  Декомпилированные ресурсы: ${DECOMPILED_DIR}/"
echo "  Java исходники: ${JAVA_DIR}/"
echo "  Анализ строк: ${ANALYSIS_DIR}/"
echo ""
echo -e "${YELLOW}Следующие шаги:${NC}"
echo "  1. Изучите AndroidManifest.xml"
echo "  2. Ищите Bluetooth-код: grep -r 'Bluetooth' ${JAVA_DIR}/"
echo "  3. Проверьте найденные UUID"
echo ""
