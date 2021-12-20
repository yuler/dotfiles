cat <<EOF
Link .{path,bash_prompt,exports,aliases,functions,extra,gitconfig} to ~
EOF

touch .gitconfig.includes
touch .gitconfig.local
touch .exports.local

for file in .{path,bash_prompt,exports,exports.local,aliases,functions,extra,gitconfig,gitconfig.local}; do
    [ -r "$file" ] && [ -f "$file" ] && ln -s $PWD/$file $HOME/$file
done

cp $PWD/.gitconfig.includes $HOME/.gitconfig.includes

# VSCode
ln -s $PWD/.vscode/keybindings.json $HOME/Library/Application\ Support/Code/User/keybindings.json
