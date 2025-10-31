#!/bin/bash
set -e

source <(curl -fsSL https://raw.githubusercontent.com/<user>/dotfiles/main/lib/logger.sh)

REPO="https://github.com/<user>/dotfiles"
TARGET="$HOME/.dotfiles"

log_step dots "Clonage du dépôt dotfiles..."
if [ -d "$TARGET" ]; then
  warn "Le dossier ~/.dotfiles existe déjà"
else
  git clone "$REPO" "$TARGET" || error "Échec du clonage du dépôt"
  ok "Dotfiles clonés dans ~/.dotfiles"
fi
