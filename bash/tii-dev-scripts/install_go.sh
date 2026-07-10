#!/usr/bin/env bash
# install_go.sh
#
# Installs Go inside the dev container (idempotent): downloads the official
# Go toolchain tarball and extracts it to /usr/local/go, following the
# standard install steps from https://go.dev/dl/.
#
# PATH is not set up here — /usr/local/go/bin is added to PATH via
# ~/.bash_aliases_local (see setup_dotfiles.sh), which is bind-mounted into
# the container from the host, so it's already in place before this runs.
#
# Must be run after every container creation:
#   ~/.dot_files/bash/tii-dev-scripts/install_go.sh [container_name]
#
# Set GO_VERSION to install a different release than the pinned default.

set -e

CONTAINER="${1:-indoor_ros2_dev}"
GO_VERSION="${GO_VERSION:-1.26.5}"

if ! docker inspect "$CONTAINER" &>/dev/null; then
    echo "[install_go] Container '$CONTAINER' not found or not running."
    exit 1
fi

if docker exec "$CONTAINER" bash -c 'command -v go' &>/dev/null; then
    echo "[install_go] go already installed in '$CONTAINER' — skipping."
    exit 0
fi

ARCH=$(docker exec "$CONTAINER" uname -m)
case "$ARCH" in
    x86_64) GOARCH="amd64" ;;
    aarch64 | arm64) GOARCH="arm64" ;;
    *)
        echo "[install_go] Unsupported architecture '$ARCH' — skipping."
        exit 0
        ;;
esac

TARBALL="go${GO_VERSION}.linux-${GOARCH}.tar.gz"
URL="https://go.dev/dl/${TARBALL}"

echo "[install_go] Installing go${GO_VERSION} (${GOARCH}) in '$CONTAINER'..."
docker exec -u root "$CONTAINER" bash -c "
    set -e
    wget -q '$URL' -O '/tmp/$TARBALL'
    rm -rf /usr/local/go
    tar -C /usr/local -xzf '/tmp/$TARBALL'
    rm -f '/tmp/$TARBALL'
"

echo "[install_go] Done. go${GO_VERSION} installed in '$CONTAINER' at /usr/local/go."
