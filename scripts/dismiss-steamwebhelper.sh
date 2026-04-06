#!/bin/bash
# Auto-dismiss the "steamwebhelper is not responding" dialog.
# Runs as a background supervisor job, polling every 3 seconds.
# Uses windowclose (WM_DELETE_WINDOW) instead of key events.
export DISPLAY="${DISPLAY:-:1}"

while true; do
    for WID in $(xdotool search --name "not responding" 2>/dev/null); do
        echo "$(date): Force-closing steamwebhelper dialog (window $WID)"
        xdotool windowclose "$WID" 2>/dev/null || true
    done
    sleep 3
done
