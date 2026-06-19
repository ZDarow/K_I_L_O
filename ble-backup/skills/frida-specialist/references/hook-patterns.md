# Типовые паттерны Frida-хуков

## 1. Перехват строк

```javascript
// Hook String constructor
Java.perform(function() {
  var String = Java.use('java.lang.String');
  String.$init.overload('[B').implementation = function(bytes) {
    var str = this.$init(bytes);
    console.log('[String.fromBytes] ' + str);
    return str;
  };
});

// Hook StringBuilder
Java.perform(function() {
  var sb = Java.use('java.lang.StringBuilder');
  sb.toString.implementation = function() {
    var result = this.toString();
    if (result.includes('secret') || result.includes('token')) {
      console.log('[StringBuilder] ' + result);
    }
    return result;
  };
});
```

## 2. Перехват AES/Crypto

```javascript
Java.perform(function() {
  // Cipher init — capture key
  var Cipher = Java.use('javax.crypto.Cipher');
  Cipher.init.overload('int', 'java.security.Key').implementation = function(mode, key) {
    console.log('[Cipher.init] mode=' + mode + ' key=' + key.toString());
    // dump encoded key
    var enc = key.getEncoded();
    if (enc) console.log('  key hex: ' + bytesToHex(enc));
    return this.init(mode, key);
  };

  // Cipher doFinal — capture plaintext
  Cipher.doFinal.overload('[B').implementation = function(input) {
    console.log('[Cipher.doFinal] input=' + bytesToHex(input));
    var result = this.doFinal(input);
    console.log('  output=' + bytesToHex(result));
    return result;
  };

  // SecretKeySpec — capture key material
  var SecretKeySpec = Java.use('javax.crypto.spec.SecretKeySpec');
  SecretKeySpec.$init.overload('[B', 'java.lang.String').implementation = function(key, algo) {
    console.log('[SecretKeySpec] algo=' + algo + ' key=' + bytesToHex(key));
    return this.$init(key, algo);
  };
});

function bytesToHex(bytes) {
  var hex = [];
  for (var i = 0; i < Math.min(bytes.length, 64); i++) {
    var b = bytes[i];
    if (b < 0) b += 256;
    hex.push(('0' + b.toString(16)).slice(-2));
  }
  return hex.join('') + (bytes.length > 64 ? '...' : '');
}
```

## 3. Перехват SharedPreferences

```javascript
Java.perform(function() {
  var Editor = Java.use('android.content.SharedPreferences$Editor');
  Editor.putString.overload('java.lang.String', 'java.lang.String').implementation = function(key, value) {
    console.log('[SharedPrefs] putString: ' + key + ' = ' + value);
    return this.putString(key, value);
  };

  var prefs = Java.use('android.content.SharedPreferences');
  prefs.getString.overload('java.lang.String', 'java.lang.String').implementation = function(key, def) {
    var value = this.getString(key, def);
    console.log('[SharedPrefs] getString: ' + key + ' = ' + value);
    return value;
  };
});
```

## 4. Перехват URL/HTTP

```javascript
Java.perform(function() {
  // Hook URL.openConnection to see all HTTP requests
  var URL = Java.use('java.net.URL');
  URL.openConnection.overload().implementation = function() {
    var conn = this.openConnection();
    console.log('[HTTP] ' + this.toString());
    return conn;
  };

  // Hook HttpURLConnection for headers/body
  var HttpURLConnection = Java.use('java.net.HttpURLConnection');
  HttpURLConnection.getOutputStream.implementation = function() {
    var os = this.getOutputStream();
    console.log('[HTTP] getOutputStream on ' + this.getURL());
    return os;
  };

  // OkHttp interceptor
  try {
    var OkHttpClient = Java.use('okhttp3.OkHttpClient');
    OkHttpClient.newCall.overload('okhttp3.Request').implementation = function(request) {
      console.log('[OkHttp] ' + request.method() + ' ' + request.url());
      return this.newCall(request);
    };
  } catch (e) {}
});
```

## 5. Перехват File I/O

```javascript
Java.perform(function() {
  var File = Java.use('java.io.File');
  File.$init.overload('java.lang.String').implementation = function(path) {
    if (path.includes('.db') || path.includes('.xml') || path.includes('key')) {
      console.log('[File] ' + path);
    }
    return this.$init(path);
  };

  var FileInputStream = Java.use('java.io.FileInputStream');
  FileInputStream.$init.overload('java.io.File').implementation = function(file) {
    console.log('[FileInputStream] reading: ' + file.getAbsolutePath());
    return this.$init(file);
  };
});
```

## 6. Bypass Root Detection — методы

```javascript
Java.perform(function() {
  // Method 1: File.exists
  var File = Java.use('java.io.File');
  File.exists.overload().implementation = function() {
    var path = this.getAbsolutePath();
    var blocked = ['/sbin/su', '/system/bin/su', '/system/xbin/su',
      '/system/app/Superuser.apk', '/data/local/tmp/frida'];
    if (blocked.some(function(p) { return path.includes(p); })) return false;
    return this.exists();
  };

  // Method 2: Runtime.exec — block su
  var Runtime = Java.use('java.lang.Runtime');
  Runtime.exec.overload('[Ljava.lang.String;').implementation = function(cmdarray) {
    var cmd = cmdarray.join(' ');
    if (cmd.includes('su') || cmd.includes('busybox') || cmd.includes('magisk')) {
      console.log('[RootBypass] blocked: ' + cmd);
      return null;
    }
    return this.exec(cmdarray);
  };

  // Method 3: Build.TAGS — spoof
  var Build = Java.use('android.os.Build');
  Build.TAGS.value = 'release-keys';  // instead of 'test-keys'
});
```

## 7. Native Hook — libc functions

```javascript
// Hook strcmp/strstr to catch detection strings
var strcmp = Module.findExportByName('libc.so', 'strcmp');
if (strcmp) {
  Interceptor.attach(strcmp, {
    onEnter: function(args) {
      var s1 = Memory.readCString(args[0]);
      var s2 = Memory.readCString(args[1]);
      if (s1 && (s1.includes('frida') || s1.includes('su') || s1.includes('debug'))) {
        console.log('[strcmp] ' + s1 + ' vs ' + s2);
      }
    }
  });
}

// Hook fopen to catch config file reads
var fopen = Module.findExportByName('libc.so', 'fopen');
if (fopen) {
  Interceptor.attach(fopen, {
    onEnter: function(args) {
      var path = Memory.readCString(args[0]);
      if (path && (path.includes('.conf') || path.includes('.key'))) {
        console.log('[fopen] ' + path);
      }
    }
  });
}
```

## 8. Bypass SSL Pinning — расширенный

```javascript
Java.perform(function() {
  // TrustManager (основной)
  var TrustManager = Java.use('javax.net.ssl.X509TrustManager');
  TrustManager.checkServerTrusted.overload(
    '[Ljava.security.cert.X509Certificate;', 'java.lang.String'
  ).implementation = function() {};

  // SSLContext.init — inject custom TrustManager
  var SSLContext = Java.use('javax.net.ssl.SSLContext');
  SSLContext.init.overload(
    '[Ljavax.net.ssl.KeyManager;',
    '[Ljavax.net.ssl.TrustManager;',
    'java.security.SecureRandom'
  ).implementation = function(keyManagers, trustManagers, secureRandom) {
    console.log('[SSL] SSLContext.init called, injecting trust manager');
    var TrustManager = Java.use('javax.net.ssl.X509TrustManager');
    var tm = TrustManager.$new();
    return this.init(keyManagers, [tm], secureRandom);
  };

  // OkHttp CertificatePinner
  try {
    var CertificatePinner = Java.use('okhttp3.CertificatePinner');
    CertificatePinner.check.overload(
      'java.lang.String', '[Ljava.security.cert.Certificate;'
    ).implementation = function(host, certs) { return; };
  } catch (e) {}

  // TrustKit
  try {
    var TrustKit = Java.use('com.datatheorem.android.trustkit.TrustKit');
    TrustKit.initializeWithNetworkSecurityConfiguration.implementation = function() {};
  } catch (e) {}

  // WebView
  try {
    var WebViewClient = Java.use('android.webkit.WebViewClient');
    WebViewClient.onReceivedSslError.overload(
      'android.webkit.WebView', 'android.webkit.SslErrorHandler',
      'android.net.http.SslError'
    ).implementation = function(view, handler, error) {
      handler.proceed();
    };
  } catch (e) {}
});
```

## 9. Dump DEX из памяти

```javascript
Java.perform(function() {
  // Enumerate all BaseDexClassLoader instances → find DEX paths
  Java.enumerateLoadedClasses({
    onMatch: function(cls) {
      if (cls.includes('dalvik.system.BaseDexClassLoader')) {
        Java.choose(cls, {
          onMatch: function(instance) {
            console.log('[DEX] Found classloader: ' + instance.toString());
          }
        });
      }
    }
  });
});
```

## 10. Method trace — все вызовы метода с caller

```javascript
Java.perform(function() {
  var cls = Java.use('com.target.SensitiveClass');

  cls.sensitiveMethod.overloads.forEach(function(overload) {
    overload.implementation = function() {
      var thread = Java.use('java.lang.Thread');
      var stack = thread.currentThread().getStackTrace();
      var caller = stack.length > 2 ? stack[2].toString() : 'unknown';

      console.log('[Trace] ' + overload + ' called from: ' + caller);
      console.log('  args: ' + JSON.stringify(Array.prototype.slice.call(arguments)));

      var result = overload.apply(this, arguments);
      console.log('  return: ' + result);
      return result;
    };
  });
});
```
