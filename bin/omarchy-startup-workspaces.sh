#!/usr/bin/env bash
# Login layout: workspace 5 = console, 2 = browser (scroll), 1 = herdr
# (dwindle), 3 = chat — wechat + cursor agents (dwindle), scratchpad = tmux.
# Triggered from ~/.config/hypr/autostart.lua.

# Give the compositor a moment to settle.
sleep 2

# Set + persist a per-workspace layout (mirrors
# omarchy-hyprland-workspace-layout-toggle).
set_workspace_layout() {
  local ws="$1" layout="$2"
  local layouts_dir="$HOME/.local/state/omarchy/workspace-layouts"
  mkdir -p "$layouts_dir"
  printf 'hl.workspace_rule({ workspace = "%s", layout = "%s" })\n' "$ws" "$layout" >"$layouts_dir/$ws.lua"
  hyprctl eval "hl.workspace_rule({ workspace = \"$ws\", layout = \"$layout\" })" >/dev/null 2>&1 ||
    hyprctl keyword workspace "$ws, layout:$layout" >/dev/null 2>&1
}

# ---- Workspace 5: console ----
hyprctl dispatch 'hl.dsp.focus({ workspace = "5" })'
sleep 2
setsid uwsm-app -- clash-verge &
sleep 2
setsid uwsm-app -- xdg-terminal-exec -e btop &
sleep 2
setsid uwsm-app -- xdg-terminal-exec --dir="$HOME/Projects/typo" -e mise run desktop-dev &
sleep 2
setsid uwsm-app -- xdg-terminal-exec --dir="$HOME/Projects/airvoice" -e mise run cli:dev &
sleep 2

# ---- Workspace 2: browser (scroll) ----
sleep 2
hyprctl dispatch 'hl.dsp.focus({ workspace = "2" })'
set_workspace_layout "2" "scrolling"
sleep 2
setsid omarchy launch browser &
sleep 2

# ---- Workspace 1: herdr (dwindle) ----
sleep 2
hyprctl dispatch 'hl.dsp.focus({ workspace = "1" })'
set_workspace_layout "1" "dwindle"
sleep 2
setsid omarchy launch terminal herdr &
sleep 2

# ---- Workspace 3: chat — wechat + cursor agents (dwindle) ----
sleep 2
hyprctl dispatch 'hl.dsp.focus({ workspace = "3" })'
set_workspace_layout "3" "dwindle"
sleep 2
setsid uwsm-app -- "$HOME/Applications/WeChat" &
sleep 2
setsid uwsm-app -- cursor --chat &
sleep 2

# ---- Scratchpad: tmux ----
# Opening the scratchpad auto-seeds tmux (qconsole), so no manual launch needed.
hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")'
sleep 2
hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")'
