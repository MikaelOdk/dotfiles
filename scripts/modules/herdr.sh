#!/bin/bash
set -euo pipefail
# Install Herdr terminal workspace manager

install_herdr() {
    echo "Installing Herdr..."

    if command -v herdr &> /dev/null; then
        echo "Herdr already installed"
        herdr --version || true
        return
    fi

    curl -fsSL https://herdr.dev/install.sh | sh

    echo "Herdr installed!"
}

install_herdr
