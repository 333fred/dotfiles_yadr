#!/bin/sh

if [ ! -d "$HOME/.yadr" ]; then
    echo "Installing YADR for the first time"
    if [ ! -z "$1" ]; then
        git clone -b "$1" --depth=1 https://github.com/333fred/dotfiles_yadr.git "$HOME/.yadr"
    else
        git clone --depth=1 https://github.com/333fred/dotfiles_yadr.git "$HOME/.yadr"
    fi
    cd "$HOME/.yadr"
    [ "$1" = "ask" ] && export ASK="true"
    rake install
else
    echo "YADR is already installed"
fi
