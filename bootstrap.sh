#!/bin/bash
# ----------------------------------------------------------------------
# SCRIPT DE DÉMARRAGE MINIMAL (BOOTSTRAP)
# Rôle: Utiliser les variables passées pour cloner le dépôt et lancer install.sh.
# ----------------------------------------------------------------------

# --- 1. FONCTIONS DE LOG SIMPLIFIÉES ---
log() { echo -e "\n\033[0;34m[INFO]\033[0m $1"; }
error() { echo -e "\n\033[0;31m[ERREUR]\033[0m $1"; exit 1; }

# Récupération des variables passées par le snippet de lancement
DOTFILES_REPO="${1:-}"
DOTFILES_DIR="$HOME/.dotfiles"

# Debug : afficher la valeur reçue
log "[DEBUG] Argument reçu pour l'URL du dépôt : '$DOTFILES_REPO'"

if [ -z "$DOTFILES_REPO" ]; then
    error "URL de dépôt non fournie au script bootstrap."
fi

# --- 2. VÉRIFICATION ET INSTALLATION DE GIT ---
if ! command -v git >/dev/null 2>&1; then
    log "Installation des dépendances essentielles (Git)..."
    sudo apt update -qq && sudo apt install -y git || { echo "❌ Échec de l'installation de Git."; exit 1; }
fi

# --- 3. CLONAGE DU DÉPÔT ---
if [ ! -d "$DOTFILES_DIR" ]; then
    log "🔗 Clonage du dépôt dotfiles dans $DOTFILES_DIR..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || error "Échec du clonage du dépôt. Vérifiez le PAT et l'URL."
else
    log "Le dépôt $DOTFILES_DIR existe déjà. Mise à jour..."
    (cd "$DOTFILES_DIR" && git remote set-url origin "$DOTFILES_REPO" && git pull) || error "Échec de la mise à jour du dépôt."
fi

# 4. Correction des permissions d'exécution pour install.sh (pour résoudre l'erreur précédente)
chmod +x "$DOTFILES_DIR/install.sh" || error "Impossible de donner les droits d'exécution à install.sh."

# --- 5. LANCEMENT DU SCRIPT DE PROVISIONNEMENT COMPLET ---
log "🚀 Lancement du script de provisionnement complet ($DOTFILES_DIR/install.sh)..."
# Nous passons l'URL sécurisée en argument à install.sh pour référence (bien qu'il ne l'utilise plus).
exec "$DOTFILES_DIR/install.sh" "$DOTFILES_REPO"