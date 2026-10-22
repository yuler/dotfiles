#!/usr/bin/env bash
set -e

# Resolve dotfiles root directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Styling and logging helpers (using gum if available)
if command -v gum &>/dev/null; then
  log_info() { gum style --foreground 39 "ℹ $1"; }
  log_success() { gum style --foreground 82 "✔ $1"; }
  log_warn() { gum style --foreground 214 "▲ $1"; }
  log_error() { gum style --foreground 196 "✖ $1"; }
  log_section() {
    echo ""
    gum style --foreground 212 --bold "─── $1 ───"
  }
else
  log_info() { printf "\033[0;34m[INFO]\033[0m %s\n" "$1"; }
  log_success() { printf "\033[0;32m[OK]\033[0m %s\n" "$1"; }
  log_warn() { printf "\033[0;33m[WARN]\033[0m %s\n" "$1"; }
  log_error() { printf "\033[0;31m[ERROR]\033[0m %s\n" "$1"; }
  log_section() { printf "\n\033[1;35m=== %s ===\033[0m\n" "$1"; }
fi

# link_file <source_file> <target_link>
link_file() {
  local src="$1"
  local dest="$2"
  local dest_dir
  dest_dir="$(dirname "$dest")"

  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    log_warn "Source file not found, skipping: $src"
    return 1
  fi

  mkdir -p "$dest_dir"

  # Idempotent: already pointing to the exact source
  if [ -L "$dest" ] && [ "$(readlink "$dest" 2>/dev/null)" = "$src" ]; then
    log_info "Already linked: $dest"
    return 0
  fi

  # Backup existing file/link if not matching
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    log_warn "Backing up existing $dest -> $dest.bak"
    mv "$dest" "$dest.bak"
  fi

  ln -s "$src" "$dest"
  log_success "Linked $src -> $dest"
}
