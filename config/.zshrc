### ┌────────────────────────────────────────────┐
### │ Zinit: Plugin manager for Zsh              │
### └────────────────────────────────────────────┘
if [[ ! -f ~/.zinit/bin/zinit.zsh ]]; then
  mkdir -p ~/.zinit
  git clone https://github.com/zdharma-continuum/zinit ~/.zinit/bin
fi
source ~/.zinit/bin/zinit.zsh

### ┌────────────────────────────────────────────┐
### │ Plugins: Autocompletion, syntax, Docker... │
### └────────────────────────────────────────────┘
# Suggestions automatiques dans le terminal
zinit light zsh-users/zsh-autosuggestions

# Mise en couleur de la syntaxe dans le terminal
zinit light zsh-users/zsh-syntax-highlighting

# Complétions contextuelles avec fzf
zinit light Aloxaf/fzf-tab

# Complétions supplémentaires pour Zsh
zinit light zsh-users/zsh-completions

# Docker CLI completions
zinit light docker/cli

# Docker Compose completions
zinit light docker/compose

### ┌────────────────────────────────────────────┐
### │ Brew: environnement Linuxbrew              │
### └────────────────────────────────────────────┘
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

### ┌────────────────────────────────────────────┐
### │ Starship: prompt moderne et rapide         │
### └────────────────────────────────────────────┘
zinit ice wait'1'
zinit light starship/starship
eval "$(starship init zsh)"

### ┌────────────────────────────────────────────┐
### │ Zoxide: navigation intelligente            │
### └────────────────────────────────────────────┘
zinit ice wait'1'
zinit light ajeetdsouza/zoxide
eval "$(zoxide init zsh)"

### ┌────────────────────────────────────────────┐
### │ Atuin: historique shell synchronisé        │
### └────────────────────────────────────────────┘
zinit ice wait'1'
zinit light atuinsh/atuin
eval "$(atuin init zsh)"
export ATUIN_NOBIND="true"
bindkey '^R' atuin-search  # remplace Ctrl-R par la recherche Atuin

### ┌────────────────────────────────────────────┐
### │ Fzf: fuzzy finder                          │
### └────────────────────────────────────────────┘
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

### ┌────────────────────────────────────────────┐
### │ VS Code: ouverture rapide + complétions    │
### └────────────────────────────────────────────┘
alias code='env TERM=xterm-256color code'
zinit snippet https://github.com/microsoft/vscode/blob/main/resources/completions/zsh/_code

### ┌────────────────────────────────────────────┐
### │ Editor par défaut                          │
### └────────────────────────────────────────────┘
export EDITOR="hx"
export VISUAL="hx"

### ┌────────────────────────────────────────────┐
### │ Remplacement de less                       │
### └────────────────────────────────────────────┘
alias less='talespin'  # Pager moderne (si installé)

### ┌────────────────────────────────────────────┐
### │ Historique enrichi et propre               │
### └────────────────────────────────────────────┘
export HISTTIMEFORMAT="%F %T "  # Ajoute date/heure à l’historique
setopt HIST_IGNORE_DUPS         # Ignore doublons consécutifs
setopt HIST_IGNORE_ALL_DUPS     # Ignore tous les doublons

### ┌────────────────────────────────────────────┐
### │ Fonctions personnalisées                   │
### └────────────────────────────────────────────┘

# Fonction extract : décompresse automatiquement selon l’extension
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xvjf "$1" ;;
      *.tar.gz)    tar xvzf "$1" ;;
      *.tar.xz)    tar xvJf "$1" ;;
      *.bz2)       bunzip2 "$1" ;;
      *.rar)       unrar x "$1" ;;
      *.gz)        gunzip "$1" ;;
      *.tar)       tar xvf "$1" ;;
      *.tbz2)      tar xvjf "$1" ;;
      *.tgz)       tar xvzf "$1" ;;
      *.zip)       unzip "$1" ;;
      *.Z)         uncompress "$1" ;;
      *.7z)        7z x "$1" ;;
      *.xz)        unxz "$1" ;;
      *)           echo "Format non supporté : '$1'" ;;
    esac
  else
    echo "'$1' n'est pas un fichier valide"
  fi
}

# Fonction yz : wrapper autour yazi pour changer de dossier
yz() {
  local target
  target=$(yazi --chooser-file=/tmp/yazi-cd)
  if [ -f /tmp/yazi-cd ]; then
    cd "$(cat /tmp/yazi-cd)" || echo "Échec du cd vers $(cat /tmp/yazi-cd)"
    rm /tmp/yazi-cd
  fi
}

### ┌────────────────────────────────────────────┐
### │ Aliases modernes                           │
### └────────────────────────────────────────────┘
alias v='hx'              # Lance Helix
alias e='hx'              # Alias rapide pour éditer
alias c='clear'           # Nettoie le terminal
alias ..='cd ..'          # Monte d’un dossier
alias ...='cd ../..'      # Monte de deux dossiers
alias reload='source ~/.zshrc'  # Recharge la config
alias ls='lsd'            # Liste avec icônes
alias ll='lsd -l'         # Liste détaillée
alias la='lsd -la'        # Liste tous les fichiers
alias cat='bat'           # Affiche avec syntaxe
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
