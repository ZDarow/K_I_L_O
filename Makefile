# KiloCode CLI Installer — Makefile
# Usage: make <target>

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.ONESHELL:

# ─── Пути к инструментам ─────────────────────────
YAMLLINT := $(shell command -v yamllint 2>/dev/null || echo "$HOME/.local/bin/yamllint")
SHELLCHECK := $(shell command -v shellcheck 2>/dev/null || echo "")
BATS := $(shell command -v bats 2>/dev/null || echo "")
ACTIONLINT := $(shell command -v actionlint 2>/dev/null || echo "$HOME/go/bin/actionlint")
SHFMT := $(shell command -v shfmt 2>/dev/null || echo "$HOME/go/bin/shfmt")
PRECOMMIT := $(shell command -v pre-commit 2>/dev/null || echo "$HOME/.local/bin/pre-commit")
MARKDOWNLINT := $(shell command -v markdownlint 2>/dev/null || echo "")

# ─── Цели ────────────────────────────────────────
.PHONY: help install uninstall check verify dry-run version backup clean lint lint-shell lint-yaml lint-markdown lint-actions lint-shfmt lint-precommit test test-bats sync docker-build docker-test

help: ## Показать справку
	@echo "KiloCode CLI Installer"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: check ## Полная установка (с предварительной проверкой)
	@./install.sh

uninstall: ## Полное удаление Kilo
	@./uninstall.sh

uninstall-dry-run: ## Просмотреть что будет удалено (без удаления)
	@./uninstall.sh --dry-run

check: ## Pre-flight проверка системы перед установкой
	@./scripts/preflight.sh

verify: ## Пост-установочная проверка целостности
	@./scripts/verify.sh

dry-run: check ## Сухой прогон установки (без реальных изменений)
	@INSTALL_DRY_RUN=1 ./install.sh

version: ## Показать версию установщика
	@./scripts/lib.sh && show_version

backup: ## Создать бэкап текущих конфигов в /tmp/
	@echo "Создание бэкапа в /tmp/kilo-backup-$$(date +%Y%m%d-%H%M%S)/"
	@mkdir -p /tmp/kilo-backup-$$(date +%Y%m%d-%H%M%S)
	@[ -d ~/.kilo ] && cp -r ~/.kilo /tmp/kilo-backup-$$(date +%Y%m%d-%H%M%S)/.kilo && echo "  ~/.kilo сохранён" || echo "  ~/.kilo не найден"
	@[ -d ~/.config/kilo ] && cp -r ~/.config/kilo /tmp/kilo-backup-$$(date +%Y%m%d-%H%M%S)/.config-kilo && echo "  ~/.config/kilo сохранён" || echo "  ~/.config/kilo не найден"
	@echo "Готово."

clean: ## Очистить временные файлы установщика
	@rm -f /tmp/kilo-install-*.log
	@echo "Логи установки очищены."

# ─── Линтинг ─────────────────────────────────────
lint: lint-shell lint-yaml lint-markdown lint-actions lint-shfmt ## Запустить все линтеры

lint-shell: ## Проверить shell-скрипты через shellcheck
	@echo "━━━ ShellCheck ━━━"
	@if [ -z "$(SHELLCHECK)" ]; then
		echo "  [!] shellcheck не установлен. Установи: sudo apt-get install -y shellcheck"
		exit 1
	else
		$(SHELLCHECK) -x -Calways install.sh
		$(SHELLCHECK) -x -Calways uninstall.sh
		$(SHELLCHECK) -x -Calways scripts/*.sh
		$(SHELLCHECK) -x -Calways src/bashrc-append.sh src/profile-append.sh
		@echo "  [✓] ShellCheck: 0 ошибок"
	fi

lint-yaml: ## Проверить YAML-файлы через yamllint
	@echo "━━━ yamllint ━━━"
	@if ! command -v yamllint &>/dev/null && [ ! -f "$(YAMLLINT)" ]; then
		echo "  [!] yamllint не установлен. Установи: pip3 install --user yamllint"
		exit 1
	else
		find . -not -path './.git/*' -not -path './.kilo/node_modules/*' -not -path './.config/*' -not -path './src/dot-kilo/node_modules/*' \( -name '*.yml' -o -name '*.yaml' \) -print0 | xargs -0 -r $(YAMLLINT) -c .yamllint.yml
		@echo "  [✓] yamllint: 0 ошибок"
	fi

lint-markdown: ## Проверить Markdown-файлы через markdownlint
	@echo "━━━ Markdown Lint ━━━"
	@if ! command -v markdownlint &>/dev/null; then
		echo "  [!] markdownlint не установлен. Установи: npm install -g markdownlint-cli"
		exit 1
	else
		markdownlint --ignore node_modules --ignore .kilo --ignore .config --ignore src/dot-kilo --ignore .git --config .markdownlint.yml '**/*.md'
		@echo "  [✓] markdownlint: 0 ошибок"
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
		$(SHFMT) -d -i 2 -bn -ci install.sh uninstall.sh scripts/*.sh src/*.sh tests/*.bats
		@echo "  [✓] shfmt: все файлы отформатированы"
	fi

format-shfmt: ## Отформатировать shell-скрипты через shfmt
	@echo "━━━ shfmt (форматирование) ━━━"
	@$(SHFMT) -w -i 2 -bn -ci install.sh uninstall.sh scripts/*.sh src/*.sh tests/*.bats
	@echo "  [✓] Форматирование завершено"

lint-precommit: ## Проверить через pre-commit хуки
	@echo "━━━ pre-commit ━━━"
	@if [ ! -x "$(PRECOMMIT)" ]; then
		echo "  [!] pre-commit не установлен. Установи: pipx install pre-commit"
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
	docker build -t kilo-test .

docker-test: docker-build ## Запустить тесты в Docker-контейнере
	docker run --rm kilo-test bash -c "cd /opt/kilo && bats tests/"

docker-install-test: docker-build ## Протестировать установку в Docker
	docker run --rm kilo-test bash -c "cd /opt/kilo && make install && make verify"

# ─── Синхронизация ───────────────────────────────
sync: ## Синхронизировать src/dot-kilo/ из .kilo/
	@echo "━━━ Синхронизация src/dot-kilo/ ← .kilo/ ━━━"
	@errors=0
	@for f in $$(find .kilo -not -path './.kilo/node_modules/*' -not -name 'package-lock.json' -type f | sed 's|^.kilo/||' | sort); do
		src="src/dot-kilo/$$f"
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

sync-check: ## Проверить синхронизацию src/dot-kilo/ и .kilo/
	@echo "━━━ Проверка синхронизации ━━━"
	@errors=0
	@for f in $$(find src/dot-kilo -not -path '*/node_modules/*' -not -name 'package-lock.json' -type f | sed 's|^src/dot-kilo/||' | sort); do
		src="src/dot-kilo/$$f"
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
