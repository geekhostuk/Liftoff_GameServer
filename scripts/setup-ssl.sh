#!/bin/bash
# Setup Let's Encrypt SSL certificates using certbot
# Run this from the project root on the VPS host (not inside Docker)
set -e

DOMAIN="${1:?Usage: ./setup-ssl.sh <domain> [email]}"
EMAIL="${2:-}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Setting up SSL for $DOMAIN"
echo "    Project dir: $PROJECT_DIR"

# Install certbot if not present
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    apt-get update && apt-get install -y certbot
fi

# Stop nginx temporarily if running (certbot needs port 80)
docker compose -f "$PROJECT_DIR/docker/docker-compose.yml" stop nginx 2>/dev/null || true

# Obtain certificate
if [ -n "$EMAIL" ]; then
    certbot certonly --standalone -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive
else
    certbot certonly --standalone -d "$DOMAIN" --register-unsafely-without-email --agree-tos --non-interactive
fi

# Copy certs to project
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
DOCKER_CERT_DIR="$PROJECT_DIR/certs"

mkdir -p "$DOCKER_CERT_DIR"
cp "$CERT_DIR/fullchain.pem" "$DOCKER_CERT_DIR/"
cp "$CERT_DIR/privkey.pem" "$DOCKER_CERT_DIR/"

# Switch nginx to SSL config
echo "==> Switching nginx to SSL configuration"
cp "$PROJECT_DIR/config/nginx-ssl.conf" "$PROJECT_DIR/config/nginx.conf"

echo ""
echo "==> SSL certificates installed"
echo "    Certs in: $DOCKER_CERT_DIR"
echo ""
echo "==> Rebuild and restart:"
echo "    cd $PROJECT_DIR/docker && docker compose up --build -d"
echo ""
echo "==> Setting up auto-renewal cron"
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --post-hook 'cp /etc/letsencrypt/live/$DOMAIN/*.pem $DOCKER_CERT_DIR/ && docker compose -f $PROJECT_DIR/docker/docker-compose.yml restart nginx'") | crontab -

echo "    Renewal cron added (runs daily at 3am)"
