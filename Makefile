# KiloCode CLI Installer — Makefile
# Usage: make <target>

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.ONESHELL:

# ─── Пути к инструментам ─────────────────────────
UV := $(shell command -v uv 2>/dev/null || echo "$${HOME}/.local/bin/uv")
YAMLLINT := $(shell command -v yamllint 2>/dev/null || echo "$${HOME}/.local/bin/yamllint")
BLE_SCRIPTS := $(wildcard ble-project/scripts/setup-env.sh ble-project/scripts/activate.sh)
SHELLCHECK := $(shell command -v shellcheck 2>/dev/null || echo "")
BATS := $(shell command -v bats 2>/dev/null || echo "")
ACTIONLINT := $(shell command -v actionlint 2>/dev/null || echo "$${HOME}/go/bin/actionlint")
SHFMT := $(shell command -v shfmt 2>/dev/null || echo "$${HOME}/go/bin/shfmt")
PRECOMMIT := $(shell command -v pre-commit 2>/dev/null || echo "$${HOME}/.local/bin/pre-commit")
MARKDOWNLINT := $(shell command -v markdownlint 2>/dev/null || echo "")
GIT_TAG := $(shell git describe --tags --abbrev=0 2>/dev/null || true)

# ─── Цели ────────────────────────────────────────
.PHONY: help install check verify dry-run uninstall version backup clean lint lint-shell lint-yaml lint-markdown lint-jsonc lint-actions lint-shfmt lint-precommit test test-bats sync sync-global sync-check docker-build docker-test git-hooks uv-sync uv-update uv-list gui-start gui-open

help: ## Показать справку
	@echo "KiloCode CLI Installer"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' "$(MAKEFILE_LIST)" | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: check ## Полная установка (с предварительной проверкой)
	@./install.sh

check: ## Pre-flight проверка системы
	@./install.sh --check

verify: ## Пост-установочная проверка
	@./install.sh --verify

uninstall: ## Полное удаление Kilo
	@./install.sh --uninstall

dry-run: check ## Сухой прогон установки (без реальных изменений)
	INSTALL_DRY_RUN=1 ./install.sh

version: ## Показать версию установщика
	@if [ -n "$(GIT_TAG)" ]; then \
		echo "KiloCode CLI Installer $(GIT_TAG)"; \
	else \
		grep '^KILO_VERSION=' scripts/lib.sh | cut -d'"' -f2 | xargs -I{} echo "KiloCode CLI Installer v{}"; \
	fi

backup: ## Создать бэкап текущих конфигов в /tmp/
	@ts=$$(date +%Y%m%d-%H%M%S); \
	echo "Создание бэкапа в /tmp/kilo-backup-$$ts/"; \
	mkdir -p "/tmp/kilo-backup-$$ts"; \
	[ -d ~/.kilo ] && cp -r ~/.kilo "/tmp/kilo-backup-$$ts/.kilo" && echo "  ~/.kilo сохранён" || echo "  ~/.kilo не найден"; \
	[ -d ~/.config/kilo ] && cp -r ~/.config/kilo "/tmp/kilo-backup-$$ts/.config-kilo" && echo "  ~/.config/kilo сохранён" || echo "  ~/.config/kilo не найден"; \
	echo "Готово."

clean: ## Очистить временные файлы установщика
	@rm -f /tmp/kilo-install-*.log
	@echo "Логи установки очищены."

# ─── Линтинг ─────────────────────────────────────
lint: lint-shell lint-yaml lint-markdown lint-jsonc lint-actions lint-shfmt ## Запустить все линтеры

lint-shell: ## Проверить shell-скрипты через shellcheck
	@echo "━━━ ShellCheck ━━━"
	@if [ -z "$(SHELLCHECK)" ]; then
		echo "  [!] shellcheck не установлен. Установи: sudo apt-get install -y shellcheck"
		exit 1
	else
		$(SHELLCHECK) -x -Calways --severity=style install.sh src/bashrc-append.sh src/profile-append.sh $(BLE_SCRIPTS) tests/*.bats
		@echo "  [✓] ShellCheck: 0 ошибок"
	fi

lint-yaml: ## Проверить YAML-файлы через yamllint
	@echo "━━━ yamllint ━━━"
	@if ! command -v yamllint &>/dev/null && [ ! -f "$(YAMLLINT)" ]; then
		echo "  [!] yamllint не установлен. Установи: uv sync  или  uv tool install yamllint"
		exit 1
	else
		find . -not -path './.git/*' -not -path './.kilo/node_modules/*' -not -path './.config/*' -not -path './src/kilo-config/node_modules/*' -not -path './.venv/*' -not -path './ble-project/.venv/*' \( -name '*.yml' -o -name '*.yaml' \) -print0 | xargs -0 -r $(YAMLLINT) -c .yamllint.yml
		@echo "  [✓] yamllint: 0 ошибок"
	fi

lint-markdown: ## Проверить Markdown-файлы через markdownlint
	@echo "━━━ Markdown Lint ━━━"
	@if ! command -v markdownlint &>/dev/null; then
		echo "  [!] markdownlint не установлен. Установи: npm install -g markdownlint-cli"
		exit 1
	else
		markdownlint --ignore node_modules --ignore .kilo --ignore .config --ignore src/kilo-config --ignore .git --config .markdownlint.yml '**/*.md'
		@echo "  [✓] markdownlint: 0 ошибок"
	fi

lint-jsonc: ## Проверить JSONC-файлы через json5
	@echo "━━━ JSONC lint ━━━"
	@if ! command -v json5 &>/dev/null; then
		echo "  [!] json5 не установлен. Пропускаю. Установи: npm install -g json5"
	else
		errors=0
		find . -name '*.jsonc' -not -path './node_modules/*' -not -path './.kilo/node_modules/*' -not -path './.git/*' -print0 | while IFS= read -r -d '' f; do
			if ! json5 "$$f" > /dev/null 2>&1; then
				echo "  [✗] $$f"
				errors=$$((errors + 1))
			fi
		done
		if [ "$$errors" -eq 0 ]; then
			echo "  [✓] json5: все файлы валидны"
		else
			echo "  [✗] Найдено $$errors ошибок"
			exit 1
		fi
	fi

lint-actions: ## Проверить GitHub Actions workflow через actionlint
	@echo "━━━ actionlint ━━━"
	@if [ ! -x "$(ACTIONLINT)" ]; then
		echo "  [!] actionlint не установлен. Установи: go install github.com/rhysd/actionlint/cmd/actionlint@latest"
		exit 1
	else
		$(ACTIONLINT)
		@echo "  [✓] actionlint: 0 ошибок"
	fi

lint-shfmt: ## Проверить форматирование shell-скриптов через shfmt
	@echo "━━━ shfmt ━━━"
	@if [ ! -x "$(SHFMT)" ]; then
		echo "  [!] shfmt не установлен. Установи: go install mvdan.cc/sh/v3/cmd/shfmt@latest"
		exit 1
	else
		$(SHFMT) -d -i 2 -bn -ci install.sh scripts/lib.sh src/*.sh tests/*.bats
		@echo "  [✓] shfmt: все файлы отформатированы"
	fi

format-shfmt: ## Отформатировать shell-скрипты через shfmt
	@echo "━━━ shfmt (форматирование) ━━━"
	@$(SHFMT) -w -i 2 -bn -ci install.sh scripts/lib.sh src/*.sh tests/*.bats
	@echo "  [✓] Форматирование завершено"

lint-precommit: uv-sync ## Проверить через pre-commit хуки
	@echo "━━━ pre-commit ━━━"
	@if [ ! -x "$(PRECOMMIT)" ]; then
		echo "  [!] pre-commit не установлен. Установи: uv sync  или  uv tool install pre-commit"
		exit 1
	else
		$(PRECOMMIT) run --all-files
	fi

# ─── Тесты ───────────────────────────────────────
test: test-bats ## Запустить все тесты

test-bats: ## Запустить bats-тесты для bash-скриптов
	@echo "━━━ BATS Tests ━━━"
	@if [ -z "$(BATS)" ]; then
		echo "  [!] bats не установлен. Установи:"
		echo "    git clone https://github.com/bats-core/bats-core.git /tmp/bats"
		echo "    cd /tmp/bats && sudo ./install.sh /usr/local"
		exit 1
	else
		$(BATS) tests/
		@echo "  [✓] BATS: все тесты пройдены"
	fi

# ─── Docker ──────────────────────────────────────
docker-build: ## Собрать Docker-образ для тестирования
	docker build -f docker/Dockerfile -t kilo-test .

docker-test: docker-build ## Запустить тесты в Docker-контейнере
	docker run --rm kilo-test bash -c "cd /opt/kilo && bats tests/"

docker-install-test: docker-build ## Протестировать установку в Docker
	docker run --rm kilo-test bash -c "cd /opt/kilo && make install && make verify"

# ─── Синхронизация ───────────────────────────────
sync: ## Синхронизировать src/kilo-config/ из .kilo/
	@echo "━━━ Синхронизация src/kilo-config/ ← .kilo/ ━━━"
	@errors=0
	@for f in $$(find .kilo -not -path './.kilo/node_modules/*' -not -name 'package-lock.json' -type f | sed 's|^.kilo/||' | sort); do
		src="src/kilo-config/$$f"
		kilo=".kilo/$$f"
		mkdir -p "$$(dirname "$$src")"
		if [ -f "$$kilo" ]; then
			if [ -f "$$src" ]; then
				if ! diff -q "$$src" "$$kilo" >/dev/null 2>&1; then
					cp "$$kilo" "$$src"
					echo "  [✓] Синхронизирован: $$f"
				fi
			else
				cp "$$kilo" "$$src"
				echo "  [✓] Создан: $$f"
			fi
		fi
	done
	@echo "  Готово."

sync-check: ## Проверить синхронизацию src/kilo-config/ и .kilo/
	@echo "━━━ Проверка синхронизации ━━━"
	@errors=0
	@for f in $$(find src/kilo-config -not -path '*/node_modules/*' -not -name 'package-lock.json' -type f | sed 's|^src/kilo-config/||' | sort); do
		src="src/kilo-config/$$f"
		kilo=".kilo/$$f"
		if [ ! -f "$$kilo" ]; then
			echo "  [!] Только в src: $$f"
			errors=$$((errors + 1))
		elif ! diff -q "$$src" "$$kilo" >/dev/null 2>&1; then
			echo "  [✗] Различается: $$f"
			errors=$$((errors + 1))
		fi
	done
	@if [ "$$errors" -eq 0 ]; then
		echo "  [✓] Все файлы синхронизированы"
	else
		echo "  [✗] Найдено $$errors расхождений. Запусти 'make sync'"
	fi

sync-global: ## Синхронизировать src/global-config/ из .config/kilo/
	@echo "━━━ Синхронизация src/global-config/ ← .config/kilo/ ━━━"
	@for f in $$(find .config/kilo -not -name 'package-lock.json' -type f | sed 's|^.config/kilo/||' | sort); do
		src=".config/kilo/$$f"
		dest="src/global-config/$$f"
		mkdir -p "$$(dirname "$$dest")"
		if [ -f "$$dest" ]; then
			if ! diff -q "$$src" "$$dest" >/dev/null 2>&1; then
				cp "$$src" "$$dest"
				echo "  [✓] Синхронизирован: $$f"
			fi
		else
			cp "$$src" "$$dest"
			echo "  [✓] Создан: $$f"
		fi
	done
	@echo "  Готово."

# ─── Python/uv targets ────────────────────────────
uv-sync: ## Синхронизировать Python-зависимости (uv sync)
	@echo "━━━ uv sync ━━━"
	@if [ -z "$(UV)" ] || ! command -v $(UV) &>/dev/null; then
		echo "  [!] uv не установлен. Установи: curl -LsSf https://astral.sh/uv/install.sh | sh"
		exit 1
	else
		$(UV) sync
		@echo "  [✓] Зависимости синхронизированы"
	fi

uv-update: ## Обновить Python-зависимости (uv lock + sync)
	@echo "━━━ uv update ━━━"
	@if [ -z "$(UV)" ] || ! command -v $(UV) &>/dev/null; then
		echo "  [!] uv не установлен."
		exit 1
	else
		$(UV) lock --upgrade
		$(UV) sync
		@echo "  [✓] Зависимости обновлены"
	fi

uv-list: ## Показать установленные Python-пакеты
	@echo "━━━ uv list ━━━"
	@$(UV) pip list 2>/dev/null || $(UV) run pip list 2>/dev/null || echo "  [i] Нет Python-пакетов в проекте"

# ─── GUI ─────────────────────────────────────────
gui-start: ## Запустить веб-интерфейс (http://localhost:8088)
	@echo "━━━ K_I_L_O GUI ━━━"
	@python3 gui/server.py

gui-open: ## Открыть GUI в браузере
	@python3 -c "import webbrowser; webbrowser.open('http://localhost:8088')" 2>/dev/null || \
		xdg-open http://localhost:8080 2>/dev/null || \
		echo "  Открой http://localhost:8088 в браузере"

# ─── Git hooks ────────────────────────────────────
git-hooks: ## Установить pre-commit хуки (.githooks/pre-commit)
	@echo "━━━ Установка Git hooks ━━━"
	@if [ -d .githooks ]; then
		git config core.hooksPath .githooks
		chmod +x .githooks/*
		echo "  [✓] Хуки установлены: $$(git config core.hooksPath)"
	else
		echo "  [!] Директория .githooks/ не найдена"
		exit 1
	fi
