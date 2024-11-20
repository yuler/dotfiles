#!/bin/bash

cat <<EOF
Link .{path,bash_prompt,exports,aliases,functions,extra,gitconfig}, bin to ~
EOF

touch .gitconfig.includes
touch .gitconfig.local
touch .exports.local

for file in .{path,bash_prompt,exports,exports.local,aliases,functions,extra,gitconfig,gitconfig.includes,gitconfig.local,npm-init.js}; do
    [ -r "$file" ] && [ -f "$file" ] && ln -s $PWD/$file $HOME/$file
done

ln -s $PWD/bin $HOME/bin

# VSCode
mv $HOME/Library/Application\ Support/Code/User/keybindings.json $HOME/Library/Application\ Support/Code/User/keybindings.json.bak
ln -s $PWD/.vscode/keybindings.json $HOME/Library/Application\ Support/Code/User/keybindings.json

# .railsrc
ln -s $PWD/.railsrc $HOME/.railsrc
ln -s $PWD/rails_template.rb $HOME/rails_template.rb

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
append "$(curl https://github.com/yulers.keys)" $HOME/.ssh/authorized_keys
