# WIP
# Install Homebrew & apps

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zprofile

brew update
brew upgrade

apps=(
   gh
   go
   glab
)

brew install "${apps[@]}"

# Install `FiraCode` font
brew tap homebrew/cask-fonts
brew install --cask font-fira-code
