# APK Modification Report

## 1. Target Info
- **APK**: `{{apk_name}}`
- **Package**: `{{package_name}}`
- **Version**: `{{version_code}} ({{version_name}})`
- **Size**: `{{size_mb}} MB`
- **Protection**: `{{packer_type}}` (detected by APKiD)
- **Min/Target SDK**: `{{min_sdk}} / {{target_sdk}}`

## 2. Toolchain
- Decompiler: apktool {{apktool_version}}, jadx {{jadx_version}}
- RE tools: {{tools_used}}
- Signing: {{signing_method}}

## 3. Modifications

### 3.1 Smali Patches
| # | File | Line | Original | Patched | Purpose |
|---|------|------|----------|---------|---------|
| 1 | `{{file}}` | {{line}} | `{{original}}` | `{{patched}}` | {{purpose}} |

### 3.2 Resource Injections
| # | Resource | Action | Details |
|---|----------|--------|---------|
| 1 | `{{path}}` | replace/add | {{details}} |

### 3.3 Native Library Modifications
| # | Library | Change | Method |
|---|---------|--------|--------|
| 1 | `{{lib.so}}` | {{change}} | {{method}} |

### 3.4 AndroidManifest Changes
| # | Change | Reason |
|---|--------|--------|
| 1 | `{{permission/element}}` | {{reason}} |

## 4. Verification

### Build
- [ ] apktool rebuild: {{status}}
- [ ] zipalign: {{status}}
- [ ] apksigner verify: {{status}}

### Installation
- [ ] Android {{api_level}}: {{status}}
- [ ] ADB install: {{status}}
- [ ] Launch: {{status}}

### Functional
- [ ] Core flow intact: {{status}}
- [ ] Modification active: {{status}}
- [ ] No crash on startup: {{status}}
- [ ] No crash on target action: {{status}}

## 5. Risks & Limitations
| Risk | Severity | Mitigation |
|------|----------|------------|
| {{risk}} | High/Med/Low | {{mitigation}} |

## 6. Artifacts
- Modified APK: `{{path}}`
- Keystore: `{{path}}`
- Patch rules: `{{path}}`

## 7. Notes
{{notes}}
