#!/bin/bash
# Script de setup CLI Proxy API tren server langhit.com
# Usage: bash setup-on-server.sh

set -e

echo "=== Setup CLI Proxy API on Server ==="
echo ""

# Kiem tra quyen root
if [ "$EUID" -ne 0 ]; then 
    echo "Vui long chay voi quyen root: sudo bash setup-on-server.sh"
    exit 1
fi

# Cai Docker neu chua co
if ! command -v docker &> /dev/null; then
    echo "Cai dat Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

# Cai Docker Compose neu chua co
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Cai dat Docker Compose..."
    apt-get update
    apt-get install -y docker-compose-plugin
fi

# Tao thu muc
INSTALL_DIR="/opt/cli-proxy-api"
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

echo "Thu muc: $INSTALL_DIR"
echo ""

# Neu chua co code, hoi user
if [ ! -f "docker-compose.yml" ]; then
    echo "Chua co code trong $INSTALL_DIR"
    echo "Vui long:"
    echo "  1. Upload code vao $INSTALL_DIR"
    echo "  2. Hoac git clone vao $INSTALL_DIR"
    echo ""
    read -p "Ban co muon git clone? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Nhap git repository URL: " GIT_REPO
        git clone $GIT_REPO .
    else
        echo "Vui long upload code thu cong"
        exit 1
    fi
fi

# Tao config neu chua co
if [ ! -f "config.yaml" ]; then
    if [ -f "config.example.yaml" ]; then
        cp config.example.yaml config.yaml
        echo "Da tao config.yaml tu config.example.yaml"
        echo "Vui long chinh sua config.yaml:"
        echo "  nano config.yaml"
    else
        echo "Canh bao: Khong tim thay config.example.yaml"
    fi
fi

# Tao thu muc auths va logs
mkdir -p auths logs

# Chay Docker Compose
echo ""
echo "Dang chay CLI Proxy API..."
docker-compose down 2>/dev/null || true
docker-compose up -d --build

# Kiem tra
sleep 3
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "=== THANH CONG ==="
    echo ""
    echo "CLI Proxy API dang chay!"
    echo ""
    docker-compose ps
    echo ""
    echo "URL: http://$(hostname -I | awk '{print $1}'):8317"
    echo "Hoac: http://localhost:8317 (neu cung server)"
    echo ""
    echo "De xem logs:"
    echo "  docker-compose logs -f"
    echo ""
else
    echo ""
    echo "Loi: CLI Proxy API khong the khoi dong"
    echo "Kiem tra logs:"
    echo "  docker-compose logs"
    exit 1
fi

