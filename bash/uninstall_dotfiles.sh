#!/usr/bin/env bash

# Undo what setup_dotfiles.sh configured. By default only the configuration is
# reverted (symlinks, shell hooks, launchers, timer, cron, GNOME setting).
# Pass --purge to also delete the binaries and tools setup installed into
# ~/.local and ~/.nvm. apt packages and the ~/.dot_files checkout are left alone.
#
# Usage: uninstall_dotfiles.sh [--purge] [--dry-run]

set -o pipefail

DEST_DIR="$HOME/.dot_files"
BASHRC="$HOME/.bash_aliases_local"
CRON_COMMENT="# dotfiles auto update"
CRON_JOB="0 8 * * * $DEST_DIR/bash/update_dotfiles.sh >/dev/null 2>&1"

PURGE=false
DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --purge) PURGE=true ;;
        --dry-run) DRY_RUN=true ;;
        *)
            echo "Usage: $0 [--purge] [--dry-run]" >&2
            exit 1
            ;;
    esac
done

run() {
    if [ "$DRY_RUN" = true ]; then
        echo "[dry-run] $*"
    else
        "$@"
    fi
}

remove_link_to_repo() {
    local target="$1"
    if [ -L "$target" ] && [[ "$(readlink "$target")" == "$DEST_DIR"/* ]]; then
        run rm -f "$target"
        echo "Removed link $target"
    fi
}

remove_path() {
    if [ -e "$1" ] || [ -L "$1" ]; then
        run rm -rf "$1"
        echo "Removed $1"
    fi
}

# Config symlinks into the repo
remove_link_to_repo "$HOME/.config/nvim"
remove_link_to_repo "$HOME/.config/tmux"
remove_link_to_repo "$HOME/.config/ghostty"
remove_link_to_repo "$HOME/.config/blesh/init.sh"
remove_link_to_repo "$HOME/.local/bin/ghostty-maximized"
remove_link_to_repo "$HOME/.local/bin/raise-or-launch"

# Ghostty launcher override and GNOME terminal shortcut
remove_path "$HOME/.local/share/applications/com.mitchellh.ghostty.desktop"
if command -v gsettings &>/dev/null \
    && [ "$(gsettings get org.gnome.desktop.default-applications.terminal exec 2>/dev/null)" = "'$HOME/.local/bin/ghostty-maximized'" ]; then
    run gsettings reset org.gnome.desktop.default-applications.terminal exec
    echo "Reset GNOME's default terminal"
fi

# xbindkeys shortcuts
if [ -f "$HOME/.xbindkeysrc" ] && grep -q raise-or-launch "$HOME/.xbindkeysrc"; then
    run killall xbindkeys 2>/dev/null
    remove_path "$HOME/.xbindkeysrc"
fi
remove_path "$HOME/.config/autostart/xbindkeys.desktop"

# systemd timer
if [ -L "$HOME/.config/systemd/user/ssd-bags-symlink.timer" ]; then
    run systemctl --user disable --now ssd-bags-symlink.timer
    remove_link_to_repo "$HOME/.config/systemd/user/ssd-bags-symlink.timer"
    remove_link_to_repo "$HOME/.config/systemd/user/ssd-bags-symlink.service"
    run systemctl --user daemon-reload
fi

# Cron job
if crontab -l 2>/dev/null | grep -qF "$CRON_COMMENT"; then
    if [ "$DRY_RUN" = true ]; then
        echo "[dry-run] remove dotfiles cron job"
    else
        crontab -l | grep -vF -e "$CRON_COMMENT" -e "$CRON_JOB" | crontab -
    fi
    echo "Removed dotfiles cron job"
fi

# Lines setup added to ~/.bash_aliases_local
HOOK_LINES=(
    "case :\$PATH: in *:\$HOME/.local/bin:*) ;; *) export PATH=\"\$HOME/.local/bin:\$PATH\" ;; esac"
    "case :\$PATH: in *:/usr/local/go/bin:*) ;; *) export PATH=\"/usr/local/go/bin:\$PATH\" ;; esac"
    "export TMUX_CONF_DIR=\"\$HOME/.dot_files/tmux\""
    "[ -s \"\$HOME/.nvm/nvm.sh\" ] && \\. \"\$HOME/.nvm/nvm.sh\""
    "[ -f /.dockerenv ] && export TERM=xterm-256color"
    "[ -f /.dockerenv ] && [ -f \"\$HOME/.dot_files/bash/devi_activate.sh\" ] && source \"\$HOME/.dot_files/bash/devi_activate.sh\""
    "source \$HOME/.dot_files/bash/dotfiles_profile.sh"
    "source \$HOME/.dot_files/bash/alias.sh"
    "source \$HOME/.dot_files/bash/ros2_completion.sh"
    "source \$HOME/.dot_files/bash/bindings.sh"
    "[ -f /.dockerenv ] || source \"\$HOME/.dot_files/bash/docker_wrapper.sh\""
    "[ -f /.dockerenv ] && [ -d \"\$HOME/.dot_files\" ] && [ ! -L \"\$HOME/.config/nvim\" ] && bash \"\$HOME/.dot_files/bash/setup_dotfiles.sh\""
)
if [ -f "$BASHRC" ]; then
    for line in "${HOOK_LINES[@]}"; do
        if grep -Fxq "$line" "$BASHRC"; then
            if [ "$DRY_RUN" = false ]; then
                # Write in place: $BASHRC may be bind-mounted as a single file.
                grep -Fxv "$line" "$BASHRC" > "$BASHRC.tmp" && cat "$BASHRC.tmp" > "$BASHRC" && rm -f "$BASHRC.tmp"
            fi
            echo "Removed from $BASHRC: $line"
        fi
    done
fi

remove_path "$HOME/.dotfiles_profile"

if [ "$PURGE" = true ]; then
    echo "Purging installed tools..."
    remove_path "$HOME/.local/bin/nvim"
    remove_path "$HOME/.local/lib/nvim"
    remove_path "$HOME/.local/share/nvim"
    remove_path "$HOME/.local/state/nvim"
    remove_path "$HOME/.cache/nvim"
    remove_path "$HOME/.local/bin/tmux"
    remove_path "$HOME/.local/share/man/man1/tmux.1"
    remove_path "$HOME/.local/share/blesh"
    remove_path "$HOME/.local/bin/ghostty"
    remove_path "$HOME/.local/share/ghostty"
    remove_path "$HOME/.nvm"
fi

echo "Uninstall complete. Restart your terminal. $DEST_DIR was left in place; remove it manually if you want it gone."
