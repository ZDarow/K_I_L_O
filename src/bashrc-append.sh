# ============================================
# Блок установки KiloCode CLI
# Добавлено установщиком K_I_L_O
# ============================================

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ---- BLE Engineering aliases ----
alias ble-activate='source $HOME/ble-project/scripts/activate.sh'
alias ble-env='source $HOME/ble-project/.venv/bin/activate'
alias ble-project='cd $HOME/ble-project'

# ---- KiloCode aliases ----
alias kilo='npx kilo'
alias kilocode='npx kilocode'
