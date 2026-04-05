#!/bin/bash
# Wait for Xvfb to be ready
for i in $(seq 1 20); do
    xdpyinfo -display "${DISPLAY:-:1}" >/dev/null 2>&1 && break
    sleep 0.5
done

if ! xdpyinfo -display "${DISPLAY:-:1}" >/dev/null 2>&1; then
    echo "ERROR: X server not available after 10 seconds"
    exit 1
fi

export DISPLAY="${DISPLAY:-:1}"

# Get the output name from xrandr (Xvfb typically uses "screen")
OUTPUT=$(xrandr 2>/dev/null | grep ' connected' | head -1 | awk '{print $1}')

if [ -z "$OUTPUT" ]; then
    echo "WARN: No connected output found via xrandr, trying default 'screen'"
    OUTPUT="screen"
fi

echo "Detected output: $OUTPUT"

# Add 1920x1080 @ 60Hz modeline (from: cvt 1920 1080 60)
xrandr --newmode "1920x1080_60" 173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync 2>/dev/null || true
xrandr --addmode "$OUTPUT" "1920x1080_60" 2>/dev/null || true

# Add 1920x1080 @ 30Hz modeline (from: cvt 1920 1080 30)
xrandr --newmode "1920x1080_30" 79.75 1920 1976 2168 2416 1080 1083 1088 1102 -hsync +vsync 2>/dev/null || true
xrandr --addmode "$OUTPUT" "1920x1080_30" 2>/dev/null || true

# Apply 60Hz mode
xrandr --output "$OUTPUT" --mode "1920x1080_60" 2>/dev/null || true

echo "Display setup complete. Available modes:"
xrandr 2>/dev/null || true
