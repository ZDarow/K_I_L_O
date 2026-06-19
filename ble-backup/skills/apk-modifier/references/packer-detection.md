# Packer / Protector Detection

## Detection Methods

### 1. APKiD (рекомендуется)
```bash
apkid app.apk
```
Определяет: Tencent Legu, 360 Jiagu, Bangcle, Qihoo, Ali, Baidu, Tencent, etc.

### 2. Manual — AndroidManifest.xml
Ищем подозрительные компоненты:
```bash
grep -E "stub|proxy|protect|guard|shell|packer" AndroidManifest.xml
```

### 3. Manual — Native libraries
Упаковщики часто добавляют свои .so:
```bash
unzip -l app.apk | grep "lib/"
# Ищите: libshell.so, libjiagu.so, libprotect.so, libDexHelper.so
```

### 4. Manual — Classes.dex
Маленький classes.dex (< 100KB) + много дополнительных .dex = упаковщик
```bash
unzip -l app.apk | grep "\.dex"
```

## Common Packers

| Packer | Signature | Difficulty | Notes |
|--------|-----------|------------|-------|
| **Tencent Legu** | libshell.so, libDexHelper.so | Medium | Можно распаковать через Frida + dumpDex |
| **360 Jiagu** | libjiagu.so, .jiagu/ | Medium | Frida dump, отработанная техника |
| **Bangcle** | libsecexe.so, libsecmain.so | High | Требует ручного распаковщика |
| **Baidu Aladin** | libbaiduprotect.so | Medium | Frida dump |
| **Ali** | libsgmain.so, libsgsecurity.so | Medium | Frida dump |
| **Tencent Shell** | libshell.so | Low-Medium | Часто просто обфускация |
| **Qihoo** | libprotect.so | Medium | Frida dump |

## Unpacking Strategy

### Step 1: Identify packer (APKiD)
### Step 2: Choose tool
- Legu → Frida script `dump_dex.js`
- Jiagu → Frida script `dump_jiagu.js`
- Unknown → Generic `frida-dump-dex`

### Step 3: Runtime dump
```bash
frida -U -f com.target.app -l dump_dex.js --no-pause
```

### Step 4: Reconstruct DEX from dump
```bash
python3 reconstruct_dex.py dump_dir/ classes.dex
```

### Step 5: Decompile unpacked DEX
```bash
jadx classes.dex
```

## If Unpacking Fails

| Symptom | Likely | Alternative |
|---------|--------|-------------|
| Anti-Frida detection | App checks for Frida | Use Frida Gadget + rename |
| Anti-emulator | Emulator check | Use physical device |
| Timeout on unpack | Online unpacker needed | Upload to 网易加固/ 360 |
| VM protection | DEX is in custom VM | Ghidra + manual analysis |
