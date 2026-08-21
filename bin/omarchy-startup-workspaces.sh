#!/usr/bin/env bash
# Login layout: workspace 5 = console, 2 = browser, 1 = editor, 3 = chat,
# scratchpad = tmux-dev.
# Triggered from ~/.config/hypr/autostart.lua.

# Give the compositor a moment to settle.
sleep 2

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

# ---- Workspace 2: browser ----
sleep 2
hyprctl dispatch 'hl.dsp.focus({ workspace = "2" })'
sleep 2
setsid omarchy launch browser &
sleep 2

# ---- Workspace 1: cursor ----
sleep 2
hyprctl dispatch 'hl.dsp.focus({ workspace = "1" })'
sleep 2
setsid uwsm-app -- cursor &
sleep 2

# ---- Workspace 3: chat ----
sleep 2
hyprctl dispatch 'hl.dsp.focus({ workspace = "3" })'
sleep 2
setsid uwsm-app -- "$HOME/Applications/WeChat" &
sleep 2

# ---- Scratchpad: tmux-dev ----
hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")'
sleep 2
setsid uwsm-app -- xdg-terminal-exec -e tmux-dev &
sleep 2
hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")'
