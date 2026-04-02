#!/bin/bash
# Setup Let's Encrypt SSL certificates using certbot
# Run this on the VPS host (not inside Docker)
set -e

DOMAIN="${1:?Usage: ./setup-ssl.sh <domain>}"
EMAIL="${2:-}"

echo "==> Setting up SSL for $DOMAIN"

# Install certbot if not present
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    apt-get update && apt-get install -y certbot
fi

# Stop nginx temporarily if running (certbot needs port 80)
docker compose -f docker/docker-compose.yml stop nginx 2>/dev/null || true

# Obtain certificate
if [ -n "$EMAIL" ]; then
    certbot certonly --standalone -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive
else
    certbot certonly --standalone -d "$DOMAIN" --register-unsafely-without-email --agree-tos --non-interactive
fi

# Copy certs to Docker volume location
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
DOCKER_CERT_DIR="./certs"

mkdir -p "$DOCKER_CERT_DIR"
cp "$CERT_DIR/fullchain.pem" "$DOCKER_CERT_DIR/"
cp "$CERT_DIR/privkey.pem" "$DOCKER_CERT_DIR/"

echo ""
echo "==> SSL certificates installed"
echo "    Certs copied to $DOCKER_CERT_DIR"
echo ""
echo "==> Setting up auto-renewal cron"
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --post-hook 'cp /etc/letsencrypt/live/$DOMAIN/*.pem $PWD/certs/ && docker compose -f $PWD/docker/docker-compose.yml restart nginx'") | crontab -

echo "    Renewal cron added (runs daily at 3am)"
echo ""
echo "==> Now start the stack: cd docker && docker compose up -d"
