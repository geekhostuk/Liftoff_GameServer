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

# Detect encoder: test if NVENC can actually open a session, fall back to x264
ENCODER="x264enc"
if gst-inspect-1.0 nvh264enc >/dev/null 2>&1; then
    # Plugin exists, but test if CUDA device is accessible
    if python3 -c "
import gi
gi.require_version('Gst', '1.0')
from gi.repository import Gst
Gst.init(None)
enc = Gst.ElementFactory.make('nvh264enc', None)
if enc is None:
    exit(1)
" 2>/dev/null; then
        echo "INFO: NVENC encoder available, using hardware encoding"
        ENCODER="nvh264enc"
    else
        echo "WARN: NVENC plugin found but GPU not accessible for encoding, using x264enc"
    fi
else
    echo "INFO: Using x264enc software encoder"
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
