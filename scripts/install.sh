#!/bin/bash
set -e

# --- Couleurs et fonctions de log ---
GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'
declare -A ICONS
ICONS=( ["system"]="⚙️" ["zsh"]="⚡" ["brew"]="🍺" ["apps"]="📦" ["font"]="🎨" ["dots"]="🔗" ["nvim"]=" V " ["summary"]="📜" )

log_step() { local step="$1"; local msg="$2"; local icon="${ICONS[$step]}"; [ -z "$icon" ] && icon="ℹ️"; echo -e "\n$(date '+%H:%M:%S') $icon ${BLUE}$msg${NC}"; }
ok() { echo -e "$(date '+%H:%M:%S') ✅ ${GREEN}$1${NC}"; }
warn() { echo -e "$(date '+%H:%M:%S') ⚠️ ${YELLOW}$1${NC}"; }
error() { echo -e "$(date '+%H:%M:%S') ❌ ${RED}$1${NC}"; exit 1; }

# --- Variables Globales ---
# L'URL du repo sera définie par la fonction get_dotfiles_repo_url
DOTFILES_REPO="" 
ZSH_CUSTOM_DIR="$HOME/.oh-my-zsh/custom"
DOTFILES_DIR="$HOME/.dotfiles"

# --- 0. FONCTION : INVITE INTERACTIVE POUR L'URL ---
function get_dotfiles_repo_url() {
    log_step "dots" "Configuration de l'accès au dépôt privé (HTTPS/PAT)..."
    
    echo -e "${YELLOW}Veuillez saisir les informations d'accès à votre dépôt dotfiles privé :${NC}"
    
    # 1. Nom d'utilisateur
    read -p "  [?] Votre nom d'utilisateur GitHub : " GITHUB_USER
    if [ -z "$GITHUB_USER" ]; then error "Nom d'utilisateur ne peut être vide."; fi
    
    # 2. Token d'accès personnel (PAT) - Saisi de manière masquée
    read -sp "  [?] Votre Personal Access Token (PAT) : " GITHUB_TOKEN
    echo # Ajoute un retour à la ligne après la saisie du PAT
    if [ -z "$GITHUB_TOKEN" ]; then error "Token ne peut être vide."; fi
    
    # 3. URL HTTPS du dépôt (sans les identifiants)
    read -p "  [?] URL HTTPS du dépôt (ex: https://github.com/user/repo.git) : " REPO_BASE_URL
    if [ -z "$REPO_BASE_URL" ]; then error "URL de dépôt ne peut être vide."; fi

    # Construction de l'URL finale au format HTTPS avec identifiants intégrés
    # Exemple: https://user:token@github.com/user/repo.git
    DOTFILES_REPO=$(echo "$REPO_BASE_URL" | sed "s/https:\/\//https:\/\/$GITHUB_USER:$GITHUB_TOKEN@/")
    
    ok "URL d'accès sécurisée configurée."
}

# --- 1. FONCTION : MISE À JOUR SYSTÈME ---
function update_system() {
    log_step "system" "Mise à jour du système (update & upgrade)..."
    sudo apt update -qq && sudo apt upgrade -y || error "Échec de la mise à jour du système."
    ok "Système à jour."
}

# --- 2. FONCTION : INSTALLATION DE ZSH ET OH MY ZSH ---
function install_zsh() {
    log_step "zsh" "Installation de Zsh et ses dépendances..."
    if ! command -v zsh >/dev/null 2>&1; then
        sudo apt install -y zsh || error "Impossible d'installer zsh."
        ok "Zsh installé."
    else
        ok "Zsh déjà présent."
    fi

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_step "zsh" "Installation de Oh My Zsh..."
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" || error "Impossible de cloner Oh My Zsh."
        ok "Oh My Zsh installé."
    else
        ok "Oh My Zsh déjà présent."
    fi
    
    ZSH_PATH=$(command -v zsh)
    if [ "$SHELL" != "$ZSH_PATH" ]; then
        log_step "zsh" "Définition de Zsh comme shell par défaut..."
        chsh -s "$ZSH_PATH" || warn "Impossible de changer le shell. Faites-le manuellement."
        ok "Zsh défini comme shell par défaut."
    else
        ok "Zsh est déjà le shell par défaut."
    fi
}

# --- 3. FONCTION : INSTALLATION ET CONFIGURATION HOMEBREW ---
function setup_homebrew() {
    log_step "brew" "Vérification et configuration de l'environnement Homebrew..."
    
    if ! command -v brew >/dev/null 2>&1; then
        POTENTIAL_BREW_PATHS=("$HOME/.linuxbrew/bin/brew" "/home/linuxbrew/.linuxbrew/bin/brew")
        BREW_BIN=""
        for path in "${POTENTIAL_BREW_PATHS[@]}"; do
            if [ -x "$path" ]; then
                BREW_BIN="$path"
                break
            fi
        done

        if [ -n "$BREW_BIN" ]; then
            eval "$("$BREW_BIN" shellenv)"
            ok "Environnement Homebrew chargé."
        else
            log_step "brew" "Homebrew non trouvé, installation en cours..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error "L'installation de Homebrew a échoué."
            if [ -x "$HOME/.linuxbrew/bin/brew" ]; then
                eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
                ok "Homebrew installé et chargé."
            else
                error "Homebrew semble installé, mais l'environnement n'a pas pu être chargé."
            fi
        fi
    else
        ok "Homebrew est déjà configuré dans le PATH."
    fi
}

# --- 4. FONCTION : INSTALLATION DES APPLICATIONS ET OUTILS ---
function install_apps() {
    log_step "apps" "Installation des dépendances, polices et outils..."

    # Dépendances système (APT)
    APT_PACKAGES_FILE="$DOTFILES_DIR/packages.apt"
    if [ -f "$APT_PACKAGES_FILE" ]; then
        log_step "apps" "Installation des dépendances système (APT)..."
        sudo apt update -qq
        # xargs lit chaque ligne du fichier et les passe comme arguments à 'sudo apt install -y'
        if grep -vE '^\s*#|^\s*$' "$APT_PACKAGES_FILE" | xargs sudo apt install -y ; then
            ok "Dépendances APT installées."
        else
            error "Impossible d'installer les dépendances APT."
        fi
    else
        warn "Fichier packages.apt non trouvé. Dépendances APT ignorées."
    fi
    
    # Outils via Homebrew
    BREW_PACKAGES_FILE="$DOTFILES_DIR/packages.brew"
    if [ -f "$BREW_PACKAGES_FILE" ]; then
        log_step "apps" "Installation des outils via Homebrew..."
        # On lit chaque outil et on l'installe
        while read -r tool; do
            # Ignorer les lignes vides ou commentées
            if [[ "$tool" =~ ^\s*#.*$ ]] || [[ -z "$tool" ]]; then
                continue
            fi
            
            if brew list "$tool" &>/dev/null; then
                ok "$tool déjà présent"
            else
                log_step "apps" "Installation de $tool..."
                if brew install "$tool"; then
                    ok "$tool installé"
                else
                    warn "Échec de l'installation de $tool."
                fi
            fi
        done < <(grep -vE '^\s*#|^\s*$' "$BREW_PACKAGES_FILE")
    else
        warn "Fichier packages.brew non trouvé. Installation Homebrew ignorée."
    fi

    # Installation de la police FiraCode Nerd Font (Logique inchangée)
    FONT_DIR="$HOME/.local/share/fonts"
    log_step "font" "Installation de la police FiraCode Nerd Font..."
    if [ -d "$FONT_DIR/FiraCode" ]; then
        ok "Police FiraCode déjà installée."
    else
        mkdir -p "$FONT_DIR"; TEMP_ZIP=$(mktemp)
        curl -L "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip" -o "$TEMP_ZIP"
        unzip -q "$TEMP_ZIP" -d "$FONT_DIR/FiraCode"; rm "$TEMP_ZIP"; fc-cache -fv >/dev/null
        ok "Police FiraCode installée."
    fi

    # Installation du serveur LSP Bash (Logique inchangée)
    log_step "apps" "Installation du serveur LSP Bash..."
    if ! command -v "bash-language-server" &>/dev/null; then
        sudo npm install -g bash-language-server || error "Impossible d'installer bash-language-server."
        ok "Serveur LSP Bash installé."
    else
        ok "Serveur LSP Bash déjà présent."
    fi
}

# --- 5. FONCTION : DÉPLOIEMENT DES DOTFILES ---
function deploy_dotfiles() {
    log_step "dots" "Clonage et déploiement du dépôt dotfiles."
    
    if [ -z "$DOTFILES_REPO" ]; then
        error "L'URL du dépôt n'a pas été configurée."
    fi

    # 1. Clonage ou mise à jour
    if [ -d "$DOTFILES_DIR" ]; then
        log_step "dots" "Mise à jour du dépôt dotfiles existant..."
        (cd "$DOTFILES_DIR" && git remote set-url origin "$DOTFILES_REPO" && git pull) || warn "Échec de la mise à jour du dépôt. Vérifiez vos identifiants."
    else
        log_step "dots" "Clonage du dépôt dotfiles..."
        git clone --recurse-submodules "$DOTFILES_REPO" "$DOTFILES_DIR" || error "Échec du clonage. Vérifiez l'URL HTTPS et vos identifiants (PAT)."
    fi

    # 2. Création des liens symboliques
    log_step "dots" "Création des liens symboliques..."
    ln -snfv "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    ln -snfv "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"
    
    ok "Dotfiles déployés."
}

# --- 6. FONCTION : SYNCHRONISATION DES PLUGINS NEOPIM ---
function sync_nvim_plugins() {
    log_step "nvim" "Synchronisation des plugins Neovim (PackerSync)..."
    
    NVIM_BIN=$(command -v nvim || echo "")
    PACKER_DIR="$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
    
    # 1. Vérification de Packer.nvim
    if [ ! -d "$PACKER_DIR" ]; then 
        log_step "nvim" "Installation de Packer.nvim..."
        git clone --depth 1 https://github.com/wbthomason/packer.nvim "$PACKER_DIR" || warn "Impossible d'installer Packer.nvim."
    else
        ok "Packer.nvim déjà présent."
    fi

    # 2. Lancement de PackerSync en mode headless
    if [ -n "$NVIM_BIN" ]; then
        # On exécute nvim pour installer les plugins
        "$NVIM_BIN" --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' || error "Échec de PackerSync. Vérifiez votre configuration Lua."
        ok "Synchronisation Packer terminée. Les plugins sont installés."
    else
        warn "Binaire Neovim non trouvé. Synchronisation des plugins ignorée."
    fi
}

# --- EXÉCUTION PRINCIPALE ---
echo
log_step "system" "=== Début du provisioning de la machine Debian ==="

get_dotfiles_repo_url

update_system
install_zsh
setup_homebrew
install_apps
deploy_dotfiles
sync_nvim_plugins # NOUVEL APPEL

log_step "summary" "✅ Provisioning terminé avec succès !"
echo
echo -e "${CYAN}Actions requises :${NC}"
echo -e "  1. ${YELLOW}Fermez et rouvrez votre terminal${NC} pour charger Zsh et la nouvelle configuration (ou exécutez ${GREEN}source ~/.zshrc${NC})."
echo -e "  2. Configurez la police ${YELLOW}FiraCode Nerd Font${NC} dans votre terminal graphique."