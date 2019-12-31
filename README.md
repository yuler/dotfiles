# This repository is dotfiles

## Load the shell dotfiles, and then some:
```bash
for file in ~/.{exports,aliases,functions}; do
  [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
```