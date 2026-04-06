#!/bin/bash
# Auto-dismiss the "steamwebhelper is not responding" dialog.
# Runs as a background supervisor job, polling every 5 seconds.
export DISPLAY="${DISPLAY:-:1}"

while true; do
    # Find and close the "not responding" dialog by clicking any button
    WID=$(xdotool search --name "not responding" 2>/dev/null | head -1)
    if [ -n "$WID" ]; then
        echo "$(date): Dismissing steamwebhelper dialog (window $WID)"
        # Press Enter to dismiss (clicks the default button)
        xdotool key --window "$WID" Return 2>/dev/null || true
    fi
    sleep 5
done
