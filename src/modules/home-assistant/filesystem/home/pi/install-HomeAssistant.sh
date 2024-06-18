#!/usr/bin/env bash
#### Smartpad Specific Tweaks for armbian images
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2023 - till today
#### https://github.com/KwadFan
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces
# Source error handling, leave this in place
set -Ee

# Source CustomPIOS common.sh
# shellcheck disable=SC1091
source /common.sh
install_cleanup_trap

#echo_green "Move script..."
#unpack /filesystem/home/pi/
#echo_green "Move script...(DONE)"

echo_green "Install Docker Home Assistant..."

# Création du script install.sh
#cat << 'EOF' > /home/pi/install.sh
#!/bin/bash

# Mise à jour du systeme
sudo apt update && sudo apt upgrade -y

# Docker Installation
echo "1. Installation de Docker..."
sudo apt-get install -y docker.io

# Vérification de l'installation Docker
echo "2. Vérification de l'installation Docker..."
sudo systemctl enable docker
sudo systemctl start docker
docker --version


# Installation d'AppArmor
echo "Installation d'AppArmor..."
sudo apt-get update
sudo apt-get install -y apparmor

# Vérification de l'installation d'AppArmor
echo "Vérification de l'installation d'AppArmor..."
if [ -x "$(command -v apparmor_parser)" ]; then
    echo "AppArmor est installé et accessible."
else
    echo "AppArmor n'est pas installé correctement. Tentative d'installation..."
    # Tentative d'installation d'AppArmor
    # La commande varie selon la distribution Linux
    # Pour Debian/Ubuntu :
    sudo apt-get update && sudo apt-get install -y apparmor apparmor-utils

    # Vérifier de nouveau après l'installation
    if [ -x "$(command -v apparmor_parser)" ]; then
        echo "AppArmor a été installé avec succès."
    else
        echo "Échec de l'installation d'AppArmor. Veuillez vérifier votre gestionnaire de paquets et vos sources de paquets."
        exit 1
    fi
fi

# Installation de Portainer
echo "Installation de Portainer..."

# Télécharger et installer le conteneur Portainer Server
echo "Installation de Portainer Server..."
curl -L https://downloads.portainer.io/ee2-19/portainer-agent-stack.yml -o portainer-agent-stack.yml
docker stack deploy -c portainer-agent-stack.yml portainer

# Vérifier si le conteneur Portainer Server a démarré
echo "Vérification de l'installation de Portainer Server..."
if docker ps | grep -q portainer; then
  echo "Portainer Server a été installé avec succès."
else
  echo "L'installation de Portainer Server a échoué."
  #exit 1
fi

# Exécutez la commande pour générer le mot de passe htpasswd
# HTPASSWD=$(docker run --rm httpd:2.4-alpine htpasswd -nbB admin "portainer_root" | cut -d ":" -f 2)
docker stop portainer
# docker run -d -p 9443:9443 -p 8000:8000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer-ce:latest --admin-password=$HTPASSWD
docker run -d -p 9443:9443 -p 8000:8000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer-ce:latest --admin="portainer_root"

echo "Configuration de Portainer terminée."

# preparation pour Home Assistant
sudo adduser --system --group homeassistant
sudo mkdir -p /home/homeassistant/.homeassistant
sudo chown -R homeassistant:homeassistant /home/homeassistant/.homeassistant

docker run -d \
  --name="home-assistant" \
  -v /home/homeassistant/.homeassistant:/config \
  -e TZ="Europe/Paris" \
  -p 8123:8123 \
  --net=host \
  homeassistant/home-assistant:stable

docker restart home-assistant

# Affichage de l'URL d'accès à Portainer Server
echo "Pour accéder à Portainer Server, ouvrez un navigateur et allez à :"
echo "https://localhost:9443"

# Récupération de l'adresse IP de la machine hôte
HOST_IP=$(hostname -I | awk '{print $1}')
echo "https://${HOST_IP}:9443"
echo "Utilisateur Admin et mot de passe - portainer_root"

echo "Installation terminée."
EOF

# Rendre le script exécutable
#sudo chmod +x /home/pi/install.sh

# Exécuter le script
#sudo ./home/pi/install.sh

echo_green "Install Docker Home Assistant...(DONE)"
