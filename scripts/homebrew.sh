#!/bin/bash
set -e

# --- Configuration ---
GIT_USER="dargh"

source <(curl -fsSL https://raw.githubusercontent.com/$GIT_USER/dotfiles/main/lib/logger.sh)

log_step brew "Installation de Homebrew..."
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error "Échec de l'installation de Homebrew"

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" || error "Échec de l'initialisation de Homebrew"

log_step zsh "Installation de Zsh via Homebrew..."
brew install zsh || error "Échec de l'installation de Zsh"

ZSH_PATH="$(brew --prefix)/bin/zsh"
if ! grep -q "$ZSH_PATH" /etc/shells; then
  echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null || error "Impossible d'ajouter Zsh à /etc/shells"
fi

chsh -s "$ZSH_PATH" || error "Échec du changement de shell par défaut"

log_step apps "Installation des outils via Homebrew..."
brew install zoxide starship bat lazygit lsd fzf ripgrep btop fd duf gdu atuin procs tlrc yazi helix talespin 7zip || error "Échec de l'installation des outils"

log_step dots "Sauvegarde de l'ancien .zshrc..."
cp ~/.zshrc ~/.zshrc.backup.$(date +%s) 2>/dev/null && ok ".zshrc sauvegardé" || warn "Aucun .zshrc à sauvegarder"

log_step dots "Installation du nouveau .zshrc..."
cp ~/.dotfiles/config/.zshrc ~/.zshrc || error "Échec de la copie du .zshrc"
ok ".zshrc installé depuis dotfiles"
