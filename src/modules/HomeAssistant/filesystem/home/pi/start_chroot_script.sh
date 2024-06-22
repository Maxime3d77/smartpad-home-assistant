#!/bin/bash
########
# shellcheck enable=require-variable-braces
# Source error handling, leave this in place
set -Ee

# Source CustomPIOS common.sh
# shellcheck disable=SC1091
source /common.sh
install_cleanup_trap


echo_green "Install Script chroot..."


# Unpack home directory for pi user
unpack /filesystem/home/pi /home/pi
cd /home/pi
chmod +x start_chroot_script.sh
sudo ./start_chroot_script.sh



BASE_USER=pi

echo_green "Install Docker IO ..."
apt-get update
apt-get install -y docker.io
echo_green "Install Docker IO ...(DONE)"

echo_green "Add user Docker ..."
usermod -aG docker "${BASE_USER}"
echo_green "Add user Docker ...(DONE)"

echo_green "Install python..."
apt-get install -y python3 python3-distutils python3-dev python3-testresources gcc libffi-dev build-essential libssl-dev cargo python3-cryptography python3-bcrypt python3-pip
echo_green "Install python ...(DONE)"

echo_green "Install Docker Compose ..."
sudo curl -L "https://github.com/docker/compose/releases/download/2.28.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
sudo curl -L https://raw.githubusercontent.com/docker/compose/2.28.0/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
echo_green "Install Docker Compose ...(DONE)"


# Install Home Assistant using Docker
echo_green "Install Home Assistant using Docker..."

# Create Home Assistant Docker container
docker pull homeassistant/home-assistant:stable

# Create necessary directories for Home Assistant configuration
mkdir -p /home/"${BASE_USER}"/homeassistant

# Run Home Assistant container
docker run -d \
  --name homeassistant \
  --privileged \
  --restart=unless-stopped \
  -e TZ=Europe/Paris \
  -v /home/"${BASE_USER}"/homeassistant:/config \
  --network=host \
  homeassistant/home-assistant:stable

echo_green "Install Home Assistant using Docker ...(DONE)"

echo_green "Installation Complete! Home Assistant is running in a Docker container."
