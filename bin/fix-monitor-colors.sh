#!/bin/bash
# fix-monitor-colors.sh - Toggle monitor resolution to fix color issues
# Changes resolution temporarily then switches back to refresh the display connection
#
# NOTE: This system uses Hyprland's Lua config provider (configProvider: lua),
# so editing monitors.conf has no effect. We must go through `hyprctl eval`.

MONITOR="HDMI-A-1"
BACKUP_MODE="preferred"
TEMPORARY_MODE="1280x1024@60"

# Set temporary resolution
hyprctl eval "hl.monitor({ output = \"$MONITOR\", mode = \"$TEMPORARY_MODE\", position = \"auto\", scale = 1 })"
sleep 2

# Restore original resolution
hyprctl eval "hl.monitor({ output = \"$MONITOR\", mode = \"$BACKUP_MODE\", position = \"auto\", scale = 1 })"

echo "Monitor color fix applied."
