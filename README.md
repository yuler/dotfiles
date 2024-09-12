# This Repo is dotfiles

## Add to `~/.bashrc` or `~/.zshrc`

```bash
# Add `/bin` to the `$PATH`
export DOTFILES_DIR="The path to this repo"
export PATH="$DOTFILES_DIR/bin:$PATH";

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,exports.local,aliases,functions,extra}; do
  [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
```

## VSCode Snippets

vscode snippets location is `~/Library/Application\ Support/Code/User/snippets`

## Refs

- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
- [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles)
- [necolas/dotfiles](https://github.com/necolas/dotfiles)
- [webpro/awesome-dotfiles](https://github.com/webpro/awesome-dotfiles)
- [tj/vscode-snippets](https://github.com/tj/vscode-snippets)
