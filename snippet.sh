#!/bin/bash
# ----------------------------------------------------------------------
# SNIPPET DE LANCEMENT FINAL ET CORRIGÉ (À utiliser sur le client)
# ----------------------------------------------------------------------
GITHUB_USER="dargh" # <-- REMPLACER VOTRE NOM D'UTILISATEUR
REPO_BASE_URL="https://github.com/dargh/dotfiles.git" # <-- REMPLACER

# 1. Demande sécurisée du Personal Access Token (PAT)
echo -e "\n\033[0;33mVeuillez saisir votre Personal Access Token (PAT) GitHub pour accéder au dépôt privé :\033[0m"
read -sp "Token : " GITHUB_PAT
echo

SECURE_REPO_URL=$(echo "$REPO_BASE_URL" | sed "s/https:\/\//https:\/\/$GITHUB_USER:$GITHUB_PAT@/")


# Utilisation de l'API GitHub pour récupérer bootstrap.sh (compatible dépôt privé)
BOOTSTRAP_API_URL="https://api.github.com/repos/$GITHUB_USER/dotfiles/contents/bootstrap.sh?ref=main"


# Construction de la commande avec authentification pour l'API GitHub et passage correct de l'argument
CMD_TO_EXECUTE=$(printf '/bin/bash -c "$(curl -fsSL -H \"Authorization: token %s\" -H \"Accept: application/vnd.github.v3.raw\" %s)" -- %q' "$GITHUB_PAT" "$BOOTSTRAP_API_URL" "$SECURE_REPO_URL")

/bin/bash -c "
# Installer curl si manquant
if ! command -v curl >/dev/null 2>&1; then
    echo -e '\n\033[0;34m[INFO]\033[0m curl non trouvé. Installation en cours...'
    sudo apt update -qq && sudo apt install -y curl -qq || { 
        echo -e '\n\033[0;31m[ERREUR]\033[0m Échec de l'\''installation de curl.' >&2; exit 1; 
    }
fi

# Exécuter la commande finale
$CMD_TO_EXECUTE
"