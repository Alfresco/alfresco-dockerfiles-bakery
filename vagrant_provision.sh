#!/bin/bash

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
x86_64)
    ARCH="amd64"
    ;;
aarch64)
    ARCH="arm64"
    ;;
*)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

echo "Installing yq..."
wget -q https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_linux_${ARCH} -O /usr/local/bin/yq
chmod +x /usr/local/bin/yq

echo "Installing Grype..."
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

echo "Installing Docker..."
wget -q https://download.docker.com/linux/ubuntu/gpg -O /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -qq
apt-get install -qy \
    make \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "Adding vagrant user to docker group"
adduser vagrant docker
