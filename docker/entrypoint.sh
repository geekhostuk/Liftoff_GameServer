#!/bin/bash
set -e

DISPLAY="${DISPLAY:-:1}"
RESOLUTION="${RESOLUTION:-1920x1080x24}"

echo "==> Checking GPU availability (required)"
if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
    echo "    NVIDIA GPU detected: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null)"
    echo "    Driver version: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null)"
    echo "    NVENC sessions available: $(nvidia-smi --query-gpu=encoder.stats.sessionCount --format=csv,noheader 2>/dev/null || echo 'N/A')"
else
    echo "ERROR: NVIDIA GPU not detected. GPU is required for this setup."
    echo "       Ensure nvidia-container-toolkit is installed and GPU passthrough is configured."
    exit 1
fi

echo "==> Configuring VirtualGL"
if [ -x /opt/VirtualGL/bin/vglserver_config ]; then
    /opt/VirtualGL/bin/vglserver_config -config +s +f -t 2>/dev/null || true
fi

echo "==> Fixing permissions"
chown -R gamer:gamer /home/gamer

echo "==> Checking for BepInEx installation"
LIFTOFF_DIR="/home/gamer/.steam/steam/steamapps/common/Liftoff"
if [ -d "$LIFTOFF_DIR" ] && [ ! -d "$LIFTOFF_DIR/BepInEx" ]; then
    echo "    Liftoff found, installing BepInEx..."
    su - gamer -c "/opt/scripts/install-bepinex.sh"
fi

echo "==> Patching steamwebhelper for container GPU compatibility"
HELPER="/home/gamer/.steam/ubuntu12_64/steamwebhelper"
# Clean up stale .real file from previous failed wrapper attempts
if [ -f "${HELPER}.real" ] && [ ! -f "${HELPER}.orig" ]; then
    if file "${HELPER}.real" | grep -q "ELF"; then
        mv "${HELPER}.real" "$HELPER"
        echo "    Restored steamwebhelper from stale .real file"
    fi
fi
# Wrap the binary if it's the real ELF executable
if [ -f "$HELPER" ] && file "$HELPER" | grep -q "ELF"; then
    mv "$HELPER" "${HELPER}.orig"
    cat > "$HELPER" << 'WRAPPER'
#!/bin/bash
exec "$(dirname "$(realpath "$0")")/steamwebhelper.orig" --no-sandbox --disable-gpu --disable-gpu-compositing "$@"
WRAPPER
    chmod +x "$HELPER"
    chown gamer:gamer "$HELPER" "${HELPER}.orig"
    echo "    Wrapped steamwebhelper with --disable-gpu"
elif [ -f "${HELPER}.orig" ]; then
    echo "    steamwebhelper already wrapped"
else
    echo "    steamwebhelper not found (first run)"
fi

echo "==> Starting supervisord"
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
