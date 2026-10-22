#!/usr/bin/env bash
set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

log_section "Shell Configuration"

# Ensure local export file exists
[ -f "$DOTFILES_DIR/.exports.local" ] || touch "$DOTFILES_DIR/.exports.local"

shell_files=(
  .exports
  .exports.local
  .aliases
  .functions
)

for file in "${shell_files[@]}"; do
  link_file "$DOTFILES_DIR/$file" "$HOME/$file"
done

log_success "Shell configuration completed."
