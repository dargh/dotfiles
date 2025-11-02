#!/bin/bash
set -e

# --- Configuration ---
GIT_USER="dargh"

source <(curl -fsSL https://raw.githubusercontent.com/$GIT_USER/dotfiles/main/lib/logger.sh)

REPO="https://github.com/$GIT_USER/dotfiles"
TARGET="$HOME/.dotfiles"

log_step dots "Clonage du dépôt dotfiles..."
if [ -d "$TARGET" ]; then
  warn "Le dossier ~/.dotfiles existe déjà, suppression..."
  rm -rf "$TARGET" || error "Échec de la suppression du dossier existant
else
  git clone "$REPO" "$TARGET" || error "Échec du clonage du dépôt"
  ok "Dotfiles clonés dans ~/.dotfiles"
fi