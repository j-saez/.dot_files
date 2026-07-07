#!/usr/bin/env bash
# Sets up and activates ~/.venv on first shell entry inside the dev container.
# Idempotent: if a healthy venv already exists it just activates it.
[ -f /.dockerenv ] || return 0

# Install system packages that the base image may not include.
if ! command -v xclip &>/dev/null; then
    echo "[container_venv] Installing xclip..."
    sudo apt update && sudo apt-get install -y -q --no-install-recommends xclip
fi

_venv="$HOME/.venv"

# Healthy venv (pip present) — just activate
if [ -f "$_venv/bin/pip" ]; then
    source "$_venv/bin/activate"
    return 0
fi

# Remove any broken partial directory left by a previous failed attempt
rm -rf "$_venv"

if python3 -c "import ensurepip" 2>/dev/null; then
    # --system-site-packages makes the venv inherit system packages (including
    # ROS2's NumPy 1.x), so pip-installed tools like evo do not pull in a
    # conflicting NumPy 2.x that would break cv_bridge.
    python3 -m venv --system-site-packages "$_venv"
else
    # ensurepip is not available in this container image — create the venv
    # skeleton without pip, then bootstrap pip via get-pip.py
    echo "[container_venv] ensurepip unavailable, bootstrapping pip manually..."
    python3 -m venv --system-site-packages --without-pip "$_venv"
    source "$_venv/bin/activate"
    curl -fsSL https://bootstrap.pypa.io/get-pip.py | python3
    deactivate
fi

if [ -f "$_venv/bin/pip" ]; then
    echo "[container_venv] Virtual environment ready at $_venv"
    source "$_venv/bin/activate"
else
    echo "[container_venv] ERROR: failed to set up virtual environment"
fi
