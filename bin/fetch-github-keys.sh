#!/usr/bin/env bash

function append() {
  local text="$1" file="$2"

  [[ -f $file ]] && touch $file

  if ! grep -q "$text" "$file"; then
    echo "$text" >>"$file"
  fi
}

# Fetching public keys
echo "Fetching public keys..."
mkdir -p $HOME/.ssh
append "$(curl https://github.com/yuler.keys)" $HOME/.ssh/authorized_keys
