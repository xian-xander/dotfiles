#!/bin/bash

ALSA_SET="$HOME/.local/bin/alsa_set"

sync_led() {
    if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
        "$ALSA_SET" hw:1 0 > /dev/null
    else
        "$ALSA_SET" hw:1 1 > /dev/null
    fi
}

# Initial sync
sync_led

# Listen for changes
pactl subscribe | grep --line-buffered "Event 'change' on source" | while read -r line; do
    sync_led
done
