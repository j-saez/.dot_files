#!/usr/bin/env bash

# Patch tmux2k's stock gpu.sh, which has two bugs on Linux:
#  1. It picks the FIRST VGA-class PCI device as "the GPU", which is the
#     integrated GPU (not NVIDIA) on hybrid-graphics laptops, since the
#     iGPU enumerates before the dGPU on the PCI bus -- so it silently
#     shows N/A there instead of real NVIDIA usage.
#  2. On Jetson boards the GPU is not a PCI device at all (Tegra), so
#     nvidia-smi/lspci see nothing there either -- also always N/A.
#
# tmux2k has no config hook for this logic, and plugins/tmux2k is
# TPM-managed (gitignored, not a submodule) so it can't carry the patch
# itself -- reapply it (idempotently) on every tmux start instead. See the
# call to this script in tmux.conf.

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmux2k_dir="$HOME/.config/tmux/plugins/tmux2k"
gpu_plugin="$tmux2k_dir/plugins/gpu.sh"

[ -f "$gpu_plugin" ] || exit 0
grep -q '^    Jetson)' "$gpu_plugin" && exit 0 # already patched

patch -p1 -s -f -d "$tmux2k_dir" < "$current_dir/../tmux2k-gpu.patch"
