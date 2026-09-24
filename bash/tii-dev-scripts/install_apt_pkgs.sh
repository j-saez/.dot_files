#!/usr/bin/env bash
# install_apt_pkgs.sh
#
# Installs a fixed set of apt packages inside the dev container (idempotent):
# skips any package already installed and only apt-get installs what's
# missing.
#
# Must be run after every container creation:
#   ~/.dot_files/bash/tii-dev-scripts/install_apt_pkgs.sh [container_name]
#
# Set APT_PKGS to install a different package list than the pinned default.

set -e

CONTAINER="${1:-indoor_ros2_dev}"
APT_PKGS="${APT_PKGS:-xclip tree htop python3-venv}"

if ! docker inspect "$CONTAINER" &>/dev/null; then
    echo "[install_apt_pkgs] Container '$CONTAINER' not found or not running."
    exit 1
fi

MISSING=()
for pkg in $APT_PKGS; do
    docker exec "$CONTAINER" dpkg -s "$pkg" &>/dev/null || MISSING+=("$pkg")
done

if [ ${#MISSING[@]} -eq 0 ]; then
    echo "[install_apt_pkgs] All packages already installed in '$CONTAINER' — skipping."
    exit 0
fi

echo "[install_apt_pkgs] Installing ${MISSING[*]} in '$CONTAINER'..."
docker exec -u root "$CONTAINER" bash -c "
    set -e
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends ${MISSING[*]}
"

echo "[install_apt_pkgs] Done. Installed: ${MISSING[*]}"
