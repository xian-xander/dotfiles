#!/bin/bash

# No ejecutar si la pantalla de bloqueo ya esta activa
if pidof hyprlock >/dev/null; then
    exit 0
fi

monitors=$(hyprctl monitors -j | jq -r '.[].name')
seed=$RANDOM

for m in $monitors; do
    hyprctl eval "hl.window_rule({ name = 'screensaver-${m}', match = { class = 'screensaver-kitty-${m}' }, monitor = '${m}', fullscreen = true })" >/dev/null 2>&1
    kitty --class "screensaver-kitty-${m}" -e ~/.local/bin/omarchy-screensaver $seed &
done
