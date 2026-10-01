#!/bin/bash
pkill -x tte 2>/dev/null
hyprctl eval 'hl.config({ cursor = { invisible = false } })' >/dev/null 2>&1
pkill -f screensaver-kitty 2>/dev/null
pkill -f omarchy-screensaver 2>/dev/null
