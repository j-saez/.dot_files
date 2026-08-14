#!/usr/bin/env bash

# On Jetson boards only, patch tmux2k's stock gpu.sh (which only knows
# nvidia-smi/lspci -- both blind to Tegra's non-PCI GPU) so the status bar
# shows real GPU load there instead of always N/A. Everywhere else, this
# exits immediately and tmux2k's plugin file is left completely untouched,
# so upstream fixes/icons/features always apply there with no drift.
#
# plugins/tmux2k is TPM-managed (gitignored, not a submodule), so it can't
# carry this patch itself -- re-applied (idempotently) on every tmux start
# instead. See the call to this script in tmux.conf.

[ -f /etc/nv_tegra_release ] || exit 0

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmux2k_dir="$HOME/.config/tmux/plugins/tmux2k"
gpu_plugin="$tmux2k_dir/plugins/gpu.sh"

[ -f "$gpu_plugin" ] || exit 0
grep -q '^    Jetson)' "$gpu_plugin" && exit 0 # already patched

patch -p1 -s -f -d "$tmux2k_dir" < "$current_dir/../tmux2k-gpu-jetson.patch"
