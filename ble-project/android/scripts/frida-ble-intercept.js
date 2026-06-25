/*
 * Frida-скрипт для перехвата BLE GATT операций на Android.
 *
 * Перехватывает:
 *   - BluetoothGatt.discoverServices()
 *   - BluetoothGatt.readCharacteristic()
 *   - BluetoothGatt.writeCharacteristic()
 *   - BluetoothGatt.setCharacteristicNotification()
 *   - BluetoothGattCallback.onServicesDiscovered()
 *   - BluetoothGattCallback.onCharacteristicRead()
 *   - BluetoothGattCallback.onCharacteristicWrite()
 *   - BluetoothGattCallback.onCharacteristicChanged()
 *
 * Использование:
 *   frida -U -f com.example.app -l frida-ble-intercept.js --no-pause
 *   frida -U com.example.app -l frida-ble-intercept.js
 *
 * Результат: логи GATT операций в stdout + /data/local/tmp/ble_log.txt
 */

'use strict';

// Конфигурация
const CONFIG = {
  logToFile: true,
  logPath: '/data/local/tmp/ble_log.txt',
  logToConsole: true,
  // UUID которые игнорировать (дескрипторы, CCCD и т.д.)
  ignoreUuids: [
    '00002902-0000-1000-8000-00805f9b34fb', // CCCD
    '00002901-0000-1000-8000-00805f9b34fb', // Characteristic User Description
  ],
};

// Логгер
function log(msg) {
  const timestamp = new Date().toISOString();
  const line = `[${timestamp}] ${msg}`;
  if (CONFIG.logToConsole) console.log(line);
  if (CONFIG.logToFile) {
    try {
      Java.perform(() => {
        const File = Java.use('java.io.File');
        const FileWriter = Java.use('java.io.FileWriter');
        const f = FileWriter.$new(CONFIG.logPath, true);
        f.write(line + '\n');
        f.close();
      });
    } catch (e) {
      console.error(`[FATAL] Log error: ${e}`);
    }
  }
}

function formatBytes(bytes) {
  if (!bytes) return 'null';
  const arr = Array.isArray(bytes) ? bytes : Array.from(bytes);
  return arr.map(b => ('0' + (b & 0xFF).toString(16)).slice(-2)).join(' ');
}

function uuidToString(uuid) {
  if (!uuid) return 'null';
  // Android UUID может быть ParcelUuid или String
  try {
    if (uuid.toString) return uuid.toString();
    return String(uuid);
  } catch (e) {
    return String(uuid);
  }
}

function isIgnoredUuid(uuid) {
  if (!uuid) return false;
  const u = uuidToString(uuid).toLowerCase();
  return CONFIG.ignoreUuids.some(ignored => u.includes(ignored));
}

// Перехват BluetoothGatt методов
function hookBluetoothGatt() {
  const BluetoothGatt = Java.use('android.bluetooth.BluetoothGatt');

  // discoverServices
  BluetoothGatt.discoverServices.implementation = function () {
    log(`[GATT] discoverServices() → device: ${this.getDevice()?.getAddress()}`);
    return this.discoverServices();
  };

  // readCharacteristic
  BluetoothGatt.readCharacteristic.implementation = function (characteristic) {
    const uuid = characteristic?.getUuid()?.toString();
    if (uuid && !isIgnoredUuid(uuid)) {
      log(`[GATT] readCharacteristic() → UUID: ${uuid}`);
    }
    return this.readCharacteristic(characteristic);
  };

  // writeCharacteristic
  BluetoothGatt.writeCharacteristic.implementation = function (characteristic) {
    const uuid = characteristic?.getUuid()?.toString();
    const value = characteristic?.getValue();
    if (uuid && !isIgnoredUuid(uuid)) {
      const hex = value ? formatBytes(value) : 'empty';
      log(`[GATT] writeCharacteristic() → UUID: ${uuid}, Value: [${hex}]`);
    }
    return this.writeCharacteristic(characteristic);
  };

  // setCharacteristicNotification
  BluetoothGatt.setCharacteristicNotification.implementation = function (characteristic, enable) {
    const uuid = characteristic?.getUuid()?.toString();
    if (uuid && !isIgnoredUuid(uuid)) {
      log(`[GATT] setCharacteristicNotification() → UUID: ${uuid}, Enable: ${enable}`);
    }
    return this.setCharacteristicNotification(characteristic, enable);
  };

  // readDescriptor
  BluetoothGatt.readDescriptor.implementation = function (descriptor) {
    const uuid = descriptor?.getUuid()?.toString();
    if (uuid && !isIgnoredUuid(uuid)) {
      log(`[GATT] readDescriptor() → UUID: ${uuid}`);
    }
    return this.readDescriptor(descriptor);
  };

  // writeDescriptor
  BluetoothGatt.writeDescriptor.implementation = function (descriptor) {
    const uuid = descriptor?.getUuid()?.toString();
    const value = descriptor?.getValue();
    if (uuid && !isIgnoredUuid(uuid)) {
      const hex = value ? formatBytes(value) : 'empty';
      log(`[GATT] writeDescriptor() → UUID: ${uuid}, Value: [${hex}]`);
    }
    return this.writeDescriptor(descriptor);
  };

  // connect
  BluetoothGatt.connect.implementation = function () {
    log(`[GATT] connect() → device: ${this.getDevice()?.getAddress()}`);
    return this.connect();
  };

  // disconnect
  BluetoothGatt.disconnect.implementation = function () {
    log(`[GATT] disconnect() → device: ${this.getDevice()?.getAddress()}`);
    return this.disconnect();
  };

  // close
  BluetoothGatt.close.implementation = function () {
    log(`[GATT] close()`);
    return this.close();
  };

  log('[HOOK] BluetoothGatt методы перехвачены');
}

// Перехват BluetoothGattCallback
function hookBluetoothGattCallback() {
  const BluetoothGattCallback = Java.use('android.bluetooth.BluetoothGattCallback');
  const classLoader = BluetoothGattCallback.class.getClassLoader();

  // Класс, который реализует callback — обычно анонимный
  Java.enumerateLoadedClasses({
    onMatch: function (className) {
      if (className.includes('BluetoothGatt') ||
          className.includes('GattCallback') ||
          className.includes('bluetooth')) {
        try {
          const clazz = Java.use(className);
          if (clazz && clazz.getClass().getName() !==
              'android.bluetooth.BluetoothGattCallback') {
            hookCallbackClass(clazz);
          }
        } catch (e) {
          // ignore
        }
      }
    },
    onComplete: function () {}
  });
}

function hookCallbackClass(clazz) {
  // onServicesDiscovered
  if (clazz.onServicesDiscovered) {
    clazz.onServicesDiscovered.implementation = function (gatt, status) {
      log(`[CALLBACK] onServicesDiscovered() → status: ${status}`);
      if (status === 0 && gatt) {
        const services = gatt.getServices();
        if (services) {
          log(`[CALLBACK]   Сервисов: ${services.size()}`);
          const iterator = services.iterator();
          while (iterator.hasNext()) {
            const svc = iterator.next();
            log(`[CALLBACK]   Сервис: ${svc.getUuid()} handle=${svc.getInstanceId()}`);
            // Характеристики
            const chars = svc.getCharacteristics();
            if (chars) {
              const charIter = chars.iterator();
              while (charIter.hasNext()) {
                const chr = charIter.next();
                const props = chr.getProperties();
                const propStr = [];
                if (props & 0x02) propStr.push('READ');
                if (props & 0x08) propStr.push('WRITE');
                if (props & 0x04) propStr.push('WRITE_NR');
                if (props & 0x10) propStr.push('NOTIFY');
                if (props & 0x20) propStr.push('INDICATE');
                log(`[CALLBACK]     Хар-ка: ${chr.getUuid()} [${propStr.join('|')}]`);
              }
            }
          }
        }
      }
      return this.onServicesDiscovered(gatt, status);
    };
    log(`[HOOK] onServicesDiscovered перехвачен в ${clazz.$className}`);
  }

  // onCharacteristicRead
  if (clazz.onCharacteristicRead) {
    clazz.onCharacteristicRead.implementation = function (gatt, characteristic, status) {
      const uuid = uuidToString(characteristic?.getUuid());
      const value = characteristic?.getValue();
      if (!isIgnoredUuid(uuid)) {
        const hex = value ? formatBytes(value) : 'empty';
        log(`[CALLBACK] onCharacteristicRead() → UUID: ${uuid}, Value: [${hex}], status: ${status}`);
      }
      return this.onCharacteristicRead(gatt, characteristic, status);
    };
  }

  // onCharacteristicWrite
  if (clazz.onCharacteristicWrite) {
    clazz.onCharacteristicWrite.implementation = function (gatt, characteristic, status) {
      const uuid = uuidToString(characteristic?.getUuid());
      const value = characteristic?.getValue();
      if (!isIgnoredUuid(uuid)) {
        const hex = value ? formatBytes(value) : 'empty';
        log(`[CALLBACK] onCharacteristicWrite() → UUID: ${uuid}, Value: [${hex}], status: ${status}`);
      }
      return this.onCharacteristicWrite(gatt, characteristic, status);
    };
  }

  // onCharacteristicChanged
  if (clazz.onCharacteristicChanged) {
    clazz.onCharacteristicChanged.implementation = function (gatt, characteristic) {
      const uuid = uuidToString(characteristic?.getUuid());
      const value = characteristic?.getValue();
      if (!isIgnoredUuid(uuid)) {
        const hex = value ? formatBytes(value) : 'empty';
        log(`[CALLBACK] onCharacteristicChanged() → UUID: ${uuid}, Value: [${hex}]`);
      }
      return this.onCharacteristicChanged(gatt, characteristic);
    };
  }

  // onConnectionStateChange
  if (clazz.onConnectionStateChange) {
    clazz.onConnectionStateChange.implementation = function (gatt, status, newState) {
      const stateNames = ['', 'CONNECTING', 'CONNECTED', 'DISCONNECTING', 'DISCONNECTED'];
      const device = gatt?.getDevice()?.getAddress() || 'unknown';
      log(`[CALLBACK] onConnectionStateChange() → device: ${device}, state: ${stateNames[newState] || newState}, status: ${status}`);
      return this.onConnectionStateChange(gatt, status, newState);
    };
  }

  // onMtuChanged
  if (clazz.onMtuChanged) {
    clazz.onMtuChanged.implementation = function (gatt, mtu, status) {
      log(`[CALLBACK] onMtuChanged() → MTU: ${mtu}, status: ${status}`);
      return this.onMtuChanged(gatt, mtu, status);
    };
  }
}

// Перехват BluetoothDevice
function hookBluetoothDevice() {
  const BluetoothDevice = Java.use('android.bluetooth.BluetoothDevice');

  BluetoothDevice.connectGatt.implementation = function (context, autoConnect, callback) {
    const address = this.getAddress();
    log(`[GATT] connectGatt() → ${address}, autoConnect: ${autoConnect}, callback: ${callback?.$className || 'null'}`);
    return this.connectGatt(context, autoConnect, callback);
  };
}

function main() {
  Java.perform(function () {
    log(`\n=== Frida BLE Intercept запущен ===`);
    log(`Конфигурация: logToFile=${CONFIG.logToFile}, path=${CONFIG.logPath}`);

    try {
      hookBluetoothGatt();
    } catch (e) {
      log(`[WARN] BluetoothGatt hook: ${e}`);
    }

    try {
      hookBluetoothDevice();
    } catch (e) {
      log(`[WARN] BluetoothDevice hook: ${e}`);
    }

    try {
      hookBluetoothGattCallback();
    } catch (e) {
      log(`[WARN] BluetoothGattCallback hook: ${e}`);
    }

    log(`=== Frida BLE Intercept готов ===\n`);
  });
}

setTimeout(main, 500);
