#!/bin/bash
set -e

# Colors for echo
echo_green() {
  echo -e "\e[92m$1\e[0m"
}

# Function to install cleanup trap
install_cleanup_trap() {
  trap cleanup SIGINT SIGTERM
}

# Cleanup function
cleanup() {
  echo "Cleanup"
}

# Ensure we have sudo
if ! command -v sudo &> /dev/null; then
  echo "This script requires sudo. Please install sudo and run again."
  exit 1
fi

echo_green "Install Script chroot..."
install_cleanup_trap

# Unpack function
unpack() {
  from=$1
  to=$2
  owner=$3

  mkdir -p /tmp/unpack/
  cp -v -r --preserve=mode,timestamps $from/. /tmp/unpack/
  
  if [ -n "$owner" ]; then
    cp -v -r --preserve=mode,ownership,timestamps /tmp/unpack/. $to
  else
    cp -v -r --preserve=mode,timestamps /tmp/unpack/. $to
  fi
  
  rm -r /tmp/unpack
}

# Unpack home directory for pi user
unpack /filesystem/home/pi /home/pi
cd /home/pi
chmod +x start_chroot_script.sh
sudo ./start_chroot_script.sh

# Start chroot script
source /common.sh
install_cleanup_trap

BASE_USER=pi

if [ -z "$BASE_USER" ]; then
  echo "Base user is not set. Exiting."
  exit 1
fi

echo_green "Install Docker IO ..."
apt-get update
apt-get install -y docker.io
echo_green "Install Docker IO ...(DONE)"

echo_green "Add user Docker ..."
usermod -aG docker $BASE_USER
echo_green "Add user Docker ...(DONE)"

echo_green "Install python..."
apt-get install -y python3 python3-distutils python3-dev python3-testresources gcc libffi-dev build-essential libssl-dev cargo python3-cryptography python3-bcrypt python3-pip
echo_green "Install python ...(DONE)"

# Install Home Assistant using Docker
echo_green "Install Home Assistant using Docker..."

# Create Home Assistant Docker container
docker pull homeassistant/home-assistant:stable

# Create necessary directories for Home Assistant configuration
mkdir -p /home/$BASE_USER/homeassistant

# Run Home Assistant container
docker run -d \
  --name homeassistant \
  --privileged \
  --restart=unless-stopped \
  -e TZ=Europe/Paris \
  -v /home/$BASE_USER/homeassistant:/config \
  --network=host \
  homeassistant/home-assistant:stable

echo_green "Install Home Assistant using Docker ...(DONE)"

echo_green "Installation Complete! Home Assistant is running in a Docker container."
