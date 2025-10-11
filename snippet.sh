# 1. Demande sécurisée du Personal Access Token (PAT)
echo -e "Veuillez saisir votre Personal Access Token (PAT) GitHub pour accéder au dépôt privé :"
read -sp "Token : " GITHUB_PAT
echo

# 2. Définition de l'URL brute de votre bootstrap.sh
#    À REMPLACER: Mettez ici votre nom d'utilisateur, le nom du dépôt et la branche (souvent 'main' ou 'master')
BOOTSTRAP_URL="https://raw.githubusercontent.com/VOTRE_USER/VOTRE_REPO/main/bootstrap.sh"

# 3. Exécution de la commande
#    Le script est téléchargé via curl avec authentification et directement exécuté par bash.
/bin/bash -c "$(curl -fsSL -H "Authorization: Bearer $GITHUB_PAT" "$BOOTSTRAP_URL")"