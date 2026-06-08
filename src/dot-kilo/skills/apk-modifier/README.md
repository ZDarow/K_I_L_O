# APK Modifier

Modification of APK files: decompilation, analysis, code injection, rebuild and signing.

## Usage

Activates automatically when APK modification tasks are detected.

## Dependencies

- [apktool](https://apktool.org/) — decompilation/rebuild
- [jadx](https://github.com/skylot/jadx) — Java decompilation
- `keytool` — signing key management
- `zipalign` — APK alignment
- `uber-apk-signer` — APK signing

## Resources

- `scripts/` — decompile, extract resources, patch, sign
- `templates/` — analysis and modification report templates
