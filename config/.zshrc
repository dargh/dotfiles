### Zinit: Plugin manager for Zsh
if [[ ! -f ~/.zinit/bin/zinit.zsh ]]; then
  mkdir -p ~/.zinit
  git clone https://github.com/zdharma-continuum/zinit ~/.zinit/bin
fi
source ~/.zinit/bin/zinit.zsh

### Plugins: Autocompletion, syntax, Docker...
# Suggestions automatiques dans le terminal
zinit light zsh-users/zsh-autosuggestions

# Mise en couleur de la syntaxe dans le terminal
zinit light zdharma-continuum/fast-syntax-highlighting

# Complétions supplémentaires pour Zsh
zinit light zsh-users/zsh-completions

# Complétions contextuelles avec fzf
zinit light Aloxaf/fzf-tab
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# Git completions
zinit snippet OMZ::plugins/gitfast/gitfast.plugin.zsh

# Aliases cheatsheet
zinit snippet OMZ::plugins/aliases/aliases.plugin.zsh

# Alias finder
zinit snippet OMZ::plugins/alias-finder/alias-finder.plugin.zsh
zstyle ':omz:plugins:alias-finder' autoload yes # disabled by default
zstyle ':omz:plugins:alias-finder' longer yes # disabled by default
zstyle ':omz:plugins:alias-finder' exact yes # disabled by default
zstyle ':omz:plugins:alias-finder' cheaper yes # disabled by default

# Extract 
zinit snippet OMZ::plugins/extract/extract.plugin.zsh

# VS Code alias
zinit snippet OMZ::plugins/vscode/vscode.plugin.zsh

### Brew: environnement Linuxbrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

### Starship: prompt moderne et rapide
eval "$(starship init zsh)"

### Zoxide: navigation intelligente
eval "$(zoxide init zsh)"

### Atuin: historique shell synchronisé
eval "$(atuin init zsh)"
export ATUIN_NOBIND="true"
bindkey '^R' atuin-search  # remplace Ctrl-R par la recherche Atuin

### Fzf: fuzzy finder
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always {} | head -100'"

### VS Code: ouverture rapide + complétions
alias code='env TERM=xterm-256color code'
zinit snippet https://github.com/microsoft/vscode/blob/main/resources/completions/zsh/_code

### Editor par défaut
export EDITOR="hx"
export VISUAL="hx"

### Remplacement de less
alias less='bat --paging=always' # Remplace less par bat
alias cat='bat'           # Affiche avec syntaxe
export BAT_THEME="TwoDark"
export BAT_STYLE="plain"

### Historique enrichi et propre
export HISTTIMEFORMAT="%F %T "  # Ajoute date/heure à l’historique
setopt HIST_IGNORE_DUPS         # Ignore doublons consécutifs
setopt HIST_IGNORE_ALL_DUPS     # Ignore tous les doublons

### Fonctions personnalisées

# Fonction yz : wrapper autour yazi pour changer de dossier
yz() {
  local target
  target=$(yazi --chooser-file=/tmp/yazi-cd)
  if [ -f /tmp/yazi-cd ]; then
    cd "$(cat /tmp/yazi-cd)" || echo "Échec du cd vers $(cat /tmp/yazi-cd)"
    rm /tmp/yazi-cd
  fi
}

### Aliases modernes
alias v='hx'              # Lance Helix
alias e='hx'              # Alias rapide pour éditer
alias c='clear'           # Nettoie le terminal
alias ..='cd ..'          # Monte d’un dossier
alias ...='cd ../..'      # Monte de deux dossiers
alias reload='source ~/.zshrc'  # Recharge la config
alias ls='lsd'            # Liste avec icônes
alias ll='lsd -l'         # Liste détaillée
alias la='lsd -la'        # Liste tous les fichiers
alias grep='rg'           # Recherche rapide
alias find='fd'           # Recherche de fichiers
alias df='duf'            # Affiche l’espace disque
alias du='gdu-go'         # Affiche la taille des dossiers
alias ps='procs'          # Affiche les processus
alias man='tldr'          # Manuels simplifiés
alias lg='lazygit'        # Interface Git
alias y='yazi'            # Explorateur de fichiers
alias top='btop'          # Remplace top
alias update-all='sudo apt update && sudo apt upgrade -y && brew update && brew upgrade && brew cleanup'
