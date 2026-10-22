#!/usr/bin/env bash
set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

log_section "Hyprland & Desktop Configuration"

# Hyprland lua configurations
link_file "$DOTFILES_DIR/.config/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"
link_file "$DOTFILES_DIR/.config/hypr/bindings.lua" "$HOME/.config/hypr/bindings.lua"
link_file "$DOTFILES_DIR/.config/hypr/looknfeel.lua" "$HOME/.config/hypr/looknfeel.lua"
link_file "$DOTFILES_DIR/.config/hypr/autostart.lua" "$HOME/.config/hypr/autostart.lua"
link_file "$DOTFILES_DIR/.config/hypr/monitors.lua" "$HOME/.config/hypr/monitors.lua"
link_file "$DOTFILES_DIR/.config/hypr/input.lua" "$HOME/.config/hypr/input.lua"
link_file "$DOTFILES_DIR/.config/hypr/typo.lua" "$HOME/.config/hypr/typo.lua"

# Scratchpad / Quake Console configuration
link_file "$DOTFILES_DIR/.config/default/hypr/qconsole.lua" "$HOME/.config/default/hypr/qconsole.lua"

# Herdr configuration
link_file "$DOTFILES_DIR/.config/herdr/config.toml" "$HOME/.config/herdr/config.toml"

# Clean up legacy workspace layout override files so default layout takes effect
rm -f "$HOME/.local/state/omarchy/workspace-layouts"/{1,2,3,4}.lua 2>/dev/null || true

log_success "Hyprland & Desktop configuration completed."
