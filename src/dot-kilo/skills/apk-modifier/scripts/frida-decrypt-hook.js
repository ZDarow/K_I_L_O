// ============================================================
// frida-decrypt-hook.js — Hook для расшифровки данных в runtime
// ============================================================
// Usage: frida -U -f com.target.app -l frida-decrypt-hook.js --no-pause
// Собирает расшифрованные данные из типовых API

Java.perform(function () {
  console.log('[+] Decryption hook loaded');

  // --- Crypto ---
  var Cipher = Java.use('javax.crypto.Cipher');
  Cipher.doFinal.overload('[B').implementation = function (input) {
    var result = this.doFinal(input);
    console.log('[Cipher.doFinal] len=' + input.length + ' → ' + bytesToHex(result));
    logIfText('Cipher.doFinal', result);
    return result;
  };

  // --- Base64 decode ---
  var Base64 = Java.use('android.util.Base64');
  Base64.decode.overload('[B', 'int').implementation = function (input, flags) {
    var result = this.decode(input, flags);
    console.log('[Base64.decode] len=' + input.length + ' → decoded=' + result.length + ' bytes');
    logIfText('Base64.decode', result);
    return result;
  };

  // --- String operations ---
  var String = Java.use('java.lang.String');
  String.getBytes.overload().implementation = function () {
    var result = this.getBytes();
    console.log('[String.getBytes] "' + this.toString().substring(0, Math.min(100, this.toString().length)) + '"');
    return result;
  };

  // --- SharedPreferences ---
  var SharedPreferences = Java.use('android.content.SharedPreferences');
  var Editor = Java.use('android.content.SharedPreferences$Editor');

  Editor.putString.overload('java.lang.String', 'java.lang.String').implementation = function (key, value) {
    console.log('[SharedPrefs.putString] ' + key + ' = ' + value);
    return this.putString(key, value);
  };

  // --- URLConnection ---
  var URL = Java.use('java.net.URL');
  URL.openConnection.overload().implementation = function () {
    var conn = this.openConnection();
    console.log('[URL.openConnection] ' + this.toString());
    return conn;
  };

  // --- File I/O ---
  var FileInputStream = Java.use('java.io.FileInputStream');
  FileInputStream.read.overload('[B').implementation = function (buffer) {
    var bytesRead = this.read(buffer);
    if (bytesRead > 0) {
      var data = java.array('byte', buffer);
      console.log('[FileInputStream.read] ' + bytesRead + ' bytes');
    }
    return bytesRead;
  };

  // --- AES specific ---
  var SecretKeySpec = Java.use('javax.crypto.spec.SecretKeySpec');
  SecretKeySpec.$init.overload('[B', 'java.lang.String').implementation = function (key, algorithm) {
    console.log('[SecretKeySpec] algorithm=' + algorithm + ' key=' + bytesToHex(key));
    return this.$init(key, algorithm);
  };

  console.log('[+] All decryption hooks installed');
});

// ============================================================
// Helpers
// ============================================================

function bytesToHex(bytes) {
  var hex = [];
  for (var i = 0; i < Math.min(bytes.length, 32); i++) {
    var b = bytes[i];
    if (b < 0) b += 256;
    hex.push(('0' + b.toString(16)).slice(-2));
  }
  return hex.join('') + (bytes.length > 32 ? '...' : '');
}

function logIfText(source, bytes) {
  try {
    var str = String.fromCharCode.apply(null, bytes);
    if (str.length > 4 && /[\x20-\x7E]{4,}/.test(str)) {
      console.log('  [' + source + ' TEXT] ' + str.substring(0, 200));
    }
  } catch (e) {
    // not text, skip
  }
}
