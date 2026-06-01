# Common Smali Patches

## 1. Bypass license / trial check

### Pattern A: boolean return
```smali
# Original:
invoke-virtual {v0}, Lcom/app/LicenseManager;->isLicensed()Z
move-result v0
if-eqz v0, :cond_skip

const/4 v0, 0x0
invoke-static {v0}, Ljava/lang/System;->exit(I)V

:cond_skip
# ... app continues

# Patched:
invoke-virtual {v0}, Lcom/app/LicenseManager;->isLicensed()Z
move-result v0
const/4 v0, 0x1        # force true
if-eqz v0, :cond_skip   # always true → always skip
```

### Pattern B: goto override
```smali
# Original:
if-eqz v0, :cond_fail
# ... success path ...
:cond_fail
# ... error/finish ...

# Patched (find :cond_fail, go directly):
goto :cond_success
:cond_fail
# ... never reached
```

### Pattern C: const-string comparison
```smali
# Original:
const-string v1, "trial"
invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
move-result v0
if-eqz v0, :cond_trial

# Patched: change const-string
const-string v1, "premium"   # вместо "trial"
invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
```

## 2. Remove ads

### Pattern: Ad class loading
```smali
# Original:
invoke-static {}, Lcom/app/ads/AdManager;->showBanner()V

# Patched: remove (nop out)
# Replace the invoke with nops
nop
nop
nop
# Or: comment out by creating unused method
return-void   # if it was the only thing in method
```

## 3. Change network endpoint

### Pattern: const-string URL
```smali
# Original:
const-string v2, "https://prod.api.example.com"

# Patched:
const-string v2, "https://debug.mydomain.com:8443"
```

### Pattern: StringBuilder URL assembly
```smali
# Original:
const-string v3, "api"
const-string v4, ".example.com"
invoke-static {v3, v4}, Ljava/lang/String;->concat(Ljava/lang/String;)Ljava/lang/String;

# Patched:
const-string v3, "debug"
const-string v4, ".mydomain.com"
```

## 4. Bypass root detection

### Pattern: Root check result
```smali
# Original:
invoke-static {}, Lcom/app/SecurityCheck;->isDeviceRooted()Z
move-result v0
if-eqz v0, :cond_blocked

# Patched:
invoke-static {}, Lcom/app/SecurityCheck;->isDeviceRooted()Z
move-result v0
const/4 v0, 0x0        # force false (not rooted)
if-eqz v0, :cond_blocked  # never taken
```

## 5. Remove signature verification

### Pattern: PackageManager signature check
```smali
# Original:
invoke-virtual {v0}, Landroid/content/pm/PackageManager;->getPackageInfo(Ljava/lang/String;I)Landroid/content/pm/PackageInfo;
move-result-object v1
iget-object v1, v1, Landroid/content/pm/PackageInfo;->signatures:[Landroid/content/pm/Signature;

# Patched (Frida, not smali):
# Hook getPackageInfo to return modified PackageInfo
```

## Patch Application Commands
```bash
# Single file replacement
sed -i 's/if-eqz v0, :cond_fail/goto :cond_success/g' smali/com/app/Check.smali

# Using patch-apk.sh with rules file
./scripts/patch-apk.sh decompiled/ patches.txt out/
```

## Verification After Patch
```bash
# Check patch applied
grep -n "goto\|const/4 v0, 0x1" patched/smali/com/app/Check.smali

# Rebuild & sign
apktool b patched/ -o modified.apk
# ... sign and install
```
