# KiloCode CLI Installer — Makefile
# Usage: make <target>

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.ONESHELL:

# ─── Цели ────────────────────────────────────────
.PHONY: help install uninstall check verify dry-run version backup clean

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

uninstall: ## Полное удаление KiloCode и BLE-проекта
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
