# K_I_L_O — Установщик KiloCode CLI для Linux Mint

**Репозиторий:** [https://github.com/ZDarow/K_I_L_O](https://github.com/ZDarow/K_I_L_O)

Полная конфигурация AI-агента KiloCode для Linux Mint: русскоязычные правила, BLE-инженерия, системные настройки.

---

## Быстрая установка

```bash
git clone https://github.com/ZDarow/K_I_L_O.git /tmp/kilo-install
cd /tmp/kilo-install

make check     # pre-flight проверка системы
make install   # установка
make verify    # проверка целостности
```

Единая команда (с pre-flight):
```bash
make install
```

После установки:
```bash
source ~/.bashrc
```

---

## Makefile — точки входа

| Команда | Действие |
|---------|----------|
| `make check` | Pre-flight: ОС, sudo, диск, интернет, Node.js |
| `make install` | Полная установка (с предпроверкой) |
| `make verify` | Пост-проверка: файлы, checksums, команды |
| `make dry-run` | Сухой прогон — что будет сделано |
| `make uninstall` | Полное удаление всех компонентов |
| `make backup` | Бэкап текущих конфигов в `/tmp/` |
| `make clean` | Очистка логов установки |
| `make help` | Справка по целям |

Установщик также поддерживает флаги:
- `./install.sh --dry-run` — просмотр без изменений
- `./install.sh --resume-from=5` — продолжить с шага 5
- `./install.sh --skip-preflight` — без предпроверки

---

## Что устанавливается

### 1. KiloCode CLI (`~/.kilo/`)
- @kilocode/cli (глобально через npm)
- 3 агента: `ble-engineer`, `russian-dev`, `gatt-recovery`
- 3 команды: `ble-capture`, `ble-setup`, `gatt-discover`
- 3 инструмента: `ble-scan`, `hex-analyzer`, `gatt-to-yaml`
- Инструкции и навыки

### 2. Глобальная конфигурация (`~/.config/kilo/`)
- AGENTS.md — правила для всех сессий Kilo
- Агент `russian-dev` (русскоязычный)
- Инструкции и настройки

### 3. Системные компоненты
- Node.js 22 LTS (через NodeSource)
- Python 3.12+, bluez-tools, Git, tshark, cmake

### 4. BLE Engineering (`~/ble-project/`)
- Скрипты `setup-env.sh`, `activate.sh`
- Python-зависимости (bleak, bumble, bleson)
- Структура для логов, GATT-профилей, прошивок

### 5. Системные настройки
- SSH-конфигурация (GitHub, GitLab)
- Алиасы в `.bashrc`: `ble-activate`, `ble-env`, `ble-project`
- Git config: user.name, user.email, defaultBranch
- PATH в `.profile`

---

## Структура репозитория

```
K_I_L_O/
│
├── Makefile              # Точка входа: install, check, verify, uninstall
├── install.sh            # Главный установщик (13 шагов)
├── uninstall.sh          # Полный откат
│
├── scripts/              # Скрипты автоматизации
│   ├── lib.sh            #   Общая библиотека (цвета, backup, manifest)
│   ├── preflight.sh      #   Pre-flight проверка системы
│   └── verify.sh         #   Пост-установочная валидация
│
├── src/                  # Исходники для установки на новую систему
│   ├── dot-kilo/                  # → ~/.kilo/
│   │   ├── kilo.jsonc, agents/, commands/, tools/, instructions/, skills/
│   ├── dot-config-kilo/           # → ~/.config/kilo/
│   │   ├── kilo.jsonc, AGENTS.md, agents/, instructions/
│   ├── dot-local-share-kilo/      # → ~/.local/share/kilo/
│   │   └── auth.template.json
│   ├── dot-ssh/                   # → ~/.ssh/
│   │   ├── config, id_ed25519.pub
│   ├── bashrc-append.sh           # → ~/.bashrc (дополнения)
│   └── profile-append.sh          # → ~/.profile (дополнения)
│
├── .kilo/                # Dev-конфигурация для разработки установщика
├── ble-project/          # BLE-проект (копируется в ~/ble-project/)
│
├── AGENTS.md             # Правила для Kilo-сессий
├── .gitignore
└── README.md
```

---

## Агенты KiloCode

| Агент | Тип | Описание |
|-------|-----|----------|
| `ble-engineer` | primary | BLE/Bluetooth reverse engineering (ESP32, Android, BlueZ) |
| `russian-dev` | primary | Русскоязычный ассистент разработки |
| `gatt-recovery` | subagent | GATT profile recovery из BLE-трафика |

---

## После установки

### API-ключ

```bash
nano ~/.local/share/kilo/auth.json
```

```json
{
  "opencode": {
    "type": "api",
    "key": "sk-..."
  }
}
```

### SSH-ключи

Скопируй приватный ключ `id_ed25519` в `~/.ssh/`:

```bash
chmod 600 ~/.ssh/id_ed25519
```

### BLE-окружение

```bash
cd ~/ble-project
./scripts/setup-env.sh
source scripts/activate.sh
```

---

## Требования

- **ОС:** Linux Mint 21.x / 22.x или Ubuntu 22.04+
- **Права:** sudo
- **Интернет:** для загрузки зависимостей

## Разработка

Если ты разрабатываешь этот установщик в KiloCode:

1. Репозиторий клонируется в `/tmp/kilo-install/` или `~/K_I_L_O/`
2. `AGENTS.md` в корне — правила для Kilo-сессий
3. `.kilo/` — конфигурация для разработки установщика (не путать с `src/dot-kilo/`)
4. `src/` — исходники, которые `install.sh` копирует на целевую систему
