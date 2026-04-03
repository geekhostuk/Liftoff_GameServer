#!/bin/bash
# Clone Steam and BepInEx volumes to create a new game server instance
# Usage: ./clone-volumes.sh <instance-number>
# Example: ./clone-volumes.sh 2
#
# Server 1 must be stopped first: docker compose -f docker/docker-compose.yml down
set -e

INSTANCE="${1:?Usage: clone-volumes.sh <instance-number>}"

STEAM_SRC="liftoff-steam-data"
STEAM_DST="liftoff-steam-data-${INSTANCE}"
MODS_SRC="liftoff-bepinex-mods"
MODS_DST="liftoff-bepinex-mods-${INSTANCE}"

# Check source volumes exist
for vol in "$STEAM_SRC" "$MODS_SRC"; do
    if ! docker volume inspect "$vol" > /dev/null 2>&1; then
        echo "Error: Source volume '$vol' not found. Is server 1 set up?"
        exit 1
    fi
done

# Check destination volumes don't already exist
for vol in "$STEAM_DST" "$MODS_DST"; do
    if docker volume inspect "$vol" > /dev/null 2>&1; then
        echo "Error: Destination volume '$vol' already exists. Remove it first or use a different instance number."
        exit 1
    fi
done

echo "Cloning volumes for instance ${INSTANCE}..."
echo "  ${STEAM_SRC} -> ${STEAM_DST}"
echo "  ${MODS_SRC} -> ${MODS_DST}"
echo ""
echo "This may take 5-15 minutes depending on data size."
echo ""

# Clone steam-data
echo "Creating volume ${STEAM_DST}..."
docker volume create "${STEAM_DST}"
echo "Copying steam data (this is the large one)..."
docker run --rm \
    -v "${STEAM_SRC}:/source:ro" \
    -v "${STEAM_DST}:/dest" \
    alpine sh -c "cp -a /source/. /dest/"
echo "Steam data cloned."

# Clone bepinex-mods
echo "Creating volume ${MODS_DST}..."
docker volume create "${MODS_DST}"
echo "Copying BepInEx mods..."
docker run --rm \
    -v "${MODS_SRC}:/source:ro" \
    -v "${MODS_DST}:/dest" \
    alpine sh -c "cp -a /source/. /dest/"
echo "BepInEx mods cloned."

echo ""
echo "Done! Volumes for instance ${INSTANCE} are ready."
echo "Next steps:"
echo "  1. Add DOMAIN_2, AUTH_TOKEN_2, VNC_PASSWORD_2 to your .env file"
echo "  2. Run: bash scripts/generate-nginx.sh"
echo "  3. Run: docker compose -f docker/docker-compose.yml up --build -d"
