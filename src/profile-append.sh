#!/usr/bin/env bash
# ============================================
# Блок установки KiloCode CLI
# Добавлено установщиком K_I_L_O
# ============================================

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ]; then
  PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then
  PATH="$HOME/.local/bin:$PATH"
fi
