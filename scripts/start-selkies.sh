#!/bin/bash
# Start Selkies-GStreamer with proper GStreamer environment
export GSTREAMER_PATH="/opt/gstreamer/gstreamer"
export PATH="${GSTREAMER_PATH}/bin:${PATH}"
export LD_LIBRARY_PATH="${GSTREAMER_PATH}/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}"
export GST_PLUGIN_PATH="${GSTREAMER_PATH}/lib/x86_64-linux-gnu/gstreamer-1.0:${GST_PLUGIN_PATH}"
export GST_PLUGIN_SYSTEM_PATH="${GSTREAMER_PATH}/lib/x86_64-linux-gnu/gstreamer-1.0:/usr/lib/x86_64-linux-gnu/gstreamer-1.0"
export GI_TYPELIB_PATH="${GSTREAMER_PATH}/lib/x86_64-linux-gnu/girepository-1.0:/usr/lib/x86_64-linux-gnu/girepository-1.0"
export PYTHONPATH="${GSTREAMER_PATH}/lib/python3/dist-packages:${PYTHONPATH}"

# Check if GStreamer is working
if ! python3 -c "import gi; gi.require_version('Gst', '1.0'); gi.require_version('GstWebRTC', '1.0')" 2>/dev/null; then
    echo "ERROR: GStreamer Python bindings not working. Checking paths..."
    echo "GSTREAMER_PATH=${GSTREAMER_PATH}"
    echo "GI_TYPELIB_PATH=${GI_TYPELIB_PATH}"
    ls -la "${GSTREAMER_PATH}/lib/x86_64-linux-gnu/girepository-1.0/" 2>/dev/null || echo "GI typelib dir missing"
    echo "Trying without custom GStreamer..."
    unset GSTREAMER_PATH GST_PLUGIN_PATH GST_PLUGIN_SYSTEM_PATH GI_TYPELIB_PATH
    export LD_LIBRARY_PATH=""
    export PYTHONPATH=""
fi

# Detect encoder: prefer NVENC, fall back to x264
ENCODER="nvh264enc"
if ! gst-inspect-1.0 nvh264enc >/dev/null 2>&1; then
    echo "WARN: nvh264enc not available, falling back to x264enc"
    ENCODER="x264enc"
fi

exec selkies-gstreamer \
    --addr=0.0.0.0 \
    --port=6901 \
    --enable_https=false \
    --enable_basic_auth=false \
    --encoder="${ENCODER}" \
    --framerate=60 \
    --video_bitrate=6000 \
    --enable_resize=false \
    --web_root=/opt/gst-web/gst-web
