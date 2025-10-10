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
DOTFILES_REPO="" 
DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"

# --- 0. FONCTION : INVITE INTERACTIVE POUR L'URL (Authentification HTTPS) ---
function get_dotfiles_repo_url() {
    log_step "dots" "Configuration de l'accès au dépôt privé (HTTPS/PAT)..."
    echo -e "${YELLOW}Veuillez saisir les informations d'accès à votre dépôt dotfiles privé :${NC}"
    read -p "  [?] Votre nom d'utilisateur GitHub : " GITHUB_USER
    if [ -z "$GITHUB_USER" ]; then error "Nom d'utilisateur ne peut être vide."; fi
    read -sp "  [?] Votre Personal Access Token (PAT) : " GITHUB_TOKEN
    echo
    if [ -z "$GITHUB_TOKEN" ]; then error "Token ne peut être vide."; fi
    read -p "  [?] URL HTTPS du dépôt (ex: https://github.com/user/repo.git) : " REPO_BASE_URL
    if [ -z "$REPO_BASE_URL" ]; then error "URL de dépôt ne peut être vide."; fi
    DOTFILES_REPO=$(echo "$REPO_BASE_URL" | sed "s/https:\/\//https:\/\/$GITHUB_USER:$GITHUB_TOKEN@/")
    ok "URL d'accès sécurisée configurée."
}

# --- 1. FONCTION : MISE À JOUR SYSTÈME ---
function update_system() {
    log_step "system" "Mise à jour du système (update & upgrade)..."
    sudo apt update -qq && sudo apt upgrade -y || error "Échec de la mise à jour du système."
    ok "Système à jour."
}

# --- 2. FONCTION : DÉPENDANCES ESSENTIELLES (Utilisées par le script lui-même) ---
function install_core_dependencies() {
    log_step "apps" "Installation des dépendances essentielles (git, curl, build-essential)..."
    CORE_DEPS=(git curl build-essential)
    sudo apt update -qq
    sudo apt install -y "${CORE_DEPS[@]}" || error "Impossible d'installer les dépendances essentielles."
    ok "Dépendances essentielles installées."
}

# --- 3. FONCTION : DÉPLOIEMENT DES DOTFILES (Clonage et liens) ---
function deploy_dotfiles() {
    log_step "dots" "Clonage et déploiement du dépôt dotfiles."
    if [ -z "$DOTFILES_REPO" ]; then error "L'URL du dépôt n'a pas été configurée."; fi

    # 1. Clonage ou mise à jour
    if [ -d "$DOTFILES_DIR" ]; then
        log_step "dots" "Mise à jour du dépôt dotfiles existant..."
        (cd "$DOTFILES_DIR" && git remote set-url origin "$DOTFILES_REPO" && git pull) || warn "Échec de la mise à jour du dépôt."
    else
        log_step "dots" "Clonage du dépôt dotfiles..."
        git clone --recurse-submodules "$DOTFILES_REPO" "$DOTFILES_DIR" || error "Échec du clonage."
    fi

    # 2. Création du répertoire parent pour .config
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR" || error "Impossible de créer le répertoire $CONFIG_DIR."
        ok "$CONFIG_DIR créé."
    else
        ok "$CONFIG_DIR existe déjà."
    fi

    # 3. Création des liens symboliques
    log_step "dots" "Création des liens symboliques..."
    ln -snfv "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    ln -snfv "$DOTFILES_DIR/.config/nvim" "$CONFIG_DIR/nvim"
    ok "Dotfiles déployés."
}

# --- 4. FONCTION : INSTALLATION ET CONFIGURATION HOMEBREW ---
function setup_homebrew() {
    log_step "brew" "Vérification et configuration de l'environnement Homebrew (Multi-utilisateur)..."
    
    local brew_path="/home/linuxbrew/.linuxbrew/bin/brew"
    local brew_shellenv_line='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    local zshrc_file="$HOME/.zshrc"

    if ! command -v brew >/dev/null 2>&1; then
        if [ -x "$brew_path" ]; then
            eval "$("$brew_path" shellenv)"
            ok "Environnement Homebrew déjà installé et chargé pour la session."
        else
            log_step "brew" "Homebrew non trouvé, installation en cours..."
            if CI=true /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
                ok "Installation de Homebrew réussie."
            else
                error "L'installation de Homebrew a échoué."
            fi
            
            if [ -x "$brew_path" ]; then
                eval "$("$brew_path" shellenv)"
                ok "Environnement Homebrew chargé pour la session."
            else
                error "Homebrew est installé, mais le binaire est introuvable à $brew_path."
            fi
        fi
    else
        ok "Homebrew est déjà configuré dans le PATH."
    fi

    # Ajout de la configuration pour les futures sessions (dans .zshrc)
    if ! grep -q "$brew_shellenv_line" "$zshrc_file"; then
        log_step "brew" "Ajout de la variable d'environnement Homebrew à $zshrc_file..."
        echo -e "\n# Homebrew" >> "$zshrc_file"
        echo "$brew_shellenv_line" >> "$zshrc_file"
        ok "Configuration Homebrew ajoutée au .zshrc."
    else
        ok "Configuration Homebrew déjà présente dans le .zshrc."
    fi
}

# --- 5. FONCTION : INSTALLATION DES APPLICATIONS ET OUTILS (Lit packages.*) ---
function install_apps() {
    log_step "apps" "Installation des applications, polices et outils additionnels..."

    # Outils via Homebrew
    BREW_PACKAGES_FILE="$DOTFILES_DIR/packages.brew"
    if [ -f "$BREW_PACKAGES_FILE" ]; then
        if ! command -v brew &>/dev/null; then
             warn "Brew n'est pas dans le PATH. Installation Homebrew via liste ignorée."
        else
            log_step "apps" "Installation des outils via Homebrew depuis la liste..."
            while read -r tool; do
                if [[ "$tool" =~ ^\s*#.*$ ]] || [[ -z "$tool" ]]; then continue; fi
                if brew list "$tool" &>/dev/null; then ok "$tool déjà présent"; else
                    log_step "apps" "Installation de $tool..."
                    if brew install "$tool"; then ok "$tool installé"; else warn "Échec de l'installation de $tool." | tee /dev/stderr; fi
                fi
            done < <(grep -vE '^\s*#|^\s*$' "$BREW_PACKAGES_FILE")
        fi
    else
        warn "Fichier packages.brew non trouvé. Installation Homebrew ignorée."
    fi

    # Dépendances système pour les applications
    APT_PACKAGES_FILE="$DOTFILES_DIR/packages.apt"
    if [ -f "$APT_PACKAGES_FILE" ]; then
        log_step "apps" "Installation des dépendances système (APT) depuis la liste..."
        sudo apt update -qq
        if grep -vE '^\s*#|^\s*$' "$APT_PACKAGES_FILE" | xargs sudo apt install -y ; then
             ok "Dépendances APT installées."
        else
            error "Impossible d'installer les dépendances APT via liste."
        fi
    else
        warn "Fichier packages.apt non trouvé. Dépendances APT ignorées."
    fi

    # Police FiraCode Nerd Font
    FONT_DIR="$HOME/.local/share/fonts"
    log_step "font" "Installation de la police FiraCode Nerd Font..."
    if [ -d "$FONT_DIR/FiraCode" ]; then ok "Police FiraCode déjà installée."; else
        mkdir -p "$FONT_DIR"; TEMP_ZIP=$(mktemp)
        curl -L "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip" -o "$TEMP_ZIP"
        unzip -q "$TEMP_ZIP" -d "$FONT_DIR/FiraCode"; rm "$TEMP_ZIP"; fc-cache -fv >/dev/null
        ok "Police FiraCode installée."
    fi

    # Serveur LSP Bash
    log_step "apps" "Installation du serveur LSP Bash..."
    if ! command -v "bash-language-server" &>/dev/null; then
        sudo npm install -g bash-language-server || error "Impossible d'installer bash-language-server."
        ok "Serveur LSP Bash installé."
    else
        ok "Serveur LSP Bash déjà présent."
    fi
}

# --- 6. FONCTION : INSTALLATION DE ZSH ET OH MY ZSH ---
function install_zsh() {
    log_step "zsh" "Installation de Zsh et ses dépendances..."
    if ! command -v zsh >/dev/null 2>&1; then sudo apt install -y zsh || error "Impossible d'installer zsh."; ok "Zsh installé."; else ok "Zsh déjà présent."; fi

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

# --- 7. FONCTION : INSTALLATION DES PLUGINS ZSH (Correction de l'erreur) ---
function install_zsh_plugins() {
    log_step "zsh" "Installation des plugins Zsh supplémentaires (Autosuggestions/Syntax Highlighting)..."

    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    mkdir -p "$plugins_dir" || error "Impossible de créer le répertoire des plugins Zsh."

    # Plugins externes à Oh My Zsh
    local plugins=(
        "zsh-users/zsh-autosuggestions.git"
        "zsh-users/zsh-syntax-highlighting.git"
    )

    for repo in "${plugins[@]}"; do
        local name=$(basename "$repo" .git)
        local path="$plugins_dir/$name"
        
        if [ ! -d "$path" ]; then
            log_step "zsh" "Clonage de $name..."
            git clone --depth=1 "https://github.com/$repo" "$path" || warn "Échec du clonage de $name."
        else
            ok "$name déjà présent."
        fi
    done

    ok "Plugins Zsh installés."
}

# --- 8. FONCTION : SYNCHRONISATION DES PLUGINS NEOPIM ---
function sync_nvim_plugins() {
    log_step "nvim" "Synchronisation des plugins Neovim (PackerSync)..."
    NVIM_BIN=$(command -v nvim || echo "")
    PACKER_DIR="$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
    
    if [ ! -d "$PACKER_DIR" ]; then 
        log_step "nvim" "Installation de Packer.nvim..."
        git clone --depth 1 https://github.com/wbthomason/packer.nvim "$PACKER_DIR" || warn "Impossible d'installer Packer.nvim."
    else
        ok "Packer.nvim déjà présent."
    fi

    if [ -n "$NVIM_BIN" ]; then
        "$NVIM_BIN" --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' || error "Échec de PackerSync."
        ok "Synchronisation Packer terminée."
    else
        warn "Binaire Neovim non trouvé. Synchronisation des plugins ignorée."
    fi
}


# --- EXÉCUTION PRINCIPALE (ORDRE FINAL ET DÉFINITIF) ---
echo
log_step "system" "=== Début du provisioning de la machine Debian ==="

get_dotfiles_repo_url

update_system
install_core_dependencies
deploy_dotfiles           # 3. CLONAGE DU DÉPÔT & LIENS SYMBOLIQUES (packages.*, .zshrc disponibles)

# ----------------- INSTALLATION DES OUTILS ET ENVIRONNEMENT -----------------
setup_homebrew            # 4. Installe/charge Homebrew (requis pour les apps et Zsh/Nvim)
install_apps              # 5. Installe fzf, neovim, etc. via packages.*
install_zsh               # 6. Installe Zsh et Oh My Zsh
install_zsh_plugins       # 7. Installe les plugins Zsh (utilise Git)
sync_nvim_plugins         # 8. Synchronise Neovim (utilise Neovim et Git)

log_step "summary" "✅ Provisioning terminé avec succès !"
echo
echo -e "${CYAN}Actions requises :${NC}"
echo -e "  1. ${YELLOW}Fermez et rouvrez votre terminal${NC} (ou exécutez ${GREEN}exec zsh${NC}) pour charger Zsh et la nouvelle configuration."
echo -e "  2. Si vous utilisez un terminal graphique, configurez la police ${YELLOW}FiraCode Nerd Font${NC}."