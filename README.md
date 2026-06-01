# K_I_L_O — Установщик KiloCode CLI для Linux Mint

**Репозиторий:** [https://github.com/ZDarow/K_I_L_O](https://github.com/ZDarow/K_I_L_O)

Полная конфигурация AI-агента KiloCode для Linux Mint с русскоязычными правилами, BLE-инженерией и системными настройками.

## Быстрая установка

```bash
# Клонирование
git clone https://github.com/ZDarow/K_I_L_O.git /tmp/kilo-install
cd /tmp/kilo-install

# Запуск установщика
chmod +x install.sh
./install.sh
```

После установки выполни:

```bash
source ~/.bashrc
```

## Что устанавливается

### 1. KiloCode CLI

- `@kilocode/cli` (глобально через npm)
- Проектная конфигурация → `~/.kilo/`
- Глобальная конфигурация → `~/.config/kilo/`
- Агенты, команды, инструменты, инструкции, навыки

### 2. Системные компоненты

| Компонент | Версия | Источник |
|-----------|--------|----------|
| Node.js | 22 LTS | NodeSource |
| npm | последняя | NodeSource |
| Python | 3.12+ | apt |
| bluez-tools | последняя | apt |
| Git | последняя | apt |

### 3. BLE Engineering проект

- Структура `~/ble-project/` с поддиректориями
- Скрипты активации окружения
- Python-зависимости (bleak, bumble, bleson)

### 4. Системные настройки

- SSH-конфигурация (GitHub, GitLab)
- Shell-алиасы (.bashrc)
- Git-конфигурация (user.name, user.email, defaultBranch)
- PATH в .profile

## Структура репозитория

```
K_I_L_O/
├── install.sh                      # Главный установщик
├── README.md                       # Документация
├── AGENTS.md                       # Правила для Kilo-сессий
├── src/                            # Установочные файлы
│   ├── dot-kilo/                   # → ~/.kilo/
│   │   ├── kilo.jsonc
│   │   ├── agents/
│   │   ├── commands/
│   │   ├── tools/
│   │   ├── instructions/
│   │   └── skills/
│   ├── dot-config-kilo/            # → ~/.config/kilo/
│   │   ├── kilo.jsonc
│   │   ├── AGENTS.md
│   │   ├── agents/
│   │   └── instructions/
│   ├── dot-local-share-kilo/       # → ~/.local/share/kilo/
│   │   └── auth.template.json
│   ├── dot-ssh/                    # → ~/.ssh/
│   │   ├── config
│   │   └── id_ed25519.pub
│   └── bashrc-append.sh           # Дополнения .bashrc
├── .kilo/                          # Конфигурация для разработки установщика
├── ble-project/                    # BLE-инженерия
│   ├── scripts/
│   ├── logs/
│   └── ...
└── .gitignore
```

## Агенты KiloCode

| Агент | Тип | Описание |
|-------|-----|----------|
| `ble-engineer` | primary | BLE/Bluetooth reverse engineering (ESP32, Android, BlueZ) |
| `russian-dev` | primary | Русскоязычный ассистент разработки |
| `gatt-recovery` | subagent | GATT profile recovery из BLE-трафика |

## Настройка после установки

### 1. API-ключ

Получи API-ключ на [https://app.kilo.ai/settings](https://app.kilo.ai/settings) и сохрани:

```bash
nano ~/.local/share/kilo/auth.json
```

Формат:
```json
{
  "opencode": {
    "type": "api",
    "key": "sk-..."
  }
}
```

### 2. SSH-ключи

Скопируй приватный ключ `id_ed25519` в `~/.ssh/`:

```bash
chmod 600 ~/.ssh/id_ed25519
```

### 3. BLE-окружение

```bash
cd ~/ble-project
./scripts/setup-env.sh
source scripts/activate.sh
```

## Требования

- **ОС:** Linux Mint 21.x / 22.x (или Ubuntu 22.04+)
- **Права:** sudo (для установки пакетов)
- **Интернет:** для загрузки зависимостей

## Разработка

Если ты разрабатываешь этот установщик в KiloCode:

1. Этот репозиторий клонирован как `~/K_I_L_O/` (или `/tmp/kilo-install/`)
2. В корне лежит `AGENTS.md` — правила для сессий Kilo
3. `.kilo/` — конфигурация для разработки установщика
4. `src/` — исходники для установки на новую систему
