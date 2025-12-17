#!/bin/bash

echo "Starting installation of development tools..."

# Update and upgrade Homebrew
brew update
brew upgrade

# --- GUI Applications ---
brew install --cask docker
brew install --cask podman
brew install --cask iterm2
brew install --cask visual-studio-code
brew install --cask intellij-idea-ce
brew install --cask obsidian
brew install --cask postman
brew install --cask pgadmin4
brew install --cask tableplus
brew install --cask dbeaver-community
brew install --cask mongodb-compass

# --- CLI Tools ---
brew install git
brew install maven
brew install node
brew install python
brew install openjdk
brew install go
brew install dotnet
brew install kubectl
brew install helm
brew install awscli
brew install azure-cli
brew install google-cloud-sdk
brew install terraform
brew install ansible
brew install k9s
brew install curl
brew install httpie
brew install k6
brew install coder

echo "✅ All requested tools have been installed!"

