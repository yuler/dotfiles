#!/usr/bin/env bash
set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

log_section "Ruby & Rails Configuration"

rails_files=(
  .railsrc
  rails_template.rb
)

for file in "${rails_files[@]}"; do
  if [ -f "$DOTFILES_DIR/$file" ]; then
    link_file "$DOTFILES_DIR/$file" "$HOME/$file"
  fi
done

log_success "Ruby & Rails configuration completed."
