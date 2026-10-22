#!/usr/bin/env bash
set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

log_section "System & Package Managers"

declare -A pkg_scripts=(
  ["Homebrew & CLI tools (brew.sh)"]="brew.sh"
  ["NPM global CLIs (npms.sh)"]="npms.sh"
  ["Ruby gems (ruby.sh)"]="ruby.sh"
  ["Mac App Store apps (mas.sh)"]="mas.sh"
)

available_labels=()
for label in "${!pkg_scripts[@]}"; do
  script="${pkg_scripts[$label]}"
  if [ -f "$DOTFILES_DIR/$script" ]; then
    available_labels+=("$label")
  fi
done

if [ ${#available_labels[@]} -eq 0 ]; then
  log_warn "No package installer scripts found."
  exit 0
fi

selected_labels=()
if [ $# -gt 0 ]; then
  # Direct script name passed as argument
  for arg in "$@"; do
    for label in "${!pkg_scripts[@]}"; do
      script="${pkg_scripts[$label]}"
      if [[ "$script" == *"$arg"* ]]; then
        selected_labels+=("$label")
      fi
    done
  done
elif command -v gum &>/dev/null && [ -t 0 ]; then
  # Interactive gum selection
  IFS=$'\n' read -r -d '' -a selected_labels < <(printf "%s\n" "${available_labels[@]}" | gum choose --no-limit --header="Select package managers to run:" && printf '\0') || true
else
  log_info "No package managers specified. To install packages, run with args (e.g. ./install/packages.sh brew) or run brew.sh / npms.sh directly."
  exit 0
fi

for label in "${selected_labels[@]}"; do
  [ -z "$label" ] && continue
  script="${pkg_scripts[$label]}"
  if [ -n "$script" ] && [ -f "$DOTFILES_DIR/$script" ]; then
    log_info "Running $script..."
    bash "$DOTFILES_DIR/$script"
  fi
done

log_success "Package managers step completed."
