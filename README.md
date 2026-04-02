# Liftoff Game Server - Remote Desktop

A Docker-based remote Ubuntu desktop for running Liftoff (drone racing game) with BepInEx mod support. Access and control the game server through any web browser with secure authentication.

## Architecture

```
[Browser / Admin Page iframe]
        |  HTTPS (443)
    [Nginx Reverse Proxy]
    ├── SSL termination (Let's Encrypt)
    ├── Cookie-based session auth
    └── WebSocket proxy
        |  HTTP (6901)
    [Docker: Ubuntu Desktop]
    ├── XFCE4 desktop environment
    ├── Xvfb virtual display (software rendering)
    ├── x11vnc + noVNC (web-based remote desktop)
    ├── Steam client + Liftoff (auto-starts)
    └── BepInEx mod loader
```

## Features

- **Web-based remote desktop** -- Full Ubuntu desktop accessible from any browser via noVNC
- **Steam + Liftoff** -- Pre-installed Steam with auto-start, Liftoff with 32-bit library support
- **BepInEx mod loader** -- Unity mod framework with doorstop injection via modified launch.sh
- **Secure access** -- Token-based auth sets HttpOnly cookie, all traffic through Nginx
- **Embeddable** -- Designed to be embedded as an iframe in your admin dashboard
- **Persistent storage** -- Steam data and BepInEx mods survive container rebuilds via Docker volumes
- **Software rendering** -- Runs headless without a GPU (suitable for menu-level interaction)

## Project Structure

```
├── docker/
│   ├── Dockerfile              # Ubuntu 22.04 + XFCE + noVNC + Steam + BepInEx
│   ├── docker-compose.yml      # Service orchestration (desktop + nginx)
│   └── entrypoint.sh           # Container startup (permissions, BepInEx check)
├── config/
│   ├── nginx.conf              # Nginx template (envsubst for DOMAIN/TOKEN)
│   ├── nginx-ssl.conf          # HTTPS version (swap in after SSL setup)
│   └── supervisord.conf        # Process manager: Xvfb, XFCE, x11vnc, noVNC, Steam
├── scripts/
│   ├── generate-nginx.sh       # Generate nginx config from template + .env
│   ├── install-bepinex.sh      # BepInEx → Liftoff installer
│   ├── install-steam.sh        # Steam client installer (reference)
│   ├── liftoff-launch.sh       # BepInEx-enabled launch.sh replacement
│   ├── setup-host.sh           # Host kernel config for Steam user namespaces
│   └── setup-ssl.sh            # Let's Encrypt certificate setup
├── plugins/
│   └── LiftoffPhotonEventLogger.dll  # BepInEx plugin
├── src/
│   └── admin-embed.html        # Example iframe embed for admin pages
├── .env.example                # Environment variable template
└── .gitignore
```

## Prerequisites

- **VPS** running Ubuntu 22.04+ with Docker and Docker Compose installed
- **Domain name** pointed at your VPS IP address
- **Minimum specs**: 4 CPU cores, 8GB RAM, 50GB storage
- **Network**: 50Mbps+ upload recommended for smooth streaming

## Quick Start

### 1. Clone and configure

```bash
git clone https://github.com/geekhostuk/Liftoff_GameServer.git
cd Liftoff_GameServer
cp .env.example .env
```

Edit `.env` with your settings:

```bash
nano .env
```

```env
VNC_PASSWORD=your-secure-vnc-password
AUTH_TOKEN=<generate with: openssl rand -hex 32>
DOMAIN=desktop.yourdomain.com
ADMIN_DOMAIN=admin.yourdomain.com
```

### 2. Configure the host kernel (one-time)

Steam requires user namespaces. Run once:

```bash
sudo chmod +x scripts/setup-host.sh
sudo ./scripts/setup-host.sh
```

### 3. Generate nginx config

```bash
chmod +x scripts/generate-nginx.sh
./scripts/generate-nginx.sh
```

### 4. Build and start

```bash
cd docker
docker compose up --build -d
```

### 5. Access the remote desktop

Open in your browser:

```
http://YOUR_VPS_IP/auth?token=YOUR_AUTH_TOKEN
```

This validates the token, sets a session cookie, and redirects to the noVNC desktop.

## SSL Setup

Once DNS is pointing at your VPS:

```bash
cd ~/Liftoff_GameServer

# Stop nginx so certbot can use port 80
cd docker && docker compose stop nginx && cd ..

# Get SSL cert
sudo certbot certonly --standalone -d yourdomain.com --agree-tos --non-interactive --register-unsafely-without-email

# Copy certs
mkdir -p certs
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem certs/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem certs/
sudo chown $USER:$USER certs/*.pem

# Switch to SSL config
cp config/nginx-ssl.conf config/nginx.conf
./scripts/generate-nginx.sh

# Restart
cd docker && docker compose up -d
```

Access via: `https://yourdomain.com/auth?token=YOUR_AUTH_TOKEN`

## Steam Setup (First Time)

Steam auto-starts with the container using the `-no-browser` flag. On first launch:

1. Connect to the remote desktop via your browser
2. Steam should be running -- if you don't see the window, open a terminal and run:
   ```bash
   /usr/games/steam -no-browser +open steam://open/minigameslist
   ```
3. Log in with your Steam credentials
4. Complete Steam Guard 2FA verification (email or mobile)
5. Install Liftoff through the Steam client

After the first login, credentials persist in the `liftoff-steam-data` Docker volume.

## BepInEx Setup

BepInEx is pre-installed in the container. After Liftoff is installed:

### 1. Run the BepInEx installer

```bash
docker exec -it liftoff-desktop /opt/scripts/install-bepinex.sh
```

### 2. Replace Liftoff's launch script

This injects BepInEx's doorstop into the game. The standard `run_bepinex.sh` / launch options approach doesn't work with Steam's runtime wrappers, so we modify `launch.sh` directly:

```bash
docker cp scripts/liftoff-launch.sh liftoff-desktop:/home/gamer/.steam/steam/steamapps/common/Liftoff/launch.sh
docker exec -it liftoff-desktop chmod +x /home/gamer/.steam/steam/steamapps/common/Liftoff/launch.sh
```

**Do NOT set any Steam launch options** -- leave them blank. BepInEx loads automatically through the modified launch script.

### 3. Verify BepInEx is working

Launch Liftoff from Steam, then check:

```bash
docker exec -it liftoff-desktop cat /home/gamer/.steam/steam/steamapps/common/Liftoff/BepInEx/LogOutput.log
```

You should see `BepInEx 5.4.22.0 - Liftoff` and `Chainloader startup complete`.

### Adding Mods

Copy plugin DLLs into the container:

```bash
docker cp MyPlugin.dll liftoff-desktop:/home/gamer/.steam/steam/steamapps/common/Liftoff/BepInEx/plugins/
```

Plugins in the repo's `plugins/` directory can be deployed with:

```bash
docker cp plugins/LiftoffPhotonEventLogger.dll liftoff-desktop:/home/gamer/.steam/steam/steamapps/common/Liftoff/BepInEx/plugins/
```

### Editing Plugin Configs

```bash
docker exec -it liftoff-desktop nano /home/gamer/.steam/steam/steamapps/common/Liftoff/BepInEx/config/PLUGIN_NAME.cfg
```

### Checking BepInEx Logs

```bash
docker exec -it liftoff-desktop cat /home/gamer/.steam/steam/steamapps/common/Liftoff/BepInEx/LogOutput.log
```

## Embedding in Your Admin Page

The remote desktop can be embedded in any web page using an iframe. See `src/admin-embed.html` for a complete example.

```html
<iframe
  src="https://yourdomain.com/auth?token=YOUR_AUTH_TOKEN"
  width="100%"
  height="800"
  style="border: none;"
></iframe>
```

Set `ADMIN_DOMAIN` in your `.env` to the domain hosting the iframe, then regenerate the nginx config.

## Configuration Reference

### Environment Variables (`.env`)

| Variable | Description | Default |
|----------|-------------|---------|
| `VNC_PASSWORD` | Password for VNC desktop access | `changeme` |
| `AUTH_TOKEN` | Token for web authentication | `changeme` |
| `DOMAIN` | Domain for the remote desktop | `desktop.localhost` |
| `ADMIN_DOMAIN` | Domain allowed to embed via iframe | `admin.localhost` |

### Docker Volumes

| Volume | Host Path | Purpose |
|--------|-----------|---------|
| `liftoff-steam-data` | `/var/lib/docker/volumes/liftoff-steam-data/_data` | Steam client data, game installs, login session |
| `liftoff-bepinex-mods` | `/var/lib/docker/volumes/liftoff-bepinex-mods/_data` | BepInEx plugin directory |

**Important:** `docker compose down` preserves volumes. Only `docker compose down -v` deletes them.

## Management Commands

```bash
# View container logs
docker logs liftoff-desktop -f

# Restart the desktop
cd docker && docker compose restart desktop

# Rebuild after config changes
cd docker && docker compose down && docker compose up --build -d

# Stop everything (keeps volumes)
cd docker && docker compose down

# Stop and DELETE ALL DATA (games, login, mods)
cd docker && docker compose down -v

# Shell into the container
docker exec -it liftoff-desktop bash

# Shell as the gamer user
docker exec -it -u gamer liftoff-desktop bash
```

## Security

- noVNC listens only on `127.0.0.1:6901` -- never directly exposed to the internet
- All external access goes through Nginx with SSL encryption
- Token auth on `/auth` endpoint sets HttpOnly session cookie
- Subsequent requests (assets, WebSocket) authenticated via cookie
- `Content-Security-Policy` restricts iframe embedding to your admin domain only
- Rate limiting prevents brute-force token attacks
- Container runs privileged (required for Steam's user namespace sandbox)
- Secrets stored in `.env` (gitignored, never committed)

## Troubleshooting

### Desktop shows a black screen
Check that all services are running:
```bash
docker logs liftoff-desktop --tail 20
```
All 5 services (pulseaudio, xvfb, xfce, x11vnc, novnc) should show RUNNING.

### Steam doesn't show a window
Steam runs with `-no-browser` flag. If no window appears:
```bash
docker exec -it liftoff-desktop pkill -9 -f steam
```
Wait 10 seconds for supervisor to auto-restart it.

### 403 Forbidden
- Access via `/auth?token=YOUR_TOKEN` (not just `/?token=`)
- Verify token matches: `grep AUTH_TOKEN .env`
- Regenerate nginx config: `./scripts/generate-nginx.sh`

### BepInEx not loading
- Ensure `launch.sh` was replaced with the BepInEx version (see BepInEx Setup)
- Steam launch options must be **blank**
- Check log: `docker exec -it liftoff-desktop cat /home/gamer/.steam/steam/steamapps/common/Liftoff/BepInEx/LogOutput.log`

### Steam requires user namespaces
Run on the host:
```bash
sudo ./scripts/setup-host.sh
```

## License

MIT
