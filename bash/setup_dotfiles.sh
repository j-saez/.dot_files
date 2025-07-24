#!/usr/bin/env bash

set -e

REPO_URL="https://github.com/j-saez/.dot_files.git"
DEST_DIR="$HOME/.dot_files"

NVIM_TARGET="$HOME/.config/nvim"
TMUX_TARGET="$HOME/.config/tmux"

CRON_COMMENT="# dotfiles auto update"
CRON_JOB="0 8 * * * $DEST_DIR/bash/update_dotfiles.sh >/dev/null 2>&1"

# Clone the repo if it doesn't exist
if [ ! -d "$DEST_DIR" ]; then
    echo "Cloning dotfiles repo..."
    git clone "$REPO_URL" "$DEST_DIR"
else
    echo "Dotfiles repo already exists at $DEST_DIR"
fi

# Create symlinks for nvim and tmux configs
mkdir -p "$HOME/.config"

if [ -L "$NVIM_TARGET" ] || [ -e "$NVIM_TARGET" ]; then
    echo "Removing existing $NVIM_TARGET"
    rm -rf "$NVIM_TARGET"
fi
ln -s "$DEST_DIR/nvim" "$NVIM_TARGET"
echo "Linked $NVIM_TARGET -> $DEST_DIR/nvim"

if [ -L "$TMUX_TARGET" ] || [ -e "$TMUX_TARGET" ]; then
    echo "Removing existing $TMUX_TARGET"
    rm -rf "$TMUX_TARGET"
fi
ln -s "$DEST_DIR/tmux" "$TMUX_TARGET"
echo "Linked $TMUX_TARGET -> $DEST_DIR/tmux"

# Ensure ~/.bashrc sources alias.sh and bindings.sh from .dot_files/bash
BASHRC="$HOME/.bashrc"
SOURCE_LINES=(
    "source \$HOME/.dot_files/bash/alias.sh"
    "source \$HOME/.dot_files/bash/bindings.sh"
)

for line in "${SOURCE_LINES[@]}"; do
    if ! grep -Fxq "$line" "$BASHRC"; then
        echo "$line" >> "$BASHRC"
        echo "Added '$line' to $BASHRC"
    else
        echo "'$line' already in $BASHRC"
    fi
done

# Add cron job to update dotfiles daily at 8 AM
(crontab -l 2>/dev/null | grep -v -F "$CRON_COMMENT" || true; echo "$CRON_COMMENT"; echo "$CRON_JOB") | crontab -
echo "Cron job installed to update dotfiles daily at 8 AM."

echo "Setup complete! Please restart your terminal or source your ~/.bashrc to apply changes."
