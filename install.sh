cat <<EOF
Link .aliases & .functions & .gitconfig to ~
EOF

ln -s $PWD/.aliases $HOME/.aliases
ln -s $PWD/.functions $HOME/.functions
ln -s $PWD/.gitconfig $HOME/.gitconfig
cp $PWD/.gitconfig.includes $HOME/.gitconfig.includes
