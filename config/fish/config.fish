# ------------------------
# Initialisation de Homebrew
# ------------------------
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# ------------------------
# Initialisation de Starship (prompt moderne)
# ------------------------
starship init fish | source

# ------------------------
# Variables d'environnement
# ------------------------
set -x EDITOR "hx"               # Éditeur par défaut (Helix)
set -x VISUAL "hx"               # Éditeur visuel par défaut (Helix)
set -x BAT_THEME "TwoDark"       # Thème de syntaxe pour Bat
set -x BAT_STYLE "plain"         # Style de sortie pour Bat