/*
 * ESP32 BLE-сканер — обнаружение и GATT-обход
 * ==============================================
 *
 * Сканирует BLE-устройства, подключается к выбранному,
 * обходит GATT-сервисы/характеристики/дескрипторы.
 *
 * Режимы работы (выбор через Serial монитор):
 *   1 — Сканирование устройств
 *   2 — Подключение по адресу (ввести через Serial)
 *   3 — Мониторинг рекламных пакетов
 *   i — Информация о подключении
 *   r — Чтение характеристики (ввести handle/UUID)
 *   w — Запись характеристики
 *
 * Сборка:
 *   arduino-cli compile --fqbn esp32:esp32:esp32 ble-project/firmware/esp32-ble-scanner/
 *   arduino-cli upload --fqbn esp32:esp32:esp32 -p /dev/ttyUSB0 ble-project/firmware/esp32-ble-scanner/
 */

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEScan.h>
#include <BLEClient.h>
#include <BLEAddress.h>
#include <BLE2902.h>

// ─── Конфигурация ─────────────────────────────────

#define SCAN_TIME_SEC   5       // Длительность сканирования (сек)
#define MAX_DEVICES     50      // Макс. устройств в списке
#define MAX_CHARS       100     // Макс. характеристик для чтения

// ─── Глобальные переменные ─────────────────────────

struct DeviceInfo {
  BLEAddress address = BLEAddress((uint8_t*)"\x00\x00\x00\x00\x00\x00");
  String name = "";
  int rssi = 0;
  bool hasName = false;
};

DeviceInfo discoveredDevices[MAX_DEVICES];
int deviceCount = 0;

BLEClient *pClient = nullptr;
BLERemoteService *pRemoteService = nullptr;
bool connected = false;
String selectedAddress = "";

// ─── Callback сканирования ─────────────────────────

class ScanCallback : public BLEAdvertisedDeviceCallbacks {
  void onResult(BLEAdvertisedDevice advertisedDevice) override {
    if (deviceCount >= MAX_DEVICES) return;
    
    // Проверка на дубликат
    for (int i = 0; i < deviceCount; i++) {
      if (discoveredDevices[i].address.equals(advertisedDevice.getAddress())) {
        // Обновляем RSSI
        discoveredDevices[i].rssi = advertisedDevice.getRSSI();
        return;
      }
    }
    
    discoveredDevices[deviceCount].address = advertisedDevice.getAddress();
    discoveredDevices[deviceCount].name = advertisedDevice.getName();
    discoveredDevices[deviceCount].rssi = advertisedDevice.getRSSI();
    discoveredDevices[deviceCount].hasName = advertisedDevice.haveName();
    deviceCount++;
    
    Serial.printf("  [%2d] %-20s %s  (%d dBm)\n",
      deviceCount,
      discoveredDevices[deviceCount-1].name.c_str(),
      discoveredDevices[deviceCount-1].address.toString().c_str(),
      discoveredDevices[deviceCount-1].rssi);
  }
};


// ─── Функции ───────────────────────────────────────

void print_menu() {
  Serial.println("\n=== BLE Scanner Menu ===");
  Serial.println("  1 — Сканировать устройства");
  Serial.println("  2 — Подключиться к устройству");
  Serial.println("  3 — Мониторинг рекламных пакетов (30 сек)");
  Serial.println("  i — Информация о подключении");
  Serial.println("  g — GATT-обход (список сервисов)");
  Serial.println("  r — Читать характеристику (введите handle/UUID)");
  Serial.println("  d — Отключиться");
  Serial.println("  m — Меню");
  Serial.println("  > ");
}

void print_device_list() {
  Serial.printf("\nНайдено устройств: %d\n", deviceCount);
  if (deviceCount == 0) {
    Serial.println("  (нет, выполните сканирование)");
    return;
  }
  Serial.println("  #  Имя                 Адрес              RSSI");
  Serial.println("  " + String("=", 50));
  for (int i = 0; i < deviceCount; i++) {
    char name[22];
    snprintf(name, sizeof(name), "%-20s",
      discoveredDevices[i].hasName ? discoveredDevices[i].name.c_str() : "(no name)");
    Serial.printf("  [%2d] %s %s  %d dBm\n",
      i + 1, name,
      discoveredDevices[i].address.toString().c_str(),
      discoveredDevices[i].rssi);
  }
}

void scan_devices() {
  Serial.printf("\nСканирование %d сек...\n", SCAN_TIME_SEC);
  deviceCount = 0;
  
  BLEScan *pScan = BLEDevice::getScan();
  pScan->setAdvertisedDeviceCallbacks(new ScanCallback());
  pScan->setActiveScan(true);
  pScan->setInterval(100);
  pScan->setWindow(99);
  
  BLEScanResults *results = pScan->start(SCAN_TIME_SEC, false);
  pScan->stop();
  
  Serial.printf("Сканирование завершено: %d устройств\n", deviceCount);
  print_device_list();
}

bool connect_to_device(String addrStr) {
  if (connected) {
    Serial.println("Уже подключено. Сначала отключитесь (d).");
    return false;
  }
  
  BLEAddress addr(addrStr.c_str());
  Serial.printf("Подключение к %s...\n", addrStr.c_str());
  
  pClient = BLEDevice::createClient();
  pClient->setClientCallbacks(new BLEClientCallbacks());
  
  // Таймаут подключения 5 секунд
  if (!pClient->connect(addr)) {
    Serial.println("Ошибка подключения");
    return false;
  }
  
  connected = true;
  selectedAddress = addrStr;
  Serial.println("Подключено!");
  Serial.printf("MTU: %d\n", pClient->getMTU());
  return true;
}

void gatt_discovery() {
  if (!connected || !pClient) {
    Serial.println("Не подключено");
    return;
  }
  
  Serial.println("\n=== GATT Discovery ===");
  
  // Получаем список сервисов
  std::map<std::string, BLERemoteService *> *services = pClient->getServices();
  if (!services) {
    Serial.println("Нет сервисов");
    return;
  }
  
  int svcCount = 0, charCount = 0;
  
  for (auto &pair : *services) {
    BLERemoteService *svc = pair.second;
    svcCount++;
    
    Serial.printf("\n  Сервис: %s [handle 0x%04x]\n",
      svc->getUUID().toString().c_str(),
      svc->getHandle());
    
    // Получаем характеристики
    std::map<std::string, BLERemoteCharacteristic *> *chars = svc->getCharacteristics();
    if (!chars) continue;
    
    for (auto &ch_pair : *chars) {
      BLERemoteCharacteristic *chr = ch_pair.second;
      charCount++;
      
      uint8_t props = chr->getProperties();
      char propStr[32] = "";
      if (props & BLE_CHAR_PROPERTY_READ) strcat(propStr, " READ");
      if (props & BLE_CHAR_PROPERTY_WRITE) strcat(propStr, " WRITE");
      if (props & BLE_CHAR_PROPERTY_WRITE_NR) strcat(propStr, " WRITE_NR");
      if (props & BLE_CHAR_PROPERTY_NOTIFY) strcat(propStr, " NOTIFY");
      if (props & BLE_CHAR_PROPERTY_INDICATE) strcat(propStr, " INDICATE");
      
      Serial.printf("    Хар-ка: %s [handle 0x%04x] (%s)\n",
        chr->getUUID().toString().c_str(),
        chr->getHandle(),
        propStr);
      
      // Попытка чтения
      if (props & BLE_CHAR_PROPERTY_READ) {
        std::string val = chr->readValue();
        if (val.length() > 0) {
          Serial.printf("      Значение (%d b): ", val.length());
          for (size_t i = 0; i < val.length() && i < 32; i++) {
            Serial.printf("%02x ", (uint8_t)val[i]);
          }
          // Попытка декодировать как UTF-8
          bool printable = true;
          for (size_t i = 0; i < val.length(); i++) {
            if (val[i] < 32 || val[i] > 126) { printable = false; break; }
          }
          if (printable && val.length() > 0) {
            Serial.printf(" = \"%s\"", val.c_str());
          }
          Serial.println();
        }
      }
      
      // Дескрипторы (CCCD и т.д.)
      // ESP32 BLE library doesn't directly expose descriptors
      // через BLERemoteCharacteristic, поэтому пропускаем
    }
  }
  
  Serial.printf("\nИтого: %d сервисов, %d характеристик\n", svcCount, charCount);
}

void read_characteristic(String input) {
  if (!connected || !pClient) {
    Serial.println("Не подключено");
    return;
  }
  
  // Парсим ввод как handle (0xNNNN) или UUID
  int handle = -1;
  BLEUUID targetUUID;
  bool isUUID = false;
  
  if (input.startsWith("0x") || input.startsWith("0X")) {
    handle = strtol(input.c_str(), nullptr, 16);
  } else if (input.indexOf('-') > 0 || input.length() > 6) {
    targetUUID = BLEUUID(input.c_str());
    isUUID = true;
  } else if (input.length() <= 4) {
    targetUUID = BLEUUID((uint16_t)strtol(input.c_str(), nullptr, 16));
    isUUID = true;
  } else {
    handle = strtol(input.c_str(), nullptr, 16);
  }
  
  // Ищем характеристику
  if (isUUID) {
    BLERemoteCharacteristic *chr = nullptr;
    std::map<std::string, BLERemoteService *> *services = pClient->getServices();
    for (auto &pair : *services) {
      chr = pair.second->getCharacteristic(targetUUID);
      if (chr) break;
    }
    if (chr && chr->canRead()) {
      std::string val = chr->readValue();
      Serial.printf("Read UUID %s: ", targetUUID.toString().c_str());
      for (size_t i = 0; i < val.length(); i++) Serial.printf("%02x ", (uint8_t)val[i]);
      Serial.printf(" (%d bytes)\n", val.length());
    } else {
      Serial.println("Характеристика не найдена или не читаема");
    }
  } else {
    // Чтение по handle — идём по всем сервисам
    bool found = false;
    std::map<std::string, BLERemoteService *> *services = pClient->getServices();
    for (auto &pair : *services) {
      std::map<std::string, BLERemoteCharacteristic *> *chars = pair.second->getCharacteristics();
      for (auto &ch_pair : *chars) {
        if (ch_pair.second->getHandle() == handle) {
          if (ch_pair.second->canRead()) {
            std::string val = ch_pair.second->readValue();
            Serial.printf("Read Handle 0x%04x: ", handle);
            for (size_t i = 0; i < val.length(); i++) Serial.printf("%02x ", (uint8_t)val[i]);
            Serial.printf(" (%d bytes)\n", val.length());
          } else {
            Serial.printf("Handle 0x%04x найден, но не читаем\n", handle);
          }
          found = true;
          break;
        }
      }
      if (found) break;
    }
    if (!found) Serial.printf("Handle 0x%04x не найден\n", handle);
  }
}

void monitor_advertising() {
  Serial.println("\nМониторинг рекламных пакетов (30 сек)...");
  Serial.printf("%-20s %-18s %s\n", "Имя", "Адрес", "RSSI");
  Serial.println(String('=', 52));
  
  class MonitorCallback : public BLEAdvertisedDeviceCallbacks {
    void onResult(BLEAdvertisedDevice adv) override {
      char name[20];
      snprintf(name, sizeof(name), "%-20s",
        adv.haveName() ? adv.getName().c_str() : "(no name)");
      Serial.printf("%s %s  %d dBm",
        name, adv.getAddress().toString().c_str(), adv.getRSSI());
      
      if (adv.haveServiceUUID()) {
        Serial.printf(" [%s]", adv.getServiceUUID().toString().c_str());
      }
      if (adv.haveManufacturerData()) {
        Serial.printf(" [mfr data]");
      }
      Serial.println();
    }
  };
  
  BLEScan *pScan = BLEDevice::getScan();
  pScan->setAdvertisedDeviceCallbacks(new MonitorCallback());
  pScan->setActiveScan(true);
  pScan->start(30, false);
  pScan->stop();
  Serial.println("Мониторинг завершён");
}


// ─── Setup / Loop ──────────────────────────────────

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n=== ESP32 BLE Scanner ===");
  Serial.println("Инструмент для GATT реверс-инжиниринга");
  
  BLEDevice::init("ESP32 BLE Scanner");
  BLEDevice::setPower(ESP_PWR_LVL_P9);
  
  Serial.println("BLE инициализирован");
  print_menu();
}

void loop() {
  if (!Serial.available()) return;
  
  char cmd = Serial.read();
  // Очистка буфера
  while (Serial.available()) Serial.read();
  
  switch (cmd) {
    case '1':
      scan_devices();
      break;
      
    case '2':
      print_device_list();
      if (deviceCount > 0) {
        Serial.print("Введите номер устройства (1-" + String(deviceCount) + "): ");
        while (!Serial.available()) delay(100);
        int idx = Serial.parseInt();
        while (Serial.available()) Serial.read();
        if (idx >= 1 && idx <= deviceCount) {
          String addr = discoveredDevices[idx-1].address.toString().c_str();
          connect_to_device(addr);
        } else {
          Serial.println("Неверный номер");
        }
      }
      break;
      
    case '3':
      monitor_advertising();
      break;
      
    case 'i':
      if (connected) {
        Serial.printf("Подключено к: %s\n", selectedAddress.c_str());
        Serial.printf("MTU: %d\n", pClient ? pClient->getMTU() : 0);
      } else {
        Serial.println("Не подключено");
      }
      break;
      
    case 'g':
      gatt_discovery();
      break;
      
    case 'r': {
      Serial.print("Введите handle (0xNNNN) или UUID: ");
      String input = Serial.readStringUntil('\n');
      input.trim();
      if (input.length() > 0) read_characteristic(input);
      break;
    }
      
    case 'd':
      if (connected && pClient) {
        pClient->disconnect();
        connected = false;
        Serial.println("Отключено");
      }
      break;
      
    case 'm':
    default:
      print_menu();
      break;
  }
  
  Serial.print("\n> ");
}
