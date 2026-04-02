# Liftoff Game Server - Remote Desktop

A Docker-based remote Ubuntu desktop for running Liftoff (drone racing game) with BepInEx mod support. Access and control the game server through any web browser with secure authentication.

## Architecture

```
[Browser / Admin Page iframe]
        |  HTTPS (443)
    [Nginx Reverse Proxy]
    ├── SSL termination (Let's Encrypt)
    ├── Token-based authentication
    └── WebSocket proxy
        |  HTTP (6901)
    [Docker: Ubuntu Desktop]
    ├── XFCE4 desktop environment
    ├── Xvfb virtual display (software rendering)
    ├── KasmVNC (web-based remote desktop)
    ├── Steam client + Liftoff
    └── BepInEx mod loader
```

## Features

- **Web-based remote desktop** — Full Ubuntu desktop accessible from any browser via KasmVNC
- **Steam + Liftoff** — Pre-configured for running Liftoff with 32-bit library support
- **BepInEx mod loader** — Unity mod framework installed and ready for plugin deployment
- **Secure access** — Token-based authentication with SSL encryption
- **Embeddable** — Designed to be embedded as an iframe in your admin dashboard
- **Persistent storage** — Steam data and BepInEx mods survive container rebuilds via Docker volumes
- **Software rendering** — Runs headless without a GPU (suitable for menu-level interaction)

## Project Structure

```
├── docker/
│   ├── Dockerfile              # Ubuntu 22.04 + XFCE + KasmVNC + Steam + BepInEx
│   ├── docker-compose.yml      # Service orchestration (desktop + nginx)
│   └── entrypoint.sh           # Container startup (VNC setup, rendering, Steam install)
├── config/
│   ├── kasmvnc.yaml            # KasmVNC server config (resolution, framerate)
│   ├── nginx.conf              # Reverse proxy with SSL + token auth + WebSocket
│   └── supervisord.conf        # Process manager for Xvfb, XFCE, KasmVNC, PulseAudio
├── scripts/
│   ├── install-steam.sh        # Steam client installer
│   ├── install-bepinex.sh      # BepInEx → Liftoff installer
│   └── setup-ssl.sh            # Let's Encrypt certificate setup
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

### 1. Clone the repository

```bash
git clone https://github.com/geekhostuk/Liftoff_GameServer.git
cd Liftoff_GameServer
```

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env` with your settings:

```env
VNC_PASSWORD=your-secure-vnc-password
AUTH_TOKEN=$(openssl rand -hex 32)
DOMAIN=desktop.yourdomain.com
ADMIN_DOMAIN=admin.yourdomain.com
```

### 3. Set up SSL certificates

```bash
chmod +x scripts/setup-ssl.sh
sudo ./scripts/setup-ssl.sh desktop.yourdomain.com your@email.com
```

This uses Let's Encrypt (certbot) to obtain free SSL certificates and sets up automatic renewal.

### 4. Build and start

```bash
cd docker
docker compose up --build -d
```

### 5. Access the remote desktop

Open in your browser:

```
https://desktop.yourdomain.com/?token=YOUR_AUTH_TOKEN
```

You should see a full XFCE desktop environment.

## Steam Setup (First Time)

Steam Guard requires an interactive first login. This must be done through the remote desktop:

1. Connect to the remote desktop via your browser
2. Open a terminal in the desktop and run `steam`
3. Log in with your Steam credentials
4. Complete Steam Guard 2FA verification (email or mobile)
5. Install Liftoff through the Steam client

After the first login, credentials persist in the `liftoff-steam-data` Docker volume.

## BepInEx Setup

Once Liftoff is installed via Steam:

```bash
# Run from the VPS host
docker exec liftoff-desktop su - gamer -c /opt/scripts/install-bepinex.sh
```

Then configure Liftoff to launch through BepInEx:

1. In the remote desktop, open Steam
2. Right-click **Liftoff** → **Properties** → **Launch Options**
3. Set: `./run_bepinex.sh %command%`

### Adding Mods

Drop `.dll` plugin files into the BepInEx plugins volume:

```bash
# Copy a mod plugin into the container
docker cp MyPlugin.dll liftoff-desktop:/home/gamer/.steam/steam/steamapps/common/Liftoff/BepInEx/plugins/
```

Or mount a local directory by modifying `docker-compose.yml`:

```yaml
volumes:
  - ./mods:/home/gamer/.steam/steam/steamapps/common/Liftoff/BepInEx/plugins
```

### Checking BepInEx Logs

```bash
docker exec liftoff-desktop cat /home/gamer/.steam/steam/steamapps/common/Liftoff/BepInEx/LogOutput.log
```

## Embedding in Your Admin Page

The remote desktop can be embedded in any web page using an iframe. See `src/admin-embed.html` for a complete example.

Basic embed code:

```html
<iframe
  src="https://desktop.yourdomain.com/?token=YOUR_AUTH_TOKEN"
  width="100%"
  height="800"
  style="border: none;"
  allow="clipboard-read; clipboard-write"
  sandbox="allow-scripts allow-same-origin allow-forms"
></iframe>
```

For production use, generate time-limited tokens from your backend rather than using a static token.

## Configuration Reference

### Environment Variables (`.env`)

| Variable | Description | Default |
|----------|-------------|---------|
| `VNC_PASSWORD` | Password for VNC desktop access | `changeme` |
| `AUTH_TOKEN` | Token for web authentication | `changeme` |
| `DOMAIN` | Domain for the remote desktop | `desktop.localhost` |
| `ADMIN_DOMAIN` | Domain allowed to embed via iframe | `admin.localhost` |

### KasmVNC Settings (`config/kasmvnc.yaml`)

| Setting | Default | Description |
|---------|---------|-------------|
| Resolution | 1920x1080 | Desktop resolution |
| Max frame rate | 30fps | Sufficient for menu interaction |
| Quality range | 5-9 | Adaptive quality based on bandwidth |

### Docker Volumes

| Volume | Purpose |
|--------|---------|
| `liftoff-steam-data` | Steam client data, game installs, login session |
| `liftoff-bepinex-mods` | BepInEx plugin directory |
| `liftoff-certs` | SSL certificates |

## Management Commands

```bash
# View container logs
docker logs liftoff-desktop -f

# Restart the desktop
docker compose -f docker/docker-compose.yml restart desktop

# Rebuild after config changes
docker compose -f docker/docker-compose.yml up --build -d

# Stop everything
docker compose -f docker/docker-compose.yml down

# Stop and remove volumes (WARNING: deletes Steam data)
docker compose -f docker/docker-compose.yml down -v

# Shell into the container
docker exec -it liftoff-desktop bash

# Shell as the gamer user
docker exec -it liftoff-desktop su - gamer
```

## Security

- KasmVNC listens only on `127.0.0.1:6901` — never directly exposed to the internet
- All external access goes through Nginx with SSL encryption
- Token-based authentication on every request
- `Content-Security-Policy` restricts iframe embedding to your admin domain only
- Rate limiting prevents brute-force token attacks
- Desktop runs as non-root `gamer` user
- Secrets stored in `.env` (gitignored, never committed)

## Troubleshooting

### Desktop shows a black screen
Check that Xvfb and XFCE are running:
```bash
docker exec liftoff-desktop supervisorctl status
```

### Steam won't launch
Ensure 32-bit libraries are installed:
```bash
docker exec liftoff-desktop dpkg --print-foreign-architectures
# Should output: i386
```

### BepInEx not loading
Verify the launch options are set correctly and check:
```bash
docker exec liftoff-desktop cat /home/gamer/.steam/steam/steamapps/common/Liftoff/doorstop_config.ini
```

### Connection refused / 403
- Verify your `AUTH_TOKEN` matches between `.env` and the URL you're accessing
- Check Nginx logs: `docker logs liftoff-proxy`
- Ensure SSL certs exist in `certs/` directory

### High bandwidth usage
Reduce frame rate in `config/kasmvnc.yaml`:
```yaml
encoding:
  max_frame_rate: 15
```

## License

MIT
