# Tool Setup Guide

## Ubuntu / Debian
```bash
# Java
sudo apt-get install openjdk-17-jdk

# Core tools
sudo apt-get install apktool jadx unzip zipalign

# Python tools
pip install frida-tools apkid

# Signing
sudo apt-get install apksigner

# RE
sudo apt-get install radare2
# Ghidra: download from ghidra-sre.org (requires Java 17)
```

## Arch Linux
```bash
sudo pacman -S apktool jadx unzip jdk17-openjdk
pip install frida-tools apkid
# Ghidra: yay -S ghidra
```

## macOS
```bash
brew install apktool jadx unzip openjdk@17
pip3 install frida-tools apkid
# Ghidra: brew install --cask ghidra
```

## Verify Installation
```bash
# Java
java -version

# Core
apktool --version
jadx --version
frida --version
apksigner --version
zipalign 2>&1 | head -1
apkid --help >/dev/null && echo "APKiD OK"
```
