FROM nvidia/cuda:12.3.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    HOME=/home/gamer \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all

# Core system packages + display + desktop + GStreamer
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    x11-xserver-utils \
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
    nano \
    file \
    # Build tools for Python C extensions (evdev)
    build-essential \
    # GStreamer for Selkies streaming
    python3 \
    python3-pip \
    python3-dev \
    python3-gi \
    python3-setuptools \
    python3-websockets \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-gl \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-x \
    gir1.2-gst-plugins-base-1.0 \
    gir1.2-gstreamer-1.0 \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    # VirtualGL dependencies
    libxtst6 \
    libxv1 \
    libegl1 \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install VirtualGL for GPU-accelerated OpenGL rendering
ARG VIRTUALGL_VERSION=3.1.1
RUN wget -q "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb" -O /tmp/virtualgl.deb \
    && dpkg -i /tmp/virtualgl.deb || apt-get install -f -y \
    && rm /tmp/virtualgl.deb

# Install Selkies-GStreamer for WebRTC streaming with NVENC (3 components from GitHub releases)
ARG SELKIES_VERSION=1.6.2
# 1. Custom GStreamer build with Selkies patches
RUN mkdir -p /opt/gstreamer \
    && wget -q "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/gstreamer-selkies_gpl_v${SELKIES_VERSION}_ubuntu22.04_amd64.tar.gz" -O /tmp/gstreamer-selkies.tar.gz \
    && tar -xzf /tmp/gstreamer-selkies.tar.gz -C /opt/gstreamer \
    && rm /tmp/gstreamer-selkies.tar.gz
# 2. Python signaling server (wheel from GitHub, not PyPI)
RUN wget -q "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" -O /tmp/selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl \
    && pip3 install --no-cache-dir --force-reinstall /tmp/selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl \
    && rm /tmp/selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl
# 3. Web interface
RUN mkdir -p /opt/gst-web \
    && wget -q "https://github.com/selkies-project/selkies-gstreamer/releases/download/v${SELKIES_VERSION}/selkies-gstreamer-web_v${SELKIES_VERSION}.tar.gz" -O /tmp/selkies-web.tar.gz \
    && tar -xzf /tmp/selkies-web.tar.gz -C /opt/gst-web \
    && rm /tmp/selkies-web.tar.gz

ENV GSTREAMER_PATH="/opt/gstreamer" \
    PATH="/opt/gstreamer/bin:${PATH}" \
    LD_LIBRARY_PATH="/opt/gstreamer/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}" \
    GST_PLUGIN_PATH="/opt/gstreamer/lib/x86_64-linux-gnu/gstreamer-1.0:${GST_PLUGIN_PATH}" \
    GST_PLUGIN_SYSTEM_PATH="/opt/gstreamer/lib/x86_64-linux-gnu/gstreamer-1.0:/usr/lib/x86_64-linux-gnu/gstreamer-1.0" \
    GI_TYPELIB_PATH="/opt/gstreamer/lib/x86_64-linux-gnu/girepository-1.0:/usr/lib/x86_64-linux-gnu/girepository-1.0" \
    PYTHONPATH="/opt/gstreamer/lib/python3/dist-packages:${PYTHONPATH}"

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

# Install Steam - accept EULA, add multiverse, install steam:i386
RUN echo 'steam steam/question select I AGREE' | debconf-set-selections \
    && echo 'steam steam/license note ' | debconf-set-selections \
    && apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository multiverse \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y steam-devices steam:i386 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add /usr/games to PATH so 'steam' command works
ENV PATH="/usr/games:/opt/VirtualGL/bin:${PATH}"

# Download BepInEx for Unix (Liftoff is Unity Mono)
ARG BEPINEX_VERSION=5.4.22
RUN mkdir -p /opt/bepinex \
    && wget -q "https://github.com/BepInEx/BepInEx/releases/download/v${BEPINEX_VERSION}/BepInEx_unix_${BEPINEX_VERSION}.0.zip" \
        -O /opt/bepinex/bepinex.zip

# Create non-root user
RUN useradd -m -s /bin/bash -G audio,video gamer

# Copy configuration files
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/setup-display.sh /opt/scripts/setup-display.sh
COPY scripts/install-steam.sh /opt/scripts/install-steam.sh
COPY scripts/install-bepinex.sh /opt/scripts/install-bepinex.sh
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh /opt/scripts/*.sh

EXPOSE 6901

ENTRYPOINT ["/entrypoint.sh"]
