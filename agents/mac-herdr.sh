#!/usr/bin/env bash
# mac-herdr.sh -- Align macOS herdr keybindings with Omarchy herdr.
#
# Usage:
#   mac-herdr.sh            Write ~/.config/herdr/config.toml and reload herdr
#   mac-herdr.sh --check    Only validate the current config, change nothing
#   mac-herdr.sh --restore  Restore the most recent backup made by this script
#
# What it does:
#   - Backs up the existing config (if any) to config.toml.bak-<timestamp>.
#   - Writes a config whose [keys] section mirrors Omarchy's herdr config
#     (https://github.com/basecamp/omarchy/blob/quattro/config/herdr/config.toml),
#     which itself mirrors Omarchy's tmux config (config/tmux/tmux.conf):
#     tmux session -> herdr workspace, tmux window -> herdr tab,
#     tmux pane -> herdr pane.
#   - Key changes applied here (prefix = press ctrl+space, then the key):
#
# | Feature                  | This script                       | herdr default    | Change                                    |
# |--------------------------|-----------------------------------|------------------|-------------------------------------------|
# | Prefix key               | `ctrl+space`                      | `ctrl+b`         | changed to match tmux C-Space             |
# | Reload config            | `prefix+q`                        | `prefix+shift+r` | changed, same as tmux q                   |
# | Detach (keep running)    | `prefix+d`                        | `prefix+q`       | changed, q given to reload                |
# | Split horizontal (below) | `prefix+h`, `alt+enter`           | `prefix+minus`   | changed, adds h                           |
# | Split vertical (beside)  | `prefix+v`, `alt+shift+enter`     | `prefix+v`       | extended with prefix-free                 |
# | Close pane               | `prefix+x`, `alt+esc`             | `prefix+x`       | extended with prefix-free                 |
# | Last pane                | `prefix+;`                        | (unset)          | new                                       |
# | Focus left/down/up/right | `ctrl+alt+arrows`                 | `prefix+h/j/k/l` | changed to prefix-free; h freed for split |
# | Resize mode              | `prefix+ctrl+arrows`              | `prefix+r`       | changed to arrows                         |
# | Resize directly          | `ctrl+alt+shift+arrows`           | (unset)          | new, prefix-free                          |
# | Rename pane              | `prefix+shift+o`                  | `prefix+shift+p` | changed, shift+p used by workspace        |
# | Rename tab               | `prefix+r`                        | `prefix+shift+t` | changed, same as tmux r                   |
# | Close tab                | `prefix+k`                        | `prefix+shift+x` | changed, same as tmux k                   |
# | Go to tab 1-9            | `prefix+1..9`, `alt+1..9`         | `prefix+1..9`    | extended with prefix-free                 |
# | Previous/next tab        | `prefix+p/n`, `alt+left/right`    | `prefix+p/n`     | extended with prefix-free                 |
# | Move tab left/right      | `alt+shift+left/right`            | (unset)          | new, same as tmux swap-window             |
# | New workspace            | `prefix+shift+c`                  | `prefix+shift+n` | changed, same as tmux C                   |
# | Rename workspace         | `prefix+shift+r`                  | `prefix+shift+w` | changed, same as tmux R                   |
# | Close workspace          | `prefix+shift+k`                  | `prefix+shift+d` | changed, same as tmux K                   |
# | Previous/next workspace  | `prefix+shift+p/n`, `alt+up/down` | (unset)          | new                                       |
#   - Unchanged bindings (prefix+?, prefix+[, prefix+z, prefix+c, prefix+s,
#     prefix+g, prefix+w, prefix+b, ...) keep the herdr built-in defaults.
#   - Preserves onboarding = false so the first-run wizard stays dismissed.
#   - Validates with `herdr config check` and reloads the running server
#     with `herdr server reload-config` (best effort: skipped when herdr
#     is not installed or no server is running).
#
# Notes:
#   - Only the keys listed under [keys] override herdr defaults; anything
#     not listed keeps the built-in default (see `herdr --default-config`).
#   - To also accept the old ctrl+b prefix (like Omarchy tmux prefix2),
#     change the prefix line to: prefix = ["ctrl+space", "ctrl+b"]

set -euo pipefail

CONFIG="${HOME}/.config/herdr/config.toml"
CONFIG_DIR="$(dirname "$CONFIG")"

usage() {
  sed -n '2,10p' "$0"
}

backup_config() {
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  cp "$CONFIG" "${CONFIG}.bak-${stamp}"
  echo "backed up $CONFIG to ${CONFIG}.bak-${stamp}"
}

restore_config() {
  local latest
  latest="$(ls -t "${CONFIG}".bak-* 2>/dev/null | head -n1 || true)"
  if [[ -z "$latest" ]]; then
    echo "no backup found (${CONFIG}.bak-*)" >&2
    exit 1
  fi
  cp "$latest" "$CONFIG"
  echo "restored $CONFIG from $latest"
}

write_config() {
  mkdir -p "$CONFIG_DIR"
  if [[ -f "$CONFIG" ]]; then
    backup_config
  fi

  # Full config below mirrors Omarchy quattro config/herdr/config.toml.
  cat >"$CONFIG" <<'EOF'
# herdr configuration - macOS port of Omarchy's herdr config.
# Source: https://github.com/basecamp/omarchy/blob/quattro/config/herdr/config.toml
# Mapping: tmux session -> herdr workspace, tmux window -> herdr tab,
# tmux pane -> herdr pane.
# Regenerate with: ~/Projects/dotfiles/agents/mac-herdr.sh

# First-run wizard already dismissed; keep it off.
onboarding = false

[theme]
# Omarchy tmux ran on the terminal's own palette, so use the terminal theme.
name = "terminal"

[theme.custom]
# The active tab is drawn as panel_bg text on an accent background, so
# panel_bg must be dark for it to read (matches tmux status-left blue).
panel_bg = "black"

[terminal]
# Match tmux -c "#{pane_current_path}": new panes inherit the current path.
new_cwd = "follow"

[keys]
# Prefix key to enter prefix mode (herdr default is ctrl+b).
# Omarchy tmux uses C-Space (with C-b as prefix2); herdr here uses ctrl+space.
prefix = "ctrl+space"

# Reload config and show all active keybindings.
reload_config = "prefix+q"
help = "prefix+?"
# Detach client, leaving the server and all panes running.
detach = "prefix+d"

# Enter copy (scrollback search) mode.
copy_mode = "prefix+["

# Split horizontal: new pane BELOW the current one (tmux split-window -v on h).
# This is the requested prefix+h binding; alt+enter works without prefix.
split_horizontal = ["prefix+h", "alt+enter"]
# Split vertical: new pane BESIDE the current one (tmux split-window -h on v).
split_vertical = ["prefix+v", "alt+shift+enter"]
# Kill the focused pane (alt+esc works without prefix).
close_pane = ["prefix+x", "alt+esc"]
# Toggle pane zoom (fullscreen).
zoom = "prefix+z"
# Jump back to the previously focused pane.
last_pane = "prefix+;"

# Move focus between panes with ctrl+alt+arrows (no prefix needed).
focus_pane_left = "ctrl+alt+left"
focus_pane_down = "ctrl+alt+down"
focus_pane_up = "ctrl+alt+up"
focus_pane_right = "ctrl+alt+right"

# Enter resize mode, then use arrows (mirrors tmux resize-pane bindings).
resize_mode = ["prefix+ctrl+left", "prefix+ctrl+down", "prefix+ctrl+up", "prefix+ctrl+right"]

# Resize panes directly without entering resize mode (like tmux C-M-S-arrows).
resize_pane_left = "ctrl+alt+shift+left"
resize_pane_down = "ctrl+alt+shift+down"
resize_pane_up = "ctrl+alt+shift+up"
resize_pane_right = "ctrl+alt+shift+right"

# Rename the focused pane (herdr default prefix+shift+p is taken below).
rename_pane = "prefix+shift+o"

# Tabs map to tmux windows: create, rename, kill, jump, cycle, reorder.
new_tab = "prefix+c"
rename_tab = "prefix+r"
close_tab = "prefix+k"
switch_tab = ["prefix+1..9", "alt+1..9"]
previous_tab = ["prefix+p", "alt+left"]
next_tab = ["prefix+n", "alt+right"]

# Move the current tab left/right (like tmux swap-window on M-S-Left/Right).
move_tab_previous = "alt+shift+left"
move_tab_next = "alt+shift+right"

# Workspaces map to tmux sessions: create, rename, kill, cycle.
new_workspace = "prefix+shift+c"
rename_workspace = "prefix+shift+r"
close_workspace = "prefix+shift+k"
previous_workspace = ["prefix+shift+p", "alt+up"]
next_workspace = ["prefix+shift+n", "alt+down"]

[ui]
# Blue accent matches the Omarchy tmux status bar.
accent = "blue"

# tmux drew single-line dividers between panes with no outer frame.
pane_gaps = false
pane_outer_borders = false

# tmux had no scrollbar column beside its panes.
pane_scrollbars = false

# tmux kill-window / kill-session never asked for confirmation.
confirm_close = false

# tmux automatic-rename named windows without prompting.
prompt_new_tab_name = false

# Match tmux set -g mouse on.
mouse_capture = true

# Status-right showed the zoom flag followed by the hostname.
tab_bar_right = [{ type = "zoom" }, { type = "hostname" }]

# Match tmux set-titles-string '#h:#W': hostname plus workspace name.
# Shown by the window manager in title/tab/group bars; resolves on the
# server so remote sessions name the remote host.
window_title = "{hostname}: {workspace}"
EOF

  echo "wrote $CONFIG"
}

check_config() {
  if ! command -v herdr >/dev/null 2>&1; then
    echo "herdr not found on PATH, skipping validation" >&2
    return 0
  fi
  herdr config check
}

reload_server() {
  if ! command -v herdr >/dev/null 2>&1; then
    return 0
  fi
  # Best effort: fails when no server is running; never break the script.
  herdr server reload-config >/dev/null 2>&1 || true
}

case "${1:-}" in
  -h | --help) usage; exit 0 ;;
  --check) check_config; exit 0 ;;
  --restore)
    restore_config
    check_config
    reload_server
    exit 0
    ;;
  "") write_config; check_config; reload_server; exit 0 ;;
  *)
    echo "unknown argument: $1 (see --help)" >&2
    exit 1
    ;;
esac
