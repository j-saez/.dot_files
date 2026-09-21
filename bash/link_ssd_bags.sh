#!/usr/bin/env bash
# link_ssd_bags.sh
#
# (Re)creates the ~/indoor_uav/bags symlink pointing at the javier_ssd's bags
# folder. Both ~/indoor_uav and /media are already bind-mounted wholesale
# into the dev container (see devi_toolkit.bashrc), so this symlink resolves
# on the host and inside the container alike.
#
# Triggered automatically by the ssd-bags-symlink systemd --user path unit
# (installed by setup_dotfiles.sh) every time the SSD is plugged in and
# udisks2 mounts it. Safe to run manually too.

set -e

SSD_BAGS="/media/$USER/javier_ssd/bags"
LINK_TARGET="$HOME/indoor_uav/bags"

if [ ! -d "$SSD_BAGS" ]; then
    echo "[link_ssd_bags] $SSD_BAGS not present — SSD not mounted, skipping."
    exit 0
fi

if [ -L "$LINK_TARGET" ] && [ "$(readlink -f "$LINK_TARGET")" = "$(readlink -f "$SSD_BAGS")" ]; then
    echo "[link_ssd_bags] $LINK_TARGET already links to $SSD_BAGS — skipping."
    exit 0
fi

if [ -e "$LINK_TARGET" ] && [ ! -L "$LINK_TARGET" ]; then
    echo "[link_ssd_bags] ERROR: $LINK_TARGET exists and is not a symlink — refusing to overwrite." >&2
    exit 1
fi

ln -sfn "$SSD_BAGS" "$LINK_TARGET"
echo "[link_ssd_bags] Linked $LINK_TARGET -> $SSD_BAGS"
