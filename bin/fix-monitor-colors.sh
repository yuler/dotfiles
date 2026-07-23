#!/bin/bash
# fix-monitor-colors.sh - Toggle monitor resolution to fix color issues
# Changes resolution temporarily then switches back to refresh the display connection

MONITOR_CONF="$HOME/.config/hypr/monitors.conf"
ORIGINAL="monitor=,preferred,auto,1"
TEMPORARY="monitor=HDMI-A-1, 1280x1024@60, auto, 1"

# Backup current config
cp "$MONITOR_CONF" "$MONITOR_CONF.bak"

# Set temporary resolution
sed -i "s/^monitor=,preferred,auto,1$/$TEMPORARY/" "$MONITOR_CONF"
hyprctl reload
sleep 1

# Restore original resolution
sed -i "s/^monitor=HDMI-A-1, 1280x1024@60, auto, 1$/$ORIGINAL/" "$MONITOR_CONF"
hyprctl reload

# Restore full backup if sed didn't work cleanly
cp "$MONITOR_CONF.bak" "$MONITOR_CONF" 2>/dev/null
rm -f "$MONITOR_CONF.bak"

echo "Monitor color fix applied."
