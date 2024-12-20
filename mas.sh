#!/usr/bin/env bash

# Use [mas](https://github.com/mas-cli/mas) to install apps from the Mac App Store

declare -A app_map=(
  ["RunCat"]="1429033973"
)

for app_name in "${!app_map[@]}"; do
  app_id="${app_map[$app_name]}"
  if mas list | grep -q "$app_name"; then
    echo "$app_name is already installed. Skipping..."
    continue
  fi
  mas install "$app_id"
done
