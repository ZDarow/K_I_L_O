/*
 * ESP32 GATT-сервер — пример для реверс-инжиниринга
 * ==================================================
 *
 * Создаёт BLE-устройство с несколькими сервисами:
 *   - Generic Access (0x1800)
 *   - Device Information (0x180A)
 *   - Battery Service (0x180F)
 *   - Кастомный сервис (0xFFE0) для тестирования read/write/notify
 *
 * Совместимость: ESP32 Arduino Core 2.x / 3.x
 * Платформа: ESP32 DevKit v1, ESP32-C3, ESP32-S3
 *
 * Сборка:
 *   arduino-cli compile --fqbn esp32:esp32:esp32 ble-project/firmware/esp32-gatt-server/
 *   arduino-cli upload --fqbn esp32:esp32:esp32 -p /dev/ttyUSB0 ble-project/firmware/esp32-gatt-server/
 *
 * Или через PlatformIO:
 *   pio run -d ble-project/firmware/esp32-gatt-server/ -t upload
 */

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>
#include <BLE2904.h>
#include <Preferences.h>

// ─── UUID сервисов и характеристик ─────────────────

// Кастомный сервис для тестирования GATT
#define CUSTOM_SERVICE_UUID        "ffe0"
#define CUSTOM_READ_CHAR_UUID      "ffe1"   // Read только
#define CUSTOM_WRITE_CHAR_UUID     "ffe2"   // Write без ответа
#define CUSTOM_WRITE_RSP_CHAR_UUID "ffe3"   // Write с ответом
#define CUSTOM_NOTIFY_CHAR_UUID    "ffe4"   // Notify
#define CUSTOM_CONFIG_CHAR_UUID    "ffe5"   // Read/Write — конфигурация

// ─── Параметры устройства ──────────────────────────

#define DEVICE_NAME        "Kilo BLE Test"
#define MANUFACTURER_NAME  "KiloDev"
#define MODEL_NUMBER       "ESP32-GATT-1.0"
#define FIRMWARE_REV       "1.0.0"
#define HARDWARE_REV       "1.0"
#define SOFTWARE_REV       "1.0.0"
#define SERIAL_NUMBER      "KILO-000001"

// ─── Глобальные переменные ─────────────────────────

BLEServer *pServer = nullptr;
BLECharacteristic *pNotifyChar = nullptr;
BLECharacteristic *pConfigChar = nullptr;

Preferences preferences;
bool deviceConnected = false;
uint32_t notifyCounter = 0;
uint8_t configValue[8] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07};

// Флаги для управления рекламой и подключением
bool advertising = false;
unsigned long lastNotifyTime = 0;
const unsigned long NOTIFY_INTERVAL_MS = 1000;  // 1 секунда между notify


// ─── Callback-и ────────────────────────────────────

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *server, esp_ble_gatts_cb_param_t *param) override {
    deviceConnected = true;
    advertising = false;
    Serial.printf("[BLE] Подключено: %s\n", server->getPeerAddress(0).toString().c_str());
    Serial.printf("[BLE] MTU: %d\n", server->getPeerMTU(0));
  }

  void onDisconnect(BLEServer *server) override {
    deviceConnected = false;
    Serial.println("[BLE] Отключено. Возобновление рекламы...");
    // Возобновляем рекламу после отключения
    BLEDevice::startAdvertising();
    advertising = true;
  }
};

class ReadCallback : public BLECharacteristicCallbacks {
  void onRead(BLECharacteristic *chr, esp_ble_gatts_cb_param_t *param) override {
    Serial.printf("[GATT] Read: %s\n", chr->getUUID().toString().c_str());
    // Для read-only характеристики возвращаем счётчик
    if (chr->getUUID().equals(BLEUUID(CUSTOM_READ_CHAR_UUID))) {
      uint32_t val = notifyCounter;
      chr->setValue((uint8_t *)&val, 4);
    }
  }
};

class WriteCallback : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *chr, esp_ble_gatts_cb_param_t *param) override {
    std::string uuid = chr->getUUID().toString();
    std::string value = chr->getValue();
    
    Serial.printf("[GATT] Write: %s, длина=%d, данные=", uuid.c_str(), value.length());
    for (size_t i = 0; i < value.length(); i++) {
      Serial.printf("%02x ", (uint8_t)value[i]);
    }
    Serial.println();

    // Обработка конфигурационной характеристики
    if (chr->getUUID().equals(BLEUUID(CUSTOM_CONFIG_CHAR_UUID))) {
      if (value.length() <= 8) {
        memcpy(configValue, value.data(), value.length());
        preferences.putBytes("config", configValue, 8);
        Serial.println("[CONFIG] Конфигурация обновлена");
      }
    }
  }
};


// ─── Создание сервисов GATT ─────────────────────────

void setup_generic_access_service(BLEServer *server) {
  // Сервис Generic Access (0x1800) — стандартный GATT
  BLEService *svc = server->createService(BLEUUID((uint16_t)0x1800));
  
  // Device Name (0x2A00) — Read
  BLECharacteristic *nameChar = svc->createCharacteristic(
    BLEUUID((uint16_t)0x2A00),
    BLE_CHAR_PROPERTY_READ
  );
  nameChar->setValue(DEVICE_NAME);
  
  // Appearance (0x2A01) — Read
  BLECharacteristic *appChar = svc->createCharacteristic(
    BLEUUID((uint16_t)0x2A01),
    BLE_CHAR_PROPERTY_READ
  );
  // 0x0300 = Generic Computer
  uint16_t appearance = 0x0300;
  appChar->setValue((uint8_t *)&appearance, 2);
  
  svc->start();
}

void setup_device_info_service(BLEServer *server) {
  // Сервис Device Information (0x180A)
  BLEService *svc = server->createService(BLEUUID((uint16_t)0x180A));
  
  auto add_string_char = [&](uint16_t uuid, const char *value) {
    BLECharacteristic *chr = svc->createCharacteristic(
      BLEUUID(uuid),
      BLE_CHAR_PROPERTY_READ
    );
    chr->setValue(value);
  };
  
  add_string_char(0x2A29, MANUFACTURER_NAME);  // Manufacturer Name
  add_string_char(0x2A24, MODEL_NUMBER);        // Model Number
  add_string_char(0x2A25, SERIAL_NUMBER);       // Serial Number
  add_string_char(0x2A26, FIRMWARE_REV);        // Firmware Revision
  add_string_char(0x2A27, HARDWARE_REV);        // Hardware Revision
  add_string_char(0x2A28, SOFTWARE_REV);        // Software Revision
  
  // PnP ID (0x2A50)
  BLECharacteristic *pnpChar = svc->createCharacteristic(
    BLEUUID((uint16_t)0x2A50),
    BLE_CHAR_PROPERTY_READ
  );
  uint8_t pnpId[] = {0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
  pnpChar->setValue(pnpId, 7);
  
  svc->start();
}

void setup_battery_service(BLEServer *server) {
  // Сервис Battery (0x180F)
  BLEService *svc = server->createService(BLEUUID((uint16_t)0x180F));
  
  // Battery Level (0x2A19) — Read + Notify
  BLECharacteristic *battChar = svc->createCharacteristic(
    BLEUUID((uint16_t)0x2A19),
    BLE_CHAR_PROPERTY_READ | BLE_CHAR_PROPERTY_NOTIFY
  );
  battChar->addDescriptor(new BLE2902());
  battChar->setValue((uint8_t)100);  // 100%
  
  svc->start();
}

void setup_custom_service(BLEServer *server) {
  // Кастомный сервис для тестирования GATT реверс-инжиниринга
  BLEService *svc = server->createService(BLEUUID(CUSTOM_SERVICE_UUID));
  
  // Read-only характеристика (возвращает счётчик)
  BLECharacteristic *readChar = svc->createCharacteristic(
    BLEUUID(CUSTOM_READ_CHAR_UUID),
    BLE_CHAR_PROPERTY_READ
  );
  readChar->setCallbacks(new ReadCallback());
  readChar->setValue((uint8_t *)"\x00\x00\x00\x00", 4);
  
  // Write без ответа (Write Command)
  BLECharacteristic *writeChar = svc->createCharacteristic(
    BLEUUID(CUSTOM_WRITE_CHAR_UUID),
    BLE_CHAR_PROPERTY_WRITE_NR
  );
  writeChar->setCallbacks(new WriteCallback());
  
  // Write с ответом (Write Request)
  BLECharacteristic *writeRspChar = svc->createCharacteristic(
    BLEUUID(CUSTOM_WRITE_RSP_CHAR_UUID),
    BLE_CHAR_PROPERTY_WRITE
  );
  writeRspChar->setCallbacks(new WriteCallback());
  
  // Notify-характеристика (отправляет счётчик каждую секунду)
  pNotifyChar = svc->createCharacteristic(
    BLEUUID(CUSTOM_NOTIFY_CHAR_UUID),
    BLE_CHAR_PROPERTY_NOTIFY | BLE_CHAR_PROPERTY_READ
  );
  pNotifyChar->addDescriptor(new BLE2902());
  pNotifyChar->setValue((uint8_t *)"\x00\x00\x00\x00", 4);
  
  // Конфигурационная характеристика (Read/Write, сохраняется в NVS)
  pConfigChar = svc->createCharacteristic(
    BLEUUID(CUSTOM_CONFIG_CHAR_UUID),
    BLE_CHAR_PROPERTY_READ | BLE_CHAR_PROPERTY_WRITE
  );
  pConfigChar->setCallbacks(new WriteCallback());
  pConfigChar->setValue(configValue, 8);
  
  svc->start();
}


// ─── Setup / Loop ──────────────────────────────────

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n\n=== Kilo BLE GATT Server ===");
  Serial.printf("Device: %s\n", DEVICE_NAME);
  
  // Загрузка конфигурации из NVS
  preferences.begin("kilo-ble", false);
  preferences.getBytes("config", configValue, 8);
  Serial.print("Config loaded: ");
  for (int i = 0; i < 8; i++) Serial.printf("%02x ", configValue[i]);
  Serial.println();
  
  // Инициализация BLE
  BLEDevice::init(DEVICE_NAME);
  BLEDevice::setPower(ESP_PWR_LVL_P9);  // +9 dBm
  
  // Создание GATT-сервера
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());
  
  // Настройка сервисов
  setup_generic_access_service(pServer);
  setup_device_info_service(pServer);
  setup_battery_service(pServer);
  setup_custom_service(pServer);
  
  // Настройка рекламы
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  
  // Рекламные данные
  BLEAdvertisementData advData;
  advData.setName(DEVICE_NAME);
  advData.setFlags(ESP_BLE_ADV_FLAG_GEN_DISC | ESP_BLE_ADV_FLAG_BREDR_NOT_SPT);
  pAdvertising->setAdvertisementData(advData);
  
  // Scan Response данные
  BLEAdvertisementData scanResp;
  scanResp.setName(DEVICE_NAME);
  scanResp.setManufacturerData(std::string("\x00\x01\x02\x03", 4));
  pAdvertising->setScanResponseData(scanResp);
  
  // Запуск рекламы
  pAdvertising->start();
  advertising = true;
  
  Serial.println("[BLE] Реклама запущена");
  Serial.printf("[BLE] Адрес: %s\n", BLEDevice::getAddress().toString().c_str());
  Serial.println("[BLE] Готов к подключению\n");
}

void loop() {
  unsigned long now = millis();
  
  // Периодическая отправка Notify подключённому клиенту
  if (deviceConnected && pNotifyChar && (now - lastNotifyTime >= NOTIFY_INTERVAL_MS)) {
    notifyCounter++;
    lastNotifyTime = now;
    
    // Отправляем счётчик как 4-байтовое LE значение
    pNotifyChar->setValue((uint8_t *)&notifyCounter, 4);
    pNotifyChar->notify();
    
    Serial.printf("[NOTIFY] #%u sent\n", notifyCounter);
    
    // Обновляем read-only характеристику
    // (ReadCallback делает это динамически, но можно и так)
  }
  
  // Небольшая задержка для watchdog
  delay(10);
}
