#!/usr/bin/env bash
# CustomPiOS module : docker
# Original script written by Damien DALY (https://github.com/MaitreDede/)
# Changes by Guy Sheffer
# GPL V3
########
# shellcheck enable=require-variable-braces
# Source error handling, leave this in place
set -ex

# Source CustomPIOS common.sh
# shellcheck disable=SC1091
source /common.sh
install_cleanup_trap

# Define BASE_USER if not already defined
BASE_USER="${BASE_USER:-pi}"

# Verify that BASE_USER is set
if [ -z "${BASE_USER}" ]; then
    echo_red "Error: BASE_USER variable is not set. Exiting..."
    exit 1
fi

echo_green "Install Docker IO ..."
apt-get update
apt-get install -y docker.io
echo_green "Install Docker IO ...(DONE)"

echo_green "Add user Docker ..."
usermod "${BASE_USER}" -aG docker
echo_green "Add user Docker ...(DONE)"

echo_green "Install python..."
apt-get install -y python3 python3-distutils python3-dev python3-testresources gcc libffi-dev build-essential libssl-dev cargo python3-cryptography python3-bcrypt python3-pip
echo_green "Install python...(DONE)"
    
# Upgrade pip to the latest version
pip3 install --upgrade pip
    
# Install PyYAML ignoring pre-installed versions
echo_green "Install PyYAML ..."
apt-get install -y python3-yaml
echo_green "Install PyYAML ...(DONE)"
    
# Install docker-compose
echo_green "Install Docker compose ..."
apt-get install -y docker-compose
echo_green "Install Docker compose ...(DONE)"

echo_green "Starting Docker service..."
systemctl start docker
systemctl enable docker
echo_green "Docker service started and enabled to start on boot...(DONE)"

# Wait for Docker to be ready
echo_green "Waiting for Docker to start..."
for i in {1..10}; do
    docker info && break
    echo "Docker not ready yet, waiting..."
    sleep 3
done
if ! docker info; then
    echo_red "Docker did not start correctly. Exiting..."
    exit 1
fi
echo_green "Docker is running...(DONE)"

echo_green "Unpack Docker file & service..."
unpack /filesystem/root /
unpack /filesystem/boot /"${BASE_BOOT_MOUNT_PATH}"
    
if [ "${DOCKER_COMPOSE_BOOT_PATH}" == "default" ]; then
    DOCKER_COMPOSE_BOOT_PATH_ACTUAL="/${BASE_BOOT_MOUNT_PATH}"/docker-compose
else
    DOCKER_COMPOSE_BOOT_PATH_ACTUAL="${DOCKER_COMPOSE_BOOT_PATH}"
fi
sed -i "s@DOCKER_COMPOSE_BOOT_PATH_PLACEHOLDER@${DOCKER_COMPOSE_BOOT_PATH_ACTUAL}@g" /etc/systemd/system/docker-compose.service
sed -i "s@DOCKER_COMPOSE_BOOT_PATH_PLACEHOLDER@${DOCKER_COMPOSE_BOOT_PATH_ACTUAL}@g" /usr/bin/start_docker_compose
sed -i "s@DOCKER_COMPOSE_BOOT_PATH_PLACEHOLDER@${DOCKER_COMPOSE_BOOT_PATH_ACTUAL}@g" /usr/bin/stop_docker_compose
systemctl enable docker-compose.service
echo_green "Unpack Docker file & service...(DONE)"

# Create directories and docker-compose.yml file for Home Assistant
echo_green "Setting up Home Assistant with Docker Compose..."
mkdir -p /home/pi/docker/homeAssistant
cat << EOF > /home/pi/docker/homeAssistant/docker-compose.yml
version: '3'
services:
  homeassistant:
    container_name: homeassistant
    image: "ghcr.io/home-assistant/home-assistant:stable"
    volumes:
      - /home/pi/homeassistant/config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
    restart: unless-stopped
    privileged: true
    network_mode: host
EOF

# Set permissions for the created directories and files
chown -R pi:pi /home/pi/docker /home/pi/homeassistant

# Start the Home Assistant container
cd /home/pi/docker/homeAssistant
docker-compose up -d
echo_green "Home Assistant setup and started...(DONE)"

# Cleanup
apt-get clean
apt-get autoremove -y
