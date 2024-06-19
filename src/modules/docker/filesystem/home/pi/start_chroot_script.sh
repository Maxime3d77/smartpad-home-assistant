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

echo_green "Install Docker IO ..."
apt-get update
apt-get install -y docker.io
echo_green "Install Docker IO ...(DONE)"

echo_green "Add user Docker ..."
usermod pi -aG docker
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

#cleanup
apt-get clean
apt-get autoremove -y
