#!/bin/bash
set -e

# --- Configuration ---
GIT_USER="dargh"

source <(curl -fsSL https://raw.githubusercontent.com/$GIT_USER/dotfiles/main/lib/logger.sh)

log_step system "Initialisation du système..."
bash <(curl -fsSL https://raw.githubusercontent.com/$GIT_USER/dotfiles/main/scripts/init.sh)

log_step dots "Clonage des dotfiles..."
bash <(curl -fsSL https://raw.githubusercontent.com/$GIT_USER/dotfiles/main/scripts/dotfiles.sh)

log_step brew "Installation de Homebrew et des outils..."
bash <(curl -fsSL https://raw.githubusercontent.com/$GIT_USER/dotfiles/main/scripts/homebrew.sh)

log_step summary "Installation terminée. Lancement de Zsh..."
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
exec "$(brew --prefix)/bin/zsh"
