#!/bin/bash

MIN=$1
MAX=$2

BATTERY_PATH=$(find /sys/class/power_supply/BAT* -maxdepth 0 -print -quit 2>/dev/null)

if [ -n "$BATTERY_PATH" ]; then
    if [ -f "$BATTERY_PATH/charge_control_start_threshold" ]; then
        echo "$MIN" > "$BATTERY_PATH/charge_control_start_threshold"
    fi
    if [ -f "$BATTERY_PATH/charge_control_end_threshold" ]; then
        echo "$MAX" > "$BATTERY_PATH/charge_control_end_threshold"
    fi
fi
