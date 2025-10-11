# ----------------------------------------------------------------------
# SNIPPET DE LANCEMENT FINAL ET CORRIGÉ (À utiliser sur le client)
# REMPLACER MON_USER
# ----------------------------------------------------------------------
GITHUB_USER="dargh" # <-- REMPLACER
REPO_BASE_URL="https://github.com/dargh/dotfiles.git" # <-- REMPLACER

# 1. Demande sécurisée du Personal Access Token (PAT)
echo -e "\n\033[0;33mVeuillez saisir votre Personal Access Token (PAT) GitHub pour accéder au dépôt privé :\033[0m"
read -sp "Token : " GITHUB_PAT
echo

# 2. Construction de l'URL sécurisée pour le clonage (inclut l'utilisateur et le PAT)
# On utilise printf %q pour un échappement parfait de l'URL
SECURE_REPO_URL=$(printf "%q" "$(echo "$REPO_BASE_URL" | sed "s/https:\/\//https:\/\/$GITHUB_USER:$GITHUB_PAT@/")")

# 3. Définition de l'URL brute du bootstrap (pour le curl initial)
BOOTSTRAP_URL="https://raw.githubusercontent.com/$GITHUB_USER/dotfiles/main/bootstrap.sh"

# 4. Exécution du script avec dépendances et passage de l'URL sécurisée
/bin/bash -c "
# Installer curl si manquant
if ! command -v curl >/dev/null 2>&1; then
    echo -e '\n\033[0;34m[INFO]\033[0m curl non trouvé. Installation en cours...'
    sudo apt update -qq && sudo apt install -y curl -qq || { 
        echo -e '\n\033[0;31m[ERREUR]\033[0m Échec de l'\''installation de curl.' >&2; exit 1; 
    }
fi

# Télécharger le bootstrap et le lancer.
# L'argument \$SECURE_REPO_URL est transmis en dehors de la sous-commande \$(...)
# en utilisant une commande "heredoc" temporaire pour garantir la bonne interprétation
/bin/bash -c \"\$(curl -fsSL -H 'Authorization: Bearer $GITHUB_PAT' '$BOOTSTRAP_URL')\" $SECURE_REPO_URL
"