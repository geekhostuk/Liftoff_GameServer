#!/bin/bash
# Find and wrap all steamwebhelper binaries with --disable-gpu flags.
# Runs at container start and as a one-shot supervisor job after Steam
# has had time to install/update.
set -e

STEAM_DIRS=(
    "/home/gamer/.steam"
    "/home/gamer/.local/share/Steam"
)

wrapped=0

for BASE in "${STEAM_DIRS[@]}"; do
    [ -d "$BASE" ] || continue
    while IFS= read -r HELPER; do
        if [ ! -f "${HELPER}.real" ]; then
            mv "$HELPER" "${HELPER}.real"
            cat > "$HELPER" << 'WRAPPER'
#!/bin/bash
exec "$(dirname "$(realpath "$0")")/steamwebhelper.real" --no-sandbox --disable-gpu --disable-gpu-compositing "$@"
WRAPPER
            chmod +x "$HELPER"
            chown gamer:gamer "$HELPER" "${HELPER}.real"
            echo "Wrapped: $HELPER"
            wrapped=$((wrapped + 1))
        fi
    done < <(find "$BASE" -name "steamwebhelper" -type f -executable ! -name "*.real" 2>/dev/null)
done

if [ "$wrapped" -gt 0 ]; then
    echo "Wrapped $wrapped steamwebhelper binary(ies). Restarting Steam..."
    # Kill Steam so supervisord restarts it with the wrapped binary
    pkill -f "/usr/games/steam" 2>/dev/null || true
else
    echo "No unwrapped steamwebhelper binaries found."
fi
