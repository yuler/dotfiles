#!/usr/bin/env bash
# Login workspace startup sequence:
# 1. Switch to workspace 10 (key 0) -> open magpie
# 2. Go to workspace 5 -> console setup (clash-verge, btop, desktop-dev, cli:dev)
# 3. Workspace 4 -> skipped
# 4. Workspace 3 -> WeChat & default browser
# 5. Workspace 2 -> default browser (new window)
# 6. Workspace 1 -> Cursor & Grok bot (if grok-bot fails, skip it)
# 7. Scratchpad -> herdr (preheat & hide)

export PATH="$HOME/.local/bin:$HOME/Projects/dotfiles/bin:$PATH"

# Give the compositor a moment to settle.
sleep 2

# Remove legacy workspace layout overrides so global dwindle applies cleanly.
rm -f "$HOME/.local/state/omarchy/workspace-layouts"/{1,2,3,4}.lua 2>/dev/null || true

# ---- Step 1: Workspace 10 (key 0) - magpie ----
hyprctl dispatch 'hl.dsp.focus({ workspace = "10" })'
sleep 2
setsid uwsm-app -- magpie &
sleep 2

# ---- Step 2: Workspace 5 - console ----
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

# ---- Step 3: Workspace 4 - skipped ----

# ---- Step 4: Workspace 3 - WeChat & browser ----
hyprctl dispatch 'hl.dsp.focus({ workspace = "3" })'
sleep 2
setsid uwsm-app -- "$HOME/Applications/WeChat" &
sleep 2
setsid omarchy launch browser &
sleep 2

# ---- Step 5: Workspace 2 - default browser ----
hyprctl dispatch 'hl.dsp.focus({ workspace = "2" })'
sleep 2
setsid omarchy launch browser --new-window &
sleep 2

# ---- Step 6: Workspace 1 - Cursor & Grok bot ----
hyprctl dispatch 'hl.dsp.focus({ workspace = "1" })'
sleep 2
setsid uwsm-app -- cursor &
sleep 2
if command -v grok-bot >/dev/null 2>&1; then
  setsid uwsm-app -- grok-bot &
fi
sleep 2

# ---- Scratchpad: herdr (dwindle layout) ----
# Opening the scratchpad auto-seeds herdr via qconsole.lua.
hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")'
sleep 2
hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")'
