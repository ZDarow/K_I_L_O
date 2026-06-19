# Frida Dynamic Analysis Report

## 1. Session Info
- **Date**: {{date}}
- **Target**: {{app_name}} ({{package}})
- **Version**: {{version_code}}
- **Device**: {{device_model}} / Android {{api_level}}
- **Frida**: {{frida_version}} ({{mode}}: inject/gadget)
- **Script**: {{script_name}}

## 2. Hooks Applied

### Java Hooks
| # | Class | Method | Signature | Purpose | Result |
|---|-------|--------|-----------|---------|--------|
| 1 | `{{class}}` | `{{method}}` | `{{sig}}` | {{purpose}} | OK/FAIL |
| 2 | `{{class}}` | `{{method}}` | `{{sig}}` | {{purpose}} | OK/FAIL |

### Native Hooks
| # | Library | Offset/Export | Purpose | Result |
|---|---------|---------------|---------|--------|
| 1 | `{{lib}}` | `+0x{{offset}}` | {{purpose}} | OK/FAIL |
| 2 | `{{lib}}` | `{{export}}` | {{purpose}} | OK/FAIL |

## 3. Bypasses
| Protection | Method | Status |
|------------|--------|--------|
| SSL Pinning | TrustManager bypass | {{status}} |
| Root Detection | `File.exists` hook | {{status}} |
| Frida Detection | `open` / `strstr` hook | {{status}} |
| Emulator Check | {{method}} | {{status}} |

## 4. Data Collected
| # | Type | Source | Content |
|---|------|--------|---------|
| 1 | Decrypted | `Crypto.decrypt()` | {{data}} |
| 2 | API Key | `Config.getApiKey()` | {{data}} |
| 3 | Token | `Auth.getToken()` | {{data}} |

## 5. Key Findings
- {{finding}}
- {{finding}}

## 6. Script Source
```javascript
{{full_script_source}}
```

## 7. Recommendations
- {{recommendation}}
- {{recommendation}}
