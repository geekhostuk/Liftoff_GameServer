#!/bin/bash
# Hide the "steamwebhelper is not responding" dialog by minimizing it.
# We minimize rather than close — closing prevents Steam from proceeding.
# steamwebhelper is slow to start in containers but works eventually.
export DISPLAY="${DISPLAY:-:1}"

while true; do
    for WID in $(xdotool search --name "not responding" 2>/dev/null); do
        echo "$(date): Minimizing steamwebhelper dialog (window $WID)"
        xdotool windowminimize "$WID" 2>/dev/null || true
    done
    sleep 3
done
