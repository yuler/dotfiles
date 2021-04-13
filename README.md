# This Repo is dotfiles

## Add to `~/.bashrc` or `~/.zshrc`

```bash
# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
  [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
```

## VSCode Snippets

vscode snippets location is `~/Library/Application\ Support/Code/User/snippets`

## Refs

- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
- [tj/vscode-snippets](https://github.com/tj/vscode-snippets)
