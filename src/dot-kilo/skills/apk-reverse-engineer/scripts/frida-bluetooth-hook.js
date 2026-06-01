/**
 * Frida скрипт для мониторинга Bluetooth-активности
 * Использование: frida -U -f <package_name> -l frida-bluetooth-hook.js --no-pause
 */

Java.perform(function() {
    console.log("[*] 📡 Starting Bluetooth monitoring...");
    console.log("[*] Hooking Android Bluetooth classes...");

    // ========== Classic Bluetooth ==========

    // BluetoothAdapter
    try {
        var BluetoothAdapter = Java.use("android.bluetooth.BluetoothAdapter");
        console.log("[+] BluetoothAdapter hooked");

        BluetoothAdapter.enable.overload().implementation = function() {
            console.log("[🔵] BluetoothAdapter.enable() called");
            return this.enable();
        };

        BluetoothAdapter.disable.overload().implementation = function() {
            console.log("[🔴] BluetoothAdapter.disable() called");
            return this.disable();
        };

        BluetoothAdapter.isEnabled.overload().implementation = function() {
            var result = this.isEnabled();
            console.log("[📶] BluetoothAdapter.isEnabled() = " + result);
            return result;
        };

        BluetoothAdapter.getAddress.overload().implementation = function() {
            var address = this.getAddress();
            console.log("[📍] BluetoothAdapter.getAddress() = " + address);
            return address;
        };

        BluetoothAdapter.getName.overload().implementation = function() {
            var name = this.getName();
            console.log("[📛] BluetoothAdapter.getName() = " + name);
            return name;
        };

        BluetoothAdapter.getBondedDevices.overload().implementation = function() {
            var devices = this.getBondedDevices();
            console.log("[🔗] BluetoothAdapter.getBondedDevices() = " + devices.size() + " devices");
            return devices;
        };
    } catch (e) {
        console.log("[-] BluetoothAdapter hook failed: " + e);
    }

    // BluetoothDevice
    try {
        var BluetoothDevice = Java.use("android.bluetooth.BluetoothDevice");
        console.log("[+] BluetoothDevice hooked");

        BluetoothDevice.getName.overload().implementation = function() {
            var name = this.getName();
            console.log("[📛] BluetoothDevice.getName() = " + name);
            return name;
        };

        BluetoothDevice.getAddress.overload().implementation = function() {
            var address = this.getAddress();
            console.log("[📍] BluetoothDevice.getAddress() = " + address);
            return address;
        };

        BluetoothDevice.createRfcommSocketToServiceRecord.overload("java.util.UUID").implementation = function(uuid) {
            console.log("[🔌] BluetoothDevice.createRfcommSocketToServiceRecord()");
            console.log("    UUID: " + uuid);
            return this.createRfcommSocketToServiceRecord(uuid);
        };

        BluetoothDevice.connect.overload("android.bluetooth.BluetoothSocket").implementation = function(socket) {
            console.log("[🔗] BluetoothDevice.connect() called");
            return this.connect(socket);
        };
    } catch (e) {
        console.log("[-] BluetoothDevice hook failed: " + e);
    }

    // BluetoothSocket
    try {
        var BluetoothSocket = Java.use("android.bluetooth.BluetoothSocket");
        console.log("[+] BluetoothSocket hooked");

        BluetoothSocket.connect.overload().implementation = function() {
            console.log("[🔗] BluetoothSocket.connect() called");
            return this.connect();
        };

        BluetoothSocket.getOutputStream.overload().implementation = function() {
            console.log("[📤] BluetoothSocket.getOutputStream() called");
            return this.getOutputStream();
        };

        BluetoothSocket.getInputStream.overload().implementation = function() {
            console.log("[📥] BluetoothSocket.getInputStream() called");
            return this.getInputStream();
        };
    } catch (e) {
        console.log("[-] BluetoothSocket hook failed: " + e);
    }

    // ========== Bluetooth Low Energy (BLE) ==========

    // BluetoothLeScanner
    try {
        var BluetoothLeScanner = Java.use("android.bluetooth.le.BluetoothLeScanner");
        console.log("[+] BluetoothLeScanner hooked");

        BluetoothLeScanner.startScan.overload("java.util.List", "android.bluetooth.le.ScanSettings", "android.bluetooth.le.ScanCallback").implementation = function(filters, settings, callback) {
            console.log("[🔍] BluetoothLeScanner.startScan() called");
            console.log("    Filters: " + (filters ? filters.size() : 0));
            return this.startScan(filters, settings, callback);
        };

        BluetoothLeScanner.stopScan.overload("android.bluetooth.le.ScanCallback").implementation = function(callback) {
            console.log("[⏹️] BluetoothLeScanner.stopScan() called");
            return this.stopScan(callback);
        };
    } catch (e) {
        console.log("[-] BluetoothLeScanner hook failed: " + e);
    }

    // ScanCallback
    try {
        var ScanCallback = Java.use("android.bluetooth.le.ScanCallback");
        console.log("[+] ScanCallback hooked");

        ScanCallback.onScanResult.overload("int", "android.bluetooth.le.ScanResult").implementation = function(callbackType, result) {
            var device = result.getDevice();
            console.log("[📡] ScanCallback.onScanResult()");
            console.log("    Device: " + device.getName() + " (" + device.getAddress() + ")");
            console.log("    RSSI: " + result.getRssi());
            return this.onScanResult(callbackType, result);
        };
    } catch (e) {
        console.log("[-] ScanCallback hook failed: " + e);
    }

    // BluetoothGatt
    try {
        var BluetoothGatt = Java.use("android.bluetooth.BluetoothGatt");
        console.log("[+] BluetoothGatt hooked");

        BluetoothGatt.connect.overload().implementation = function() {
            console.log("[🔗] BluetoothGatt.connect() called");
            return this.connect();
        };

        BluetoothGatt.disconnect.overload().implementation = function() {
            console.log("[❌] BluetoothGatt.disconnect() called");
            return this.disconnect();
        };

        BluetoothGatt.close.overload().implementation = function() {
            console.log("[🚪] BluetoothGatt.close() called");
            return this.close();
        };

        BluetoothGatt.discoverServices.overload().implementation = function() {
            console.log("[🔎] BluetoothGatt.discoverServices() called");
            return this.discoverServices();
        };

        BluetoothGatt.readCharacteristic.overload("android.bluetooth.BluetoothGattCharacteristic").implementation = function(characteristic) {
            var uuid = characteristic.getUuid();
            console.log("[📖] BluetoothGatt.readCharacteristic()");
            console.log("    UUID: " + uuid);
            return this.readCharacteristic(characteristic);
        };

        BluetoothGatt.writeCharacteristic.overload("android.bluetooth.BluetoothGattCharacteristic").implementation = function(characteristic) {
            var uuid = characteristic.getUuid();
            var value = characteristic.getValue();
            console.log("[✍️] BluetoothGatt.writeCharacteristic()");
            console.log("    UUID: " + uuid);
            console.log("    Value: " + bytesToHex(value));
            return this.writeCharacteristic(characteristic);
        };

        BluetoothGatt.setCharacteristicNotification.overload("android.bluetooth.BluetoothGattCharacteristic", "boolean").implementation = function(characteristic, enable) {
            var uuid = characteristic.getUuid();
            console.log("[🔔] BluetoothGatt.setCharacteristicNotification()");
            console.log("    UUID: " + uuid);
            console.log("    Enable: " + enable);
            return this.setCharacteristicNotification(characteristic, enable);
        };
    } catch (e) {
        console.log("[-] BluetoothGatt hook failed: " + e);
    }

    // BluetoothGattCharacteristic
    try {
        var BluetoothGattCharacteristic = Java.use("android.bluetooth.BluetoothGattCharacteristic");
        console.log("[+] BluetoothGattCharacteristic hooked");

        BluetoothGattCharacteristic.setValue.overload("[B").implementation = function(data) {
            console.log("[💾] BluetoothGattCharacteristic.setValue(byte[])");
            console.log("    Length: " + data.length);
            console.log("    Data: " + bytesToHex(data));
            return this.setValue(data);
        };

        BluetoothGattCharacteristic.getValue.overload().implementation = function() {
            var value = this.getValue();
            console.log("[📤] BluetoothGattCharacteristic.getValue()");
            console.log("    Length: " + (value ? value.length : 0));
            if (value) {
                console.log("    Data: " + bytesToHex(value));
            }
            return value;
        };
    } catch (e) {
        console.log("[-] BluetoothGattCharacteristic hook failed: " + e);
    }

    // ========== Helper Functions ==========

    function bytesToHex(bytes) {
        if (!bytes) return "null";
        var hex = "";
        for (var i = 0; i < bytes.length; i++) {
            hex += ((bytes[i] & 0xFF) + 0x100).toString(16).substring(1).toUpperCase() + " ";
        }
        return hex.trim();
    }

    function hexToString(hex) {
        var str = "";
        for (var i = 0; i < hex.length; i += 2) {
            str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
        }
        return str;
    }

    console.log("[*] ✅ All Bluetooth hooks installed!");
    console.log("[*] Waiting for Bluetooth activity...");
});
