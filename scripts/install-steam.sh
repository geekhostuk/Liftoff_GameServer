#!/bin/bash
# Install Steam client from pre-downloaded .deb
# Run as root (called from entrypoint)
set -e

if command -v steam &> /dev/null; then
    echo "Steam is already installed."
    exit 0
fi

if [ ! -f /opt/steam.deb ]; then
    echo "Downloading Steam installer..."
    wget -q "https://cdn.akamai.steamstatic.com/client/installer/steam.deb" -O /opt/steam.deb
fi

echo "Installing Steam..."
dpkg -i /opt/steam.deb 2>/dev/null || true
apt-get -f install -y

echo "Steam installed successfully."
echo ""
echo "IMPORTANT: You must log into Steam manually through the VNC desktop."
echo "Steam Guard 2FA requires interactive login for the first time."
echo "After first login, credentials are cached in the steam-data volume."
