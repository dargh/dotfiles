function update-all
    echo "Mise à jour du système et des paquets..."
    fastfetch
    sudo apt update && sudo apt upgrade -y
    brew update && brew upgrade && brew cleanup
    fisher update
end
