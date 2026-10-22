#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$DOTFILES_DIR/install"

show_help() {
  cat <<EOF
Usage: ./install.sh [options] [modules...]

Modular dotfiles installer powered by Charm gum.

Options:
  -a, --all        Install all standard modules without prompting
  -h, --help       Show this help message

Available modules:
  shell            Shell configuration (.exports, .aliases, .functions)
  git              Git configuration (.gitconfig, .gitconfig.local)
  agents           AI Agent profile & rules (USER.md across AI harnesses)
  editors          Editor settings (VS Code, Cursor)
  rails            Ruby on Rails templates (.railsrc, rails_template.rb)
  packages         Package manager scripts (brew, npms, ruby, mas)

Examples:
  ./install.sh                Interactive menu (select with gum)
  ./install.sh --all          Install all modules
  ./install.sh shell git      Install only shell and git
EOF
}

# Define available modules (Label -> Script)
declare -A MODULE_SCRIPTS=(
  ["Shell"]="shell.sh"
  ["Git"]="git.sh"
  ["Agents"]="agents.sh"
  ["Editors"]="editors.sh"
  ["Rails"]="rails.sh"
  ["Packages"]="packages.sh"
)

# Friendly display names for gum menu
OPT_SHELL="🐚 Shell    - Aliases, exports, functions"
OPT_GIT="🐙 Git      - Git config & local includes"
OPT_AGENTS="🤖 Agents   - USER.md profile & AI harnesses"
OPT_EDITORS="💻 Editors  - VS Code & Cursor settings/keybindings"
OPT_RAILS="💎 Rails    - .railsrc & rails_template.rb"
OPT_PACKAGES="📦 Packages - Package managers (brew, npm, etc.)"

run_module() {
  local mod="$1"
  local script="${MODULE_SCRIPTS[$mod]}"
  if [ -n "$script" ] && [ -f "$INSTALL_DIR/$script" ]; then
    bash "$INSTALL_DIR/$script"
  else
    echo "Unknown module: $mod"
    return 1
  fi
}

# 1. Parse command-line arguments
TARGET_MODULES=()

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -a|--all)
      TARGET_MODULES=("Shell" "Git" "Agents" "Editors" "Rails")
      shift
      ;;
    shell|Shell)
      TARGET_MODULES+=("Shell")
      shift
      ;;
    git|Git)
      TARGET_MODULES+=("Git")
      shift
      ;;
    agents|Agents)
      TARGET_MODULES+=("Agents")
      shift
      ;;
    editors|Editors|vscode|VSCode)
      TARGET_MODULES+=("Editors")
      shift
      ;;
    rails|Rails)
      TARGET_MODULES+=("Rails")
      shift
      ;;
    packages|Packages)
      TARGET_MODULES+=("Packages")
      shift
      ;;
    *)
      echo "Unknown option or module: $1"
      show_help
      exit 1
      ;;
  esac
done

# 2. Interactive selection if no CLI arguments specified
if [ ${#TARGET_MODULES[@]} -eq 0 ]; then
  if command -v gum &>/dev/null && [ -t 0 ]; then
    # Render header banner
    gum style \
      --border double \
      --margin "1 0" \
      --padding "0 2" \
      --border-foreground 212 \
      --foreground 212 \
      --bold \
      "✨ Dotfiles Modular Installer"

    # Present multi-select menu with core modules pre-selected
    CHOICES=$(gum choose --no-limit \
      --selected="$OPT_SHELL,$OPT_GIT,$OPT_AGENTS" \
      --header="Select modules to install (Space to toggle, Enter to confirm):" \
      "$OPT_SHELL" \
      "$OPT_GIT" \
      "$OPT_AGENTS" \
      "$OPT_EDITORS" \
      "$OPT_RAILS" \
      "$OPT_PACKAGES") || true

    if [ -z "$CHOICES" ]; then
      gum style --foreground 214 "No modules selected. Installation cancelled."
      exit 0
    fi

    while IFS= read -r line; do
      case "$line" in
        *"Shell"*)    TARGET_MODULES+=("Shell") ;;
        *"Git"*)      TARGET_MODULES+=("Git") ;;
        *"Agents"*)   TARGET_MODULES+=("Agents") ;;
        *"Editors"*)  TARGET_MODULES+=("Editors") ;;
        *"Rails"*)    TARGET_MODULES+=("Rails") ;;
        *"Packages"*) TARGET_MODULES+=("Packages") ;;
      esac
    done <<< "$CHOICES"
  else
    # Fallback for non-interactive or environments without gum
    echo "=== Dotfiles Installer (Default Core Modules) ==="
    TARGET_MODULES=("Shell" "Git" "Agents")
  fi
fi

# 3. Execute selected modules
for mod in "${TARGET_MODULES[@]}"; do
  run_module "$mod"
done

# 4. Final summary
echo ""
if command -v gum &>/dev/null; then
  gum style \
    --foreground 82 \
    --bold \
    "🎉 All selected modules installed successfully!"
else
  printf "\033[1;32m🎉 All selected modules installed successfully!\033[0m\n"
fi
