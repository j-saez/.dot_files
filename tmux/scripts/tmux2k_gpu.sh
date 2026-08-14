#!/usr/bin/env bash

# Jetson-aware drop-in replacement for tmux2k's plugins/gpu.sh.
#
# On Jetson (Tegra) boards the GPU is not a PCI device, so it never shows up
# via `nvidia-smi` or `lspci` and tmux2k's stock detection falls through to
# N/A. `/etc/nv_tegra_release` is the standard L4T marker for "this is a
# Jetson", and `tegrastats` (ships with L4T) is the standard way to sample
# GR3D (GPU) load without extra dependencies like jetson-stats.
#
# tmux2k has no config option to override gpu.sh's detection logic, and
# plugins/tmux2k is TPM-managed (gitignored, not a submodule), so this file
# is copied over it by tmux.conf every time tmux starts. See the
# "tmux2k_gpu_plugin" block in tmux.conf.

export LC_ALL=en_US.UTF-8

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

gpu_gradient="$(get_tmux_option '@tmux2k-gpu-gradient' '')"

[ -n "$gpu_gradient" ] &&
    source "$current_dir/../lib/color-utils.sh"

gpu_icon_link_to="$(get_tmux_option '@tmux2k-gpu-icon-link-to' '')"

get_platform() {
    case $(uname -s) in
    Linux)
        if [ -f /etc/nv_tegra_release ]; then
            echo "Jetson"
        elif lspci 2>/dev/null | grep -qi nvidia; then
            echo "NVIDIA"
        else
            gpu=$(lspci -v | grep VGA | head -n 1 | awk '{print $5}')
            echo "$gpu"
        fi
        ;;
    Darwin) echo "Apple" ;;
    CYGWIN* | MINGW32* | MSYS* | MINGW*) ;; # TODO - windows compatibility
    esac
}

get_gpu() {
    local gpu usage
    gpu=$(get_platform)

    case "$gpu" in
    NVIDIA)
        usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{ sum += $0 } END { printf("%s", sum / NR) }')
        ;;
    Jetson)
        # `head -n1` closing the pipe should make tegrastats exit on SIGPIPE,
        # but `timeout` guarantees it never lingers if that doesn't happen.
        usage=$(timeout 1 tegrastats --interval 200 2>/dev/null | head -n 1 | grep -oP 'GR3D_FREQ \K[0-9]+(?=%)')
        ;;
    Apple)
        usage=$(ioreg -l 2>/dev/null | grep "PerformanceStatistics" | grep "Device Utilization" | sed -n 's/.*"Device Utilization %"=\([0-9]*\).*/\1/p' | head -1)
        ;;
    esac

    if [ -z "$usage" ]; then
        normalize_padding 'N/A'
        return
    fi

    local output=''
    if [ -n "$gpu_gradient" ]; then
        local color
        color="$(pct2color "${usage}%" "$gpu_gradient")"
        output+="#[fg=${color:-default}]"
        [ "$gpu_icon_link_to" = 'usage' ] &&
            tmux set -g '@tmux2k-gpu-linked-color' "$color"
    fi
    output+="$(normalize_padding "${usage}%")"
    printf '%s' "$output"
}

main() {
    local gpu_icon gpu_usage output=''
    gpu_icon=$(get_tmux_option "@tmux2k-gpu-icon" "")
    gpu_usage=$(get_gpu)

    if [ -z "$gpu_icon_link_to" ] || [ -z "$gpu_gradient" ]; then
        tmux set -g '@tmux2k-gpu-linked-color' ''
    else
        local gpu_linked_color
        gpu_linked_color="$(get_tmux_option '@tmux2k-gpu-linked-color' '')"
        [ -n "$gpu_linked_color" ] &&
            output+="#[fg=${gpu_linked_color}]"
    fi

    output+="$gpu_icon $gpu_usage"
    printf '%s' "$output"
}

main
