#!/bin/bash

# --- Couleurs ---
GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

# --- Icônes ---
declare -A ICONS
ICONS=( ["system"]="⚙️" ["zsh"]="⚡" ["brew"]="🍺" ["apps"]="📦" ["font"]="🎨" ["dots"]="🔗" ["nvim"]=" V " ["summary"]="📜" )

# --- Fonctions de log ---
log_step() {
  local step="$1"; local msg="$2"
  local icon="${ICONS[$step]} "
  [ -z "$icon" ] && icon="ℹ️"
  echo -e "\n$(date '+%H:%M:%S') $icon ${BLUE}$msg${NC}"
}

ok()    { echo -e "$(date '+%H:%M:%S') ✅ ${GREEN}$1${NC}"; }
warn()  { echo -e "$(date '+%H:%M:%S') ⚠️ ${YELLOW}$1${NC}"; }
error() { echo -e "$(date '+%H:%M:%S') ❌ ${RED}$1${NC}"; exit 1; }
