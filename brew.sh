#!/usr/bin/env bash

# Install Homebrew & apps
if ! command -v brew &>/dev/null; then
   echo "Installing Homebrew..."
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   source "$HOME/.zshrc"
fi

brew update
brew upgrade

apps=(
   bash          # System version too low
   git           # Git CLI
   git-extras    # Git aliases
   gh            # GitHub CLI
   glab          # GitLab CLI
   go            # golang
   httpstat      # http client tools
   wifi-password # Get wifi password CLI
   fnm           # https://github.com/Schniz/fnm
   rbenv         # https://github.com/rbenv/rbenv
   mas           # https://github.com/mas-cli/mas
)

for app in "${apps[@]}"; do
   if brew list "$app" &>/dev/null; then
      echo "$app is already installed. Skipping..."
      continue
   fi
done

# refs: https://formulae.brew.sh/cask/
casks=(
   font-fira-code     # https://github.com/tonsky/FiraCode
   raycast            # https://raycast.com/
   orbstack           # https://orbstack.dev/
   google-chrome      # https://www.google.com/chrome/
   visual-studio-code # https://code.visualstudio.com/
   telegram           # https://macos.telegram.org/
)

# Applications with special names
# raycast => Raycast.app
declare -A cask_map=(
   ["raycast"]="Raycast"
   ["orbstack"]="Orbstack"
   ["google-chrome"]="Google Chrome"
   ["visual-studio-code"]="Visual Studio Code"
   ["telegram"]="Telegram"
)

for cask in "${casks[@]}"; do
   if brew list --cask "$cask" &>/dev/null; then
      echo "$cask is already installed. Skipping..."
      continue
   fi

   app_name="${cask_map[$cask]}"
   if [ -d "/Applications/${app_name}.app" ]; then
      echo "/Applications/$app_name.app is already installed. Skipping..."
      continue
   fi
   brew install --cask "$cask"
done
