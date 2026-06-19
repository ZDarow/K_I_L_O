# Устранение проблем

---

## Установка

### Проблема: Pre-flight проверка не пройдена

**Причина:** Одно из требований не выполнено.

**Решение:**

```bash
# Проверить ОС
cat /etc/os-release

# Проверить sudo
sudo -v

# Проверить интернет
curl -I https://github.com

# Проверить место на диске
df -h ~

# Пропустить preflight
./install.sh --skip-preflight
```

### Проблема: Ошибка при установке Node.js

**Причина:** Проблемы с NodeSource репозиторием.

**Решение:**

```bash
# Установить Node.js вручную
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Или через nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 22
```

### Проблема: npm install не работает в ~/.kilo/

**Причина:** Отсутствует package.json или проблемы с сетью.

**Решение:**

```bash
cd ~/.kilo
npm install
# Или с флагом --legacy-peer-deps
npm install --legacy-peer-deps
```

### Проблема: Установка прервана на середине

**Причина:** Обрыв соединения, сигнал SIGINT.

**Решение:**

```bash
# Продолжить с шага N
./install.sh --resume-from=5
# где 5 — номер шага, с которого продолжить
```

---

## SSH

### Проблема: SSH-ключ не работает

**Причина:** Отсутствует приватный ключ или неправильные права.

**Решение:**

```bash
# Скопировать приватный ключ
# (должен быть предоставлен отдельно)

# Установить правильные права
chmod 600 ~/.ssh/id_ed25519
chmod 700 ~/.ssh
```

### Проблема: git push требует пароль

**Причина:** SSH-ключ не добавлен в GitHub/GitLab.

**Решение:**

```bash
# Показать публичный ключ
cat ~/.ssh/id_ed25519.pub

# Добавить ключ в GitHub: Settings → SSH and GPG keys → New SSH key
```

---

## KiloCode CLI

### Проблема: npx kilo: команда не найдена

**Причина:** KiloCode CLI не установлен глобально.

**Решение:**

```bash
# Установить вручную
npm install -g @kilocode/cli

# Или запустить напрямую
npx --yes @kilocode/cli
```

### Проблема: API-ключ не настроен

**Причина:** В `auth.json` не заменён ключ.

**Решение:**

```bash
nano ~/.local/share/kilo/auth.json
# Заменить "YOUR_API_KEY_HERE" на реальный API-ключ
```

### Проблема: Агент dev не загружается

**Причина:** Отсутствует файл агента или ошибка в YAML-фронтматере.

**Решение:**

```bash
# Проверить наличие файла
ls -la ~/.kilo/agent/dev.md

# Проверить синтаксис YAML (первые строки файла)
head -10 ~/.kilo/agent/dev.md
```

---

## Shell-конфигурация

### Проблема: алиасы KiloCode не работают

**Причина:** Не выполнен `source ~/.bashrc`.

**Решение:**

```bash
source ~/.bashrc
```

### Проблема: PATH не обновлён

**Причина:** Не выполнен `source ~/.profile`.

**Решение:**

```bash
source ~/.profile
```

---

## Makefile

### Проблема: make: команда не найдена

**Причина:** make не установлен.

**Решение:**

```bash
sudo apt-get install -y build-essential
```

---

## Удаление

### Проблема: После uninstall остались файлы

**Причина:** uninstall.sh не удалил все компоненты.

**Решение:**

```bash
# Удалить вручную
rm -rf ~/.kilo
rm -rf ~/.config/kilo
rm -rf ~/.local/share/kilo

# Восстановить .bashrc и .profile из бэкапа
# Бэкапы находятся в /tmp/kilo-backup-*/
```

---

## Диагностика

```bash
# Собрать информацию о системе для отладки
echo "=== OS ==="
cat /etc/os-release
echo "=== Kernel ==="
uname -a
echo "=== Node ==="
node --version 2>/dev/null || echo "not installed"
echo "=== npm ==="
npm --version 2>/dev/null || echo "not installed"
echo "=== Python ==="
python3 --version 2>/dev/null || echo "not installed"
echo "=== Git ==="
git --version 2>/dev/null || echo "not installed"

echo "=== Kilo ==="
npx kilo --version 2>/dev/null || echo "KiloCode not installed"
echo "=== Manifest ==="
cat ~/.local/share/kilo/manifest.json 2>/dev/null || echo "no manifest"
```
