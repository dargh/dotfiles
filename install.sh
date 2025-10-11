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
# Si un argument est passé, on l'utilise comme URL du dépôt (cas bootstrap)
if [ -n "$1" ]; then
    DOTFILES_REPO="$1"
    echo -e "\n[DEBUG] DOTFILES_REPO reçu en argument : '$DOTFILES_REPO'"
else
    DOTFILES_REPO=""
fi
DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"

# --- 0. FONCTION : INVITE INTERACTIVE POUR L'URL ---
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

# --- 2. FONCTION : DÉPENDANCES ESSENTIELLES ---
function install_core_dependencies() {
    log_step "apps" "Installation des dépendances essentielles (git, curl, build-essential)..."
    CORE_DEPS=(git curl build-essential)
    sudo apt update -qq
    sudo apt install -y "${CORE_DEPS[@]}" || error "Impossible d'installer les dépendances essentielles."
    ok "Dépendances essentielles installées."
}

# --- 3. FONCTION : DÉPLOIEMENT DES DOTFILES ---
function deploy_dotfiles() {
    log_step "dots" "Clonage et déploiement du dépôt dotfiles."
    if [ -z "$DOTFILES_REPO" ]; then error "L'URL du dépôt n'a pas été configurée."; fi

    if [ -d "$DOTFILES_DIR" ]; then
        log_step "dots" "Mise à jour du dépôt dotfiles existant..."
        (cd "$DOTFILES_DIR" && git remote set-url origin "$DOTFILES_REPO" && git pull) || warn "Échec de la mise à jour du dépôt."
    else
        log_step "dots" "Clonage du dépôt dotfiles..."
        git clone --recurse-submodules "$DOTFILES_REPO" "$DOTFILES_DIR" || error "Échec du clonage."
    fi

    if [ ! -d "$CONFIG_DIR" ]; then mkdir -p "$CONFIG_DIR"; ok "$CONFIG_DIR créé."; fi

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
        else
            log_step "brew" "Homebrew non trouvé, installation en cours..."
            if CI=true /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then ok "Installation de Homebrew réussie."; else error "L'installation de Homebrew a échoué."; fi
            if [ -x "$brew_path" ]; then eval "$("$brew_path" shellenv)"; else error "Binaire Homebrew introuvable après installation."; fi
        fi
        ok "Environnement Homebrew chargé pour la session."
    else
        ok "Homebrew est déjà configuré dans le PATH."
    fi

    if [ -f "$zshrc_file" ] && ! grep -q "$brew_shellenv_line" "$zshrc_file"; then
        log_step "brew" "Ajout de la variable d'environnement Homebrew à $zshrc_file..."
        echo -e "\n# Homebrew" >> "$zshrc_file"
        echo "$brew_shellenv_line" >> "$zshrc_file"
        ok "Configuration Homebrew ajoutée au .zshrc."
    else
        ok "Configuration Homebrew déjà présente dans le .zshrc."
    fi
}

# --- 5. FONCTION : INSTALLATION DES APPLICATIONS ET OUTILS ---
function install_apps() {
    log_step "apps" "Installation des applications, polices et outils additionnels..."

    BREW_PACKAGES_FILE="$DOTFILES_DIR/packages.brew"
    if [ -f "$BREW_PACKAGES_FILE" ]; then
        if command -v brew >/dev/null 2>&1; then
            log_step "apps" "Installation des outils via Homebrew depuis la liste..."
            while read -r tool; do
                if [[ "$tool" =~ ^\s*#.*$ ]] || [[ -z "$tool" ]]; then continue; fi
                if brew list "$tool" &>/dev/null; then ok "$tool déjà présent"; else
                    if brew install "$tool"; then ok "$tool installé"; else warn "Échec de l'installation de $tool."; fi
                fi
            done < <(grep -vE '^\s*#|^\s*$' "$BREW_PACKAGES_FILE")
        else
             warn "Brew n'est pas dans le PATH. Installation Homebrew via liste ignorée."
        fi
    else
        warn "Fichier packages.brew non trouvé. Installation Homebrew ignorée."
    fi

    APT_PACKAGES_FILE="$DOTFILES_DIR/packages.apt"
    if [ -f "$APT_PACKAGES_FILE" ]; then
        log_step "apps" "Installation des dépendances système (APT) depuis la liste..."
        sudo apt update -qq
        if grep -vE '^\s*#|^\s*$' "$APT_PACKAGES_FILE" | xargs sudo apt install -y ; then ok "Dépendances APT installées."; else error "Impossible d'installer les dépendances APT."; fi
    else
        warn "Fichier packages.apt non trouvé. Dépendances APT ignorées."
    fi

    FONT_DIR="$HOME/.local/share/fonts"
    log_step "font" "Installation de la police FiraCode Nerd Font..."
    if [ -d "$FONT_DIR/FiraCode" ]; then ok "Police FiraCode déjà installée."; else
        mkdir -p "$FONT_DIR"; TEMP_ZIP=$(mktemp)
        curl -L "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip" -o "$TEMP_ZIP"
        unzip -q "$TEMP_ZIP" -d "$FONT_DIR/FiraCode"; rm "$TEMP_ZIP"; fc-cache -fv >/dev/null; ok "Police FiraCode installée."
    fi

    # Installation automatique des serveurs LSP nécessaires
    log_step "apps" "Installation de bash-language-server (npm) si absent..."
    if ! command -v bash-language-server >/dev/null 2>&1; then
        if command -v npm >/dev/null 2>&1; then
            npm install -g bash-language-server && ok "bash-language-server installé."
        else
            warn "npm non trouvé, bash-language-server non installé. Installez Node.js et npm pour le support Bash LSP."
        fi
    else
        ok "bash-language-server déjà présent."
    fi

    log_step "apps" "Installation de lua-language-server (apt ou brew) si absent..."
    if ! command -v lua-language-server >/dev/null 2>&1; then
        if command -v apt >/dev/null 2>&1; then
            sudo apt update -qq && sudo apt install -y lua-language-server && ok "lua-language-server installé (apt)."
        elif command -v brew >/dev/null 2>&1; then
            brew install lua-language-server && ok "lua-language-server installé (brew)."
        else
            warn "Ni apt ni brew trouvés, lua-language-server non installé. Installez-le manuellement pour le support Lua LSP."
        fi
    else
        ok "lua-language-server déjà présent."
    fi
}

# --- 6. FONCTION : INSTALLATION DE ZSH ET SES PLUGINS ---
function install_zsh_and_plugins() {
    log_step "zsh" "Installation de Zsh, Oh My Zsh et plugins..."

    if ! command -v zsh >/dev/null 2>&1; then sudo apt install -y zsh; ok "Zsh installé."; else ok "Zsh déjà présent."; fi
    
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" || error "Impossible de cloner Oh My Zsh."
        ok "Oh My Zsh installé."
    else
        ok "Oh My Zsh déjà présent."
    fi

    ZSH_PATH=$(command -v zsh)
    if [ "$SHELL" != "$ZSH_PATH" ]; then
        chsh -s "$ZSH_PATH" || warn "Impossible de changer le shell. Faites-le manuellement."
        ok "Zsh défini comme shell par défaut."
    fi

    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    mkdir -p "$plugins_dir"

    declare -A plugins_repos=(
        ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
        ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
        ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab.git"
        ["zsh-completions"]="https://github.com/zsh-users/zsh-completions.git"
    )
    for name in "${!plugins_repos[@]}"; do
        if [ ! -d "$plugins_dir/$name" ]; then
            git clone --depth=1 "${plugins_repos[$name]}" "$plugins_dir/$name" || warn "Échec du clonage de $name."
        fi
    done
    ok "Plugins Zsh vérifiés/installés."
}

# --- 7. FONCTION : CONFIGURATION DE NEOPIM (PLUGINS UNIQUEMENT) ---
function setup_neovim() {
    log_step "nvim" "Configuration des plugins Neovim (Packer)..."
    NVIM_BIN=$(command -v nvim || echo "")

    if [ -z "$NVIM_BIN" ]; then
        warn "Binaire Neovim non trouvé. La configuration de Neovim est ignorée."
        return
    fi

    # 1. Assure que Packer est installé
    local packer_install_path="$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
    if [ ! -d "$packer_install_path" ]; then
        log_step "nvim" "Installation initiale de Packer.nvim..."
        git clone --depth 1 https://github.com/wbthomason/packer.nvim "$packer_install_path" || warn "Échec de l'installation de Packer."
    fi

    # 2. Exécute la synchronisation via une simple commande Vimscript.
    log_step "nvim" "Synchronisation des plugins (PackerSync)..."
    
    # Exécution de PackerSync en mode headless. Cette commande quitte automatiquement une fois terminée.
    if "$NVIM_BIN" --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'; then
        echo
        ok "Plugins Neovim synchronisés avec succès."
    else
        # Cette erreur ne se déclenchera que si le processus nvim lui-même échoue (ex: introuvable).
        # Les erreurs Lua internes ne sont pas capturées ici, ce qui est le comportement que vous aviez et qui fonctionnait.
        error "Une erreur est survenue lors du lancement de Neovim pour la synchronisation."
    fi
}


# --- EXÉCUTION PRINCIPALE ---
echo
log_step "system" "=== Début du provisioning de la machine Debian ==="

update_system
install_core_dependencies
deploy_dotfiles
setup_homebrew
install_apps
install_zsh_and_plugins
setup_neovim

log_step "summary" "✅ Provisioning terminé avec succès !"
echo
echo -e "${CYAN}Actions requises :${NC}"
echo -e "  1. ${YELLOW}Fermez et rouvrez votre terminal${NC} (ou exécutez ${GREEN}exec zsh${NC}) pour charger Zsh et la nouvelle configuration."
echo -e "  2. Si vous utilisez un terminal graphique, configurez la police ${YELLOW}FiraCode Nerd Font${NC}."
