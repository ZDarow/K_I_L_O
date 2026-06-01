#!/usr/bin/env bash
set -e

echo "=== BLE Environment Setup ==="

# Install system packages
sudo apt-get update -qq
sudo apt-get install -y -qq \
  python3-pip python3.12-venv python3-dev \
  tshark cmake \
  libglib2.0-dev

# Create and activate virtual environment
python3 -m venv "$(dirname "$0")/../.venv"
source "$(dirname "$0")/../.venv/bin/activate"

# Install Python BLE libraries
pip install --upgrade pip
pip install bleak bumble bleson bluepy pygatt

# Verify
python3 -c "
import bleak, bumble, bleson
print('bleak:', bleak.__version__)
print('bumble:', bumble.__version__)
print('bleson:', bleson.__version__)
"

# Start bluetooth service
sudo systemctl start bluetooth

echo ""
echo "=== Setup complete ==="
echo "Activate: source $(dirname "$0")/../.venv/bin/activate"
