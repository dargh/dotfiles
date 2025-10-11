#!/bin/bash
set -e

# ----------------------------------------------------------------------
# SCRIPT DE PROVISIONNEMENT COMPLET
# Rôle: Installer tous les outils, configurer l'environnement (Zsh, Nvim, etc.).
# Ce script est lancé par le bootstrap.sh
# ----------------------------------------------------------------------

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
DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"

# --- 1. FONCTION : MISE À JOUR SYSTÈME ---
function update_system() {
    log_step "system" "Mise à jour du système (update & upgrade)..."
    sudo apt update -qq && sudo apt upgrade -y || error "Échec de la mise à jour du système."
    ok "Système à jour."
}

# --- 2. FONCTION : DÉPENDANCES ESSENTIELLES (Utilisées par Homebrew/Build) ---
function install_core_dependencies() {
    log_step "apps" "Installation des dépendances essentielles (curl, build-essential)..."
    CORE_DEPS=(curl build-essential)
    sudo apt update -qq
    sudo apt install -y "${CORE_DEPS[@]}" || error "Impossible d'installer les dépendances essentielles."
    ok "Dépendances essentielles installées."
}

# --- 3. FONCTION : DÉPLOIEMENT DES DOTFILES (Liens symboliques uniquement) ---
function deploy_dotfiles() {
    log_step "dots" "Déploiement des liens symboliques."
    
    # Le bootstrap a déjà cloné/mis à jour le dépôt. On ne fait que les liens ici.
    
    if [ ! -d "$CONFIG_DIR" ]; then 
        mkdir -p "$CONFIG_DIR"; 
        ok "$CONFIG_DIR créé."
    else
        ok "$CONFIG_DIR existe déjà."
    fi

    log_step "dots" "Création des liens symboliques..."
    ln -snfv "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    ln -snfv "$DOTFILES_DIR/.config/nvim" "$CONFIG_DIR/nvim"
    ok "Dotfiles déployés."
}

# --- 4. FONCTION : INSTALLATION ET CONFIGURATION HOMEBREW ---
function setup_homebrew() {
    log_step "brew" "Vérification et configuration de l'environnement Homebrew..."
    
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
            # Logique d'installation Brew...
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

    local temp_lua_script
    temp_lua_script=$(mktemp) || error "Impossible de créer un fichier temporaire pour Neovim."
    
    # Le script Lua minimal pour s'assurer que Packer est là et synchronisé
    cat <<'EOF' > "$temp_lua_script"
vim.notify('Démarrage du setup Neovim...', vim.log.levels.INFO)

-- S'assure que Packer est installé
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  vim.notify('Installation de Packer.nvim...', vim.log.levels.INFO)
  fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
  vim.cmd 'packadd packer.nvim'
end

vim.notify('Synchronisation des plugins (PackerSync)...', vim.log.levels.INFO)
pcall(require('packer').sync)
vim.notify('PackerSync terminé.', vim.log.levels.INFO)
EOF

    # Exécution de Neovim
    if "$NVIM_BIN" --headless -S "$temp_lua_script" -c 'qa!'; then
        ok "Plugins Neovim synchronisés avec succès."
    else
        error "Une erreur est survenue lors de la synchronisation des plugins Neovim."
    fi
    
    rm "$temp_lua_script"
}

# --- EXÉCUTION PRINCIPALE ---
echo
log_step "system" "=== Démarrage du provisionnement de la machine Debian ==="

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