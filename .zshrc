# brew
eval "$(/opt/homebrew/bin/brew shellenv)"
# fnm

# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH"

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,exports.local,aliases,functions,extra}; do
  [ -r "$file" ] && [ -f "$file" ] && source "$file"
done

# export PNPM_HOME="/Users/yule/Library/pnpm"
# export PATH="$PNPM_HOME:$PATH"
# eval "$(pyenv init -)"

# go
PATH=$PATH:$(go env GOPATH)/bin

# Bun
export BUN_INSTALL="/Users/yule/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# Bun completions
[ -s "/Users/yule/.bun/_bun" ] && source "/Users/yule/.bun/_bun"

# fnm
eval "$(fnm env --use-on-cd)"

# volta
# export VOLTA_HOME="$HOME/.volta"
# export PATH="$VOLTA_HOME/bin:$PATH"

# pnpm
# export PNPM_HOME="/Users/yule/Library/pnpm"
# export PATH="$PNPM_HOME:$PATH"
# pnpm end

# refs:https://github.com/microsoft/vscode-docs/issues/5221#issuecomment-1061081538
# bindkey -e

# ruby
# if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
#   export PATH=/opt/homebrew/opt/ruby/bin:$PATH
#   export PATH=$(gem environment gemdir)/bin:$PATH
# fi
# eval "$(rbenv init - zsh)"

# python
# export PYENV_ROOT="$HOME/.pyenv"
# command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"

# GitHub Copilot CLI
# eval "$(gh copilot alias -- zsh)"

# exercism
[ -s "$(brew --prefix)/share/zsh/site-functions/_exercism" ] && source "$(brew --prefix)/share/zsh/site-functions/_exercism"

# deno
export PATH="/Users/yule/.deno/bin:$PATH"

# ni
export NI_DEFAULT_AGENT="pnpm" # default "prompt"
export NI_GLOBAL_AGENT="pnpm"

# Added by Windsurf
export PATH="/Users/yule/.codeium/windsurf/bin:$PATH"
