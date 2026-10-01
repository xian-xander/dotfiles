#!/bin/bash
pkill -f "socat.*socket2.sock.*HDMI"
socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | grep --line-buffered "monitoradded>>HDMI-A-1" | while read -r line; do
    sleep 1
    # Mover escritorios 1-5 al HDMI
    for i in {1..5}; do hyprctl dispatch moveworkspacetomonitor $i HDMI-A-1; done
    # Mover escritorios 6-10 al portatil
    for i in {6..10}; do hyprctl dispatch moveworkspacetomonitor $i eDP-1; done
done
