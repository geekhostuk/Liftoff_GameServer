#!/bin/bash
set -e

VNC_PASSWORD="${VNC_PASSWORD:-changeme}"
DISPLAY="${DISPLAY:-:1}"
RESOLUTION="${RESOLUTION:-1920x1080x24}"

echo "==> Setting up VNC"
mkdir -p /home/gamer/.vnc

echo "==> Configuring software rendering"
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe

echo "==> Installing Steam (first run)"
if ! command -v steam &> /dev/null && [ -f /opt/steam.deb ]; then
    echo "    Installing Steam package..."
    dpkg -i /opt/steam.deb 2>/dev/null || apt-get -f install -y 2>/dev/null || true
fi

echo "==> Fixing permissions"
chown -R gamer:gamer /home/gamer

echo "==> Checking for BepInEx installation"
LIFTOFF_DIR="/home/gamer/.steam/steam/steamapps/common/Liftoff"
if [ -d "$LIFTOFF_DIR" ] && [ ! -d "$LIFTOFF_DIR/BepInEx" ]; then
    echo "    Liftoff found, installing BepInEx..."
    su - gamer -c "/opt/scripts/install-bepinex.sh"
fi

echo "==> Starting supervisord"
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
