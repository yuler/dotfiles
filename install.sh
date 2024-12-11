#!/usr/bin/env bash

cat <<EOF
Link .{path,bash_prompt,exports,aliases,functions,extra,gitconfig}, bin to ~
EOF

cp .gitconfig.includes.example .gitconfig.includes
cp .gitconfig.local.example .gitconfig.local
touch .exports.local

dotfiles=(
    # .path
    # .bash_prompt
    .exports
    .exports.local
    .aliases
    .functions
    # .extra
    .gitconfig
    .gitconfig.includes
    .gitconfig.local
    bin
    # rails
    .railsrc
    rails_template.rb
)

echo "Link dotfiles to $HOME"

for dotfile in "${dotfiles[@]}"; do
    if [ -r "$dotfile" ] && [ -f "$dotfile" ]; then
        echo "Linking $PWD/$dotfile to $HOME/$dotfile"

        if [ -e "$HOME/$dotfile" ]; then
            echo "$HOME/$dotfile already exists. Backing up to $HOME/$dotfile.bak"
            mv "$HOME/$dotfile" "$HOME/$dotfile.bak"
        fi

        ln -s "$PWD/$dotfile" "$HOME/$dotfile"
    fi
done

# VSCode
# mv $HOME/Library/Application\ Support/Code/User/keybindings.json $HOME/Library/Application\ Support/Code/User/keybindings.json.bak
# ln -s $PWD/.vscode/keybindings.json $HOME/Library/Application\ Support/Code/User/keybindings.json
