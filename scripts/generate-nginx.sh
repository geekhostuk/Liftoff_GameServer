#!/bin/bash
# Generate nginx config from template, substituting only our env vars
# Run from project root after setting up .env
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Load .env
if [ -f "$PROJECT_DIR/.env" ]; then
    export $(grep -v '^#' "$PROJECT_DIR/.env" | xargs)
fi

DOMAIN="${DOMAIN:-desktop.localhost}"
ADMIN_DOMAIN="${ADMIN_DOMAIN:-admin.localhost}"
AUTH_TOKEN="${AUTH_TOKEN:-changeme}"

# Only substitute our 3 variables, leave all nginx $variables untouched
envsubst '${DOMAIN} ${ADMIN_DOMAIN} ${AUTH_TOKEN}' \
    < "$PROJECT_DIR/config/nginx.conf" \
    > "$PROJECT_DIR/config/generated-nginx.conf"

echo "Generated nginx config with:"
echo "  DOMAIN=$DOMAIN"
echo "  ADMIN_DOMAIN=$ADMIN_DOMAIN"
echo "  AUTH_TOKEN=${AUTH_TOKEN:0:8}..."
echo "  Output: config/generated-nginx.conf"
