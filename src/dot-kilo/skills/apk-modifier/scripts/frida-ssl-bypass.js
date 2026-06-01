// ============================================================
// frida-ssl-bypass.js — Universal SSL Pinning Bypass
// ============================================================
// Usage: frida -U -f com.target.app -l frida-ssl-bypass.js --no-pause

Java.perform(function () {
  console.log('[+] SSL Pinning Bypass loaded');

  // --- TrustManager bypass ---
  var TrustManager = Java.use('javax.net.ssl.X509TrustManager');
  var TrustManagerImpl = Java.use('com.android.org.conscrypt.TrustManagerImpl');

  if (TrustManager) {
    TrustManager.checkServerTrusted.overload(
      '[Ljava.security.cert.X509Certificate;', 'java.lang.String'
    ).implementation = function (certs, authType) {
      console.log('[+] TrustManager.checkServerTrusted bypassed');
      return;
    };

    TrustManager.checkClientTrusted.overload(
      '[Ljava.security.cert.X509Certificate;', 'java.lang.String'
    ).implementation = function (certs, authType) {
      return;
    };
  }

  // --- OkHttp3 bypass ---
  var CertificatePinner = Java.use('okhttp3.CertificatePinner');
  if (CertificatePinner) {
    CertificatePinner.check.overload('java.lang.String', '[Ljava.security.cert.Certificate;').implementation = function () {
      console.log('[+] OkHttp CertificatePinner bypassed');
      return;
    };
  }

  // --- TrustKit bypass ---
  var TrustKit = Java.use('com.datatheorem.android.trustkit.TrustKit');
  if (TrustKit) {
    TrustKit.initializeWithNetworkSecurityConfiguration.implementation = function () {
      console.log('[+] TrustKit bypassed');
      return;
    };
  }

  // --- WebView SSL error bypass ---
  var WebViewClient = Java.use('android.webkit.WebViewClient');
  if (WebViewClient) {
    WebViewClient.onReceivedSslError.overload(
      'android.webkit.WebView', 'android.webkit.SslErrorHandler', 'android.net.http.SslError'
    ).implementation = function (view, handler, error) {
      console.log('[+] WebView SSL error bypassed: ' + error.getPrimaryError());
      handler.proceed();
    };
  }

  // --- NetworkSecurityManager bypass ---
  var NetworkSecurityManager = Java.use('android.security.NetworkSecurityPolicy');
  if (NetworkSecurityManager) {
    NetworkSecurityManager.isCleartextTrafficPermitted.overload().implementation = function () {
      return true;
    };
  }

  console.log('[+] All SSL bypass hooks installed');
});
