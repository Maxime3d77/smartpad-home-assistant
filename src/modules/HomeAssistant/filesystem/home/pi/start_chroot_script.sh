#!/bin/bash
########
# shellcheck enable=require-variable-braces
# Source error handling, leave this in place
set -Ee

# Source CustomPIOS common.sh
# shellcheck disable=SC1091
source /common.sh
install_cleanup_trap

BASE_USER=pi

echo_green "Install Docker IO CE ..."
apt-get update
apt-get install -y curl
# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

# Set up the stable repository for Docker
add-apt-repository \
   "deb [arch=arm64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

apt-get update

# Install Docker
apt-get install -y docker-ce docker-ce-cli containerd.io

echo_green "Run Hello ..."
docker run --rm hello-world # test - you may skip
echo_green "Run Hello ...(DONE)"
echo_green "Docker version ...(DONE)"
docker --version
echo_green "Docker version ...(DONE)"
echo_green "Install Docker IO CE ...(DONE)"

echo_green "Add user Docker ..."
usermod -aG docker "${BASE_USER}"
echo_green "Add user Docker ...(DONE)"

echo_green "Install python..."
apt-get install -y python3-pip python3-dev libffi-dev libssl-dev
echo_green "Install python ...(DONE)"

echo_green "Install Docker Compose ..."
pip3 install docker-compose
docker-compose --version
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
