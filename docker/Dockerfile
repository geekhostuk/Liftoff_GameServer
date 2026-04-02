FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    LIBGL_ALWAYS_SOFTWARE=1 \
    GALLIUM_DRIVER=llvmpipe \
    HOME=/home/gamer

# Core system packages + display + desktop
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    mesa-utils \
    pulseaudio \
    supervisor \
    wget \
    curl \
    ca-certificates \
    locales \
    fonts-liberation \
    fonts-dejavu-core \
    unzip \
    xdg-utils \
    libglib2.0-0 \
    libnss3 \
    libxss1 \
    libasound2 \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install x11vnc and noVNC for web-based remote desktop
RUN apt-get update && apt-get install -y --no-install-recommends \
    x11vnc \
    python3 \
    python3-numpy \
    git \
    && git clone --depth 1 https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone --depth 1 https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify \
    && ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable 32-bit architecture for Steam
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    libgl1-mesa-dri:i386 \
    libgl1-mesa-glx:i386 \
    libc6:i386 \
    libstdc++6:i386 \
    libx11-6:i386 \
    libxext6:i386 \
    libxrandr2:i386 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Steam - accept EULA and install the launcher package
RUN wget -q "https://cdn.akamai.steamstatic.com/client/installer/steam.deb" -O /tmp/steam.deb \
    && echo 'steam steam/question select I AGREE' | debconf-set-selections \
    && echo 'steam steam/license note ' | debconf-set-selections \
    && dpkg -i /tmp/steam.deb; apt-get -f install -y \
    && rm /tmp/steam.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Download BepInEx for Unix (Liftoff is Unity Mono)
ARG BEPINEX_VERSION=5.4.22
RUN mkdir -p /opt/bepinex \
    && wget -q "https://github.com/BepInEx/BepInEx/releases/download/v${BEPINEX_VERSION}/BepInEx_unix_${BEPINEX_VERSION}.0.zip" \
        -O /opt/bepinex/bepinex.zip

# Create non-root user
RUN useradd -m -s /bin/bash -G audio,video gamer

# Copy configuration files
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/install-steam.sh /opt/scripts/install-steam.sh
COPY scripts/install-bepinex.sh /opt/scripts/install-bepinex.sh
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh /opt/scripts/*.sh

EXPOSE 6901

ENTRYPOINT ["/entrypoint.sh"]
