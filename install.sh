cat <<EOF
Copy .aliases & .functions to ~
EOF

ln -s $PWD/.aliases $HOME/.aliases
ln -s $PWD/.functions $HOME/.functions
