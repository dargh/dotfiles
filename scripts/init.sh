#!/bin/bash
set -e

source <(curl -fsSL https://raw.githubusercontent.com/<user>/dotfiles/main/lib/logger.sh)

log_step system "Mise à jour du système et installation des outils de base..."
sudo apt update && sudo apt upgrade -y || error "Échec de la mise à jour"
sudo apt install -y git build-essential curl wget unzip || error "Échec de l'installation des paquets de base"
ok "Système prêt"
