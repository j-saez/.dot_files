#!/usr/bin/env bash
# install_claude.sh
#
# Installs Claude Code inside the dev container (idempotent): runs the
# official native installer, which drops a versioned build under
# ~/.local/share/claude and symlinks ~/.local/bin/claude.
#
# PATH is not set up here — ~/.local/bin is added to PATH via
# ~/.bash_aliases_local (see setup_dotfiles.sh), which is bind-mounted into
# the container from the host, so it's already in place before this runs.
#
# Runs as the container's default (non-root) user so the install lands in
# that user's $HOME, matching how the native installer is meant to be used.
#
# Must be run after every container creation:
#   ~/.dot_files/bash/tii-dev-scripts/install_claude.sh [container_name]

set -e

CONTAINER="${1:-indoor_ros2_dev}"

if ! docker inspect "$CONTAINER" &>/dev/null; then
    echo "[install_claude] Container '$CONTAINER' not found or not running."
    exit 1
fi

if docker exec "$CONTAINER" bash -c 'command -v claude' &>/dev/null; then
    echo "[install_claude] claude already installed in '$CONTAINER' — skipping."
    exit 0
fi

echo "[install_claude] Installing Claude Code in '$CONTAINER'..."
docker exec "$CONTAINER" bash -c 'curl -fsSL https://claude.ai/install.sh | bash'

echo "[install_claude] Done. claude installed in '$CONTAINER'."
