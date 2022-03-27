cat <<EOF
Link .{path,bash_prompt,exports,aliases,functions,extra,gitconfig} to ~
EOF

touch .gitconfig.includes
touch .gitconfig.local
touch .exports.local

for file in .{path,bash_prompt,exports,exports.local,aliases,functions,extra,gitconfig,gitconfig.includes,gitconfig.local}; do
    [ -r "$file" ] && [ -f "$file" ] && ln -s $PWD/$file $HOME/$file
done

# VSCode
mv $HOME/Library/Application\ Support/Code/User/keybindings.json $HOME/Library/Application\ Support/Code/User/keybindings.json.bak
ln -s $PWD/.vscode/keybindings.json $HOME/Library/Application\ Support/Code/User/keybindings.json
