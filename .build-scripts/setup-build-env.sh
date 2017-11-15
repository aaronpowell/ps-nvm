#! /bin/sh

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    # Fix ruby error https://github.com/Homebrew/brew/issues/3299
    brew update
    brew tap caskroom/cask
    brew cask install powershell
fi

if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    # Import the public repository GPG keys
    curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

    # Register the Microsoft Ubuntu repository
    curl https://packages.microsoft.com/config/ubuntu/14.04/prod.list | sudo tee /etc/apt/sources.list.d/microsoft.list

    # Update the list of products
    sudo apt-get update

    # Install PowerShell
    sudo apt-get install -y powershell
fi
