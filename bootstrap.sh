#!/bin/bash
# ----------------------------------------------------------------------
# SCRIPT DE DÉMARRAGE MINIMAL (BOOTSTRAP)
# Rôle: Installer Git, demander les identifiants, et cloner le dépôt privé.
# ----------------------------------------------------------------------

DOTFILES_REPO_BASE="https://github.com/dargh/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# --- 1. FONCTIONS DE LOG SIMPLIFIÉES ---
log() { echo -e "\n\033[0;34m[INFO]\033[0m $1"; }
error() { echo -e "\n\033[0;31m[ERREUR]\033[0m $1"; exit 1; }

# --- 2. VÉRIFICATION ET INSTALLATION DE GIT ---
if ! command -v git >/dev/null 2>&1; then
    log "Installation des dépendances essentielles (Git)..."
    sudo apt update -qq && sudo apt install -y git || error "Échec de l'installation de Git."
fi

# --- 3. CONFIGURATION DE L'ACCÈS AU DÉPÔT PRIVÉ ---
log "Configuration de l'accès au dépôt privé (HTTPS/PAT)..."
echo -e "\033[0;33mVeuillez saisir les informations d'accès à votre dépôt dotfiles privé :\033[0m"
read -p "  [?] Votre nom d'utilisateur GitHub : " GITHUB_USER
[ -z "$GITHUB_USER" ] && error "Nom d'utilisateur ne peut être vide."
read -sp "  [?] Votre Personal Access Token (PAT) : " GITHUB_TOKEN
echo
[ -z "$GITHUB_TOKEN" ] && error "Token ne peut être vide."

# Création de l'URL avec authentification
DOTFILES_REPO=$(echo "$DOTFILES_REPO_BASE" | sed "s/https:\/\//https:\/\/$GITHUB_USER:$GITHUB_TOKEN@/")
log "URL d'accès sécurisée configurée."

# --- 4. CLONAGE DU DÉPÔT ---
if [ ! -d "$DOTFILES_DIR" ]; then
    log "Clonage du dépôt dotfiles dans $DOTFILES_DIR..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || error "Échec du clonage du dépôt. Vérifiez votre PAT et votre URL de dépôt."
else
    log "Le dépôt $DOTFILES_DIR existe déjà. Mise à jour..."
    (cd "$DOTFILES_DIR" && git remote set-url origin "$DOTFILES_REPO" && git pull) || error "Échec de la mise à jour du dépôt."
fi

# --- 5. LANCEMENT DU SCRIPT DE PROVISIONNEMENT COMPLET ---
log "Lancement du script de provisionnement complet ($DOTFILES_DIR/install.sh)..."
exec "$DOTFILES_DIR/install.sh"
