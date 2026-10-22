#!/usr/bin/env bash
set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

log_section "Git Configuration"

# Initialize .gitconfig.includes and .gitconfig.local from examples if missing
if [ ! -f "$DOTFILES_DIR/.gitconfig.includes" ] && [ -f "$DOTFILES_DIR/.gitconfig.includes.example" ]; then
  cp "$DOTFILES_DIR/.gitconfig.includes.example" "$DOTFILES_DIR/.gitconfig.includes"
  log_info "Initialized .gitconfig.includes from template."
fi

if [ ! -f "$DOTFILES_DIR/.gitconfig.local" ] && [ -f "$DOTFILES_DIR/.gitconfig.local.example" ]; then
  cp "$DOTFILES_DIR/.gitconfig.local.example" "$DOTFILES_DIR/.gitconfig.local"
  log_info "Initialized .gitconfig.local from template."
fi

git_files=(
  .gitconfig
  .gitconfig.includes
  .gitconfig.local
)

for file in "${git_files[@]}"; do
  link_file "$DOTFILES_DIR/$file" "$HOME/$file"
done

log_success "Git configuration completed."
