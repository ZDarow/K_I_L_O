// ============================================================
// Frida Hook Template — базовая структура скрипта
// ============================================================
// Usage:
//   frida -U -f com.target.app -l frida-hook-template.js --no-pause
//   frida -U -l frida-hook-template.js  (attach to running)

'use strict';

// === Configuration ===
const CONFIG = {
  TARGET_CLASS: 'com.target.app.MainActivity',
  LOG_TAG: '[HOOK]',
  DUMP_DIR: '/data/local/tmp/frida_dumps/',
};

// === Utility ===
function hexdump(buf, len) {
  if (!buf) return '(null)';
  const bytes = Memory.readByteArray(buf, Math.min(len || 64, 64));
  return JSON.stringify(Array.from(new Uint8Array(bytes)));
}

function log(tag, msg) {
  console.log(`${CONFIG.LOG_TAG} [${tag}] ${msg}`);
}

// === Java Hooks ===
function hookJava() {
  Java.perform(function() {
    log('Java', 'Script loaded, hooking...');

    // --- Template: hook class method ---
    try {
      var TargetClass = Java.use(CONFIG.TARGET_CLASS);

      // Hook with specific overload
      if (TargetClass.someMethod) {
        TargetClass.someMethod.overload('int', 'java.lang.String').implementation = function(a, b) {
          log('SomeMethod', `called(${a}, "${b}")`);
          // Modify args
          var result = this.someMethod(a, b + '_hooked');
          log('SomeMethod', `return=${result}`);
          return result;
        };
      }
    } catch (e) {
      console.warn(`[WARN] Failed to hook ${CONFIG.TARGET_CLASS}: ${e}`);
    }

    // --- Template: enumerate all methods of a class ---
    try {
      var cls = Java.use('java.lang.Class');
      log('Enumerate', 'Ready');
    } catch (e) {
      // ignore
    }
  });
}

// === Native Hooks ===
function hookNative() {
  // --- Template: hook by export name ---
  var libc = Module.findBaseAddress('libc.so');
  if (libc) {
    var strcmp = Module.findExportByName('libc.so', 'strcmp');
    if (strcmp) {
      Interceptor.attach(strcmp, {
        onEnter: function(args) {
          var s1 = Memory.readCString(args[0]);
          var s2 = Memory.readCString(args[1]);
          if (s1 && s1.includes('password')) {
            log('strcmp', `"${s1}" vs "${s2}"`);
          }
        }
      });
    }
  }

  // --- Template: hook by offset (from IDA/Ghidra) ---
  var mod = Process.findModuleByName('libnative.so');
  if (mod) {
    var targetFunc = mod.base.add(0x1234);
    Interceptor.attach(targetFunc, {
      onEnter: function(args) {
        log('Offset', `+0x1234 called arg0=${args[0]}`);
      },
      onLeave: function(retval) {
        log('Offset', `returns ${retval}`);
      }
    });
  }
}

// === SSL Pinning Bypass ===
function bypassSSL() {
  Java.perform(function() {
    // TrustManager bypass
    try {
      var TrustManager = Java.use('javax.net.ssl.X509TrustManager');
      TrustManager.checkServerTrusted.overload(
        '[Ljava.security.cert.X509Certificate;', 'java.lang.String'
      ).implementation = function() { return; };

      TrustManager.checkClientTrusted.overload(
        '[Ljava.security.cert.X509Certificate;', 'java.lang.String'
      ).implementation = function() { return; };

      log('SSL', 'TrustManager bypassed');
    } catch (e) {
      console.warn('[WARN] TrustManager bypass failed:', e);
    }

    // OkHttp CertificatePinner bypass
    try {
      var CertificatePinner = Java.use('okhttp3.CertificatePinner');
      CertificatePinner.check.overload(
        'java.lang.String', '[Ljava.security.cert.Certificate;'
      ).implementation = function() { return; };
      log('SSL', 'OkHttp CertificatePinner bypassed');
    } catch (e) {
      // not using OkHttp
    }

    // WebView SSL error bypass
    try {
      var WebViewClient = Java.use('android.webkit.WebViewClient');
      WebViewClient.onReceivedSslError.overload(
        'android.webkit.WebView', 'android.webkit.SslErrorHandler',
        'android.net.http.SslError'
      ).implementation = function(view, handler, error) {
        log('SSL', `WebView SSL error: ${error.getPrimaryError()}, proceeding`);
        handler.proceed();
      };
    } catch (e) {
      // no WebView
    }
  });
}

// === Message Handling (Python client communication) ===
function setupComms() {
  // Send data back to Python client
  send({ type: 'ready', message: 'Frida script loaded successfully' });

  // Receive commands from Python client
  recv(function(msg) {
    log('Comms', `Received command: ${JSON.stringify(msg)}`);
    if (msg.type === 'hook') {
      Java.perform(function() {
        // dynamic hook from command
      });
    }
  });
}

// === Main ===
function main() {
  log('Init', 'Frida script starting');
  log('Init', `Target: ${CONFIG.TARGET_CLASS}`);
  log('Init', `Platform: ${Process.platform}, Arch: ${Process.arch}, PID: ${Process.id}`);

  setupComms();
  bypassSSL();
  hookJava();
  hookNative();
}

// Entry point
setTimeout(main, 0);
