# 1. Demande sécurisée du Personal Access Token (PAT)
echo -e "Veuillez saisir votre Personal Access Token (PAT) GitHub pour accéder au dépôt privé :"
read -sp "Token : " GITHUB_PAT
echo

# 2. Définition de l'URL du bootstrap (À REMPLACER)
BOOTSTRAP_URL="https://raw.githubusercontent.com/VOTRE_USER/VOTRE_REPO/main/bootstrap.sh"

# 3. Exécution du script avec une tentative Curl, puis Wget en cas d'échec
if command -v curl >/dev/null 2>&1; then
    # Utilisation de Curl (méthode préférée)
    echo "Utilisation de curl..."
    /bin/bash -c "$(curl -fsSL -H "Authorization: Bearer $GITHUB_PAT" "$BOOTSTRAP_URL")"
elif command -v wget >/dev/null 2>&1; then
    # Utilisation de Wget (méthode alternative)
    echo "Utilisation de wget..."
    /bin/bash -c "$(wget -qO - --header="Authorization: Bearer $GITHUB_PAT" "$BOOTSTRAP_URL")"
else
    # Ni Curl ni Wget
    echo -e "\n\033[0;31m[ERREUR]\033[0m Ni 'curl' ni 'wget' ne sont installés. Veuillez installer l'un d'eux manuellement."
    exit 1
fi
