#!/bin/bash
# Wait for Caelestia shell to be ready
while ! pgrep -f "caelestia.*shell" > /dev/null; do
    sleep 0.1
done

# Wait for Caelestia to finish all initialization
sleep 10
hyprctl dispatch global caelestia:lock
