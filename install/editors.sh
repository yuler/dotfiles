#!/usr/bin/env bash
set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

log_section "Editor Configuration (VS Code / Cursor)"

candidate_dirs=(
  "$HOME/Library/Application Support/Code/User"
  "$HOME/Library/Application Support/Cursor/User"
  "$HOME/.config/Code/User"
  "$HOME/.config/Cursor/User"
)

target_dirs=()
for dir in "${candidate_dirs[@]}"; do
  if [ -d "$dir" ]; then
    target_dirs+=("$dir")
  fi
done

# If no editor directories exist yet, default to platform standard VS Code dir
if [ ${#target_dirs[@]} -eq 0 ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    target_dirs+=("$HOME/Library/Application Support/Code/User")
  else
    target_dirs+=("$HOME/.config/Code/User")
  fi
fi

for target_dir in "${target_dirs[@]}"; do
  log_info "Configuring editor at: $target_dir"
  [ -f "$DOTFILES_DIR/.vscode/settings.json" ] && link_file "$DOTFILES_DIR/.vscode/settings.json" "$target_dir/settings.json"
  [ -f "$DOTFILES_DIR/.vscode/keybindings.json" ] && link_file "$DOTFILES_DIR/.vscode/keybindings.json" "$target_dir/keybindings.json"
done

log_success "Editor configuration completed."
