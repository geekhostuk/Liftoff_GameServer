#!/bin/bash
# Install BepInEx into Liftoff game directory
# Run as gamer user
set -e

STEAM_DIR="${HOME}/.steam/steam"
LIFTOFF_DIR="${STEAM_DIR}/steamapps/common/Liftoff"
BEPINEX_ZIP="/opt/bepinex/bepinex.zip"

# Check if Liftoff is installed
if [ ! -d "$LIFTOFF_DIR" ]; then
    echo "ERROR: Liftoff is not installed at $LIFTOFF_DIR"
    echo "Please install Liftoff through Steam first, then run this script again."
    exit 1
fi

# Check if BepInEx core is already installed (not just the directory)
if [ -f "$LIFTOFF_DIR/run_bepinex.sh" ] && [ -d "$LIFTOFF_DIR/BepInEx/core" ]; then
    echo "BepInEx is already fully installed. Use --force to reinstall."
    [ "$1" != "--force" ] && exit 0
fi

# Check for BepInEx zip
if [ ! -f "$BEPINEX_ZIP" ]; then
    echo "ERROR: BepInEx archive not found at $BEPINEX_ZIP"
    exit 1
fi

echo "Installing BepInEx into Liftoff..."
unzip -o "$BEPINEX_ZIP" -d "$LIFTOFF_DIR"

# Make the launch script executable
chmod +x "$LIFTOFF_DIR/run_bepinex.sh"

echo "BepInEx installed successfully."
echo ""
echo "To activate BepInEx, set Steam launch options for Liftoff:"
echo "  Right-click Liftoff -> Properties -> Launch Options"
echo "  Set: ./run_bepinex.sh %command%"
echo ""
echo "Place mod plugins (.dll) in:"
echo "  $LIFTOFF_DIR/BepInEx/plugins/"
echo ""
echo "Check logs at:"
echo "  $LIFTOFF_DIR/BepInEx/LogOutput.log"
