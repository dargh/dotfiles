#!/bin/bash

# --- Couleurs ---
GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

# --- Icônes ---
declare -A ICONS
ICONS=( ["system"]="⚙️" ["shell"]="🐟" ["brew"]="🍺" ["apps"]="📦" ["font"]="🎨" ["dots"]="🔗" ["plugin"]="🎣" ["summary"]="📜" ["dl"]="⬇️")

# --- Fonctions de log ---
log-step() {
  local step="$1"; local msg="$2"
  local icon="${ICONS[$step]} "
  [ -z "$icon" ] && icon="ℹ️"
  echo -e "\n$(date '+%H:%M:%S') $icon ${BLUE}$msg${NC}"
}

info() { echo -e "$(date '+%H:%M:%S') 🎃 ${MAGENTA}$1${NC}"; }
ok() { echo -e "$(date '+%H:%M:%S') ✅ ${GREEN}$1${NC}"; }
ok-step() { echo -e "$(date '+%H:%M:%S') ☑️ ${CYAN}$1${NC}"; }
warn() { echo -e "$(date '+%H:%M:%S') ⚠️ ${YELLOW}$1${NC}"; }
error() { echo -e "$(date '+%H:%M:%S') ❌ ${RED}$1${NC}"; exit 1; }

# Mise à jour du système
function update-system() {
    log-step system "Mise à jour du système..."
    sudo apt update && sudo apt upgrade -y || error "Échec de la mise à jour du système"
    ok "Système à jour"
}

# Installation des prérequis minimum pour Homebrew
function install-dependencies() {
  log-step system "Installation des dépendances nécessaires via apt..."
  sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    procps \
    file \
    unzip \
    ca-certificates || error "Échec de l'installation des dépendances"
  ok "Dépendances installées"
}

# Installation de Homebrew si non présent
function install-homebrew() {
  log-step brew "Vérification de l'installation de Homebrew..."
  if ! command -v brew &> /dev/null
  then
      log-step brew "Homebrew n'est pas installé. Installation en cours..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error "Échec de l'installation de Homebrew"
      ok "Homebrew installé"
  else
      warn "Homebrew est déjà installé."
  fi
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" || error "Échec de la configuration de l'environnement Homebrew"
}

# Installation de Fish et des applications via Homebrew
function install-fish-and-tools() {
  log-step apps "Installation de Fish et des outils via Homebrew..."
  brew install \
    fish \
    fisher \
    starship \
    bat \
    lazygit \
    lsd \
    ripgrep \
    btop \
    fd \
    duf \
    gdu \
    procs \
    tlrc \
    yazi \
    helix \
    7zip \
    fastfetch || error "Échec de l'installation de Fish et des outils"
  ok "Fish et les outils installés"
}

# Copie de la configuration Fish depuis le dépôt GitHub
function setup-fish-config() {
  log-step dl "Téléchargement de la configuration Fish depuis le dépôt GitHub..."
  REPO_URL="https://github.com/dargh/dotfiles.git"
  CLONE_DIR="$HOME/dotfiles"

  log-step dots "Suppression du dépôt existant s'il est présent..."
  if [ -d "$CLONE_DIR" ]; then
      rm -rf "$CLONE_DIR" || error "Impossible de supprimer $CLONE_DIR"
      warn "Ancien dossier dotfiles supprimé"
  fi
  ok-step "Prêt pour le clonage du dépôt dotfiles"

  log-step dots "Clonage du dépôt dotfiles..."
  if [ ! -d "$CLONE_DIR" ]; then
      git clone $REPO_URL "$CLONE_DIR" || error "Échec du clonage du dépôt dotfiles"
  fi
  ok-step "Clonage du dépôt dotfiles dans $CLONE_DIR"

  log-step dots "Copie de la configuration Fish..."
  echo "Copie du dossier fish..."
  mkdir -p "$HOME/.config/"
  cp -R "$CLONE_DIR/config/fish" "$HOME/.config" || error "Échec de la copie de la configuration Fish"
  ok-step "Dossier fish copié dans $HOME/.config/"

  ok "Configuration Fish copiée"
}

# Changement du shell par défaut pour Fish
function switch-shell-to-fish() {
  log-step shell "Changement du shell par défaut pour Fish..."
  FISH_PATH="$(brew --prefix)/bin/fish"
  if ! grep -q "$FISH_PATH" /etc/shells; then
      echo "$FISH_PATH" | sudo tee -a /etc/shells || error "Échec de l'ajout de Fish à /etc/shells"
  fi

  chsh -s "$FISH_PATH" || error "Échec du changement de shell par défaut pour Fish"
  ok "Shell par défaut changé pour Fish"
}

# Mise à jour du système, de tous les paquets Homebrew installés et des plugins Fisher
function update-fisher() {
  log-step plugin "Mise à jour des plugins Fisher..."
  fish -c "fisher update" || error "Échec de la mise à jour des plugins Fisher"
  ok "Plugins Fisher mis à jour"
}

# Configuration du thème Starship
function configure-starship() {
  log-step font "Configuration du thème Starship..."
  mkdir -p "$HOME/.config"
  CLONE_DIR="$HOME/dotfiles"
  cp "$CLONE_DIR/config/starship.toml" "$HOME/.config/starship.toml" || error "Échec de la copie de la configuration Starship"
  ok "Thème Starship configuré"
}

# Résumé de l'installation
function summarize() {
  log-step summary "Résumé de l'installation..."
  fish -c "starship --version"
  fish -c "fish --version"
  ok "Installation terminée avec succès"
}

# Exécution des fonctions dans l'ordre
info "Début de l'installation du système de développement avec Fish..."
START_TIME=$(date +%s)
update-system
install-dependencies
install-homebrew
install-fish-and-tools
setup-fish-config
switch-shell-to-fish
update-fisher
configure-starship
summarize
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
ok "Installation terminée en $DURATION secondes"
