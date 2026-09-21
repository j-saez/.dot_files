#!/usr/bin/env bash
# Runs `devi-activate` once, automatically, on every new shell inside the dev
# container.
#
# devi-activate is defined by devi_toolkit.bashrc, which the team-managed
# ~/.bashrc only sources near the end (after ~/.bash_aliases_local, where
# this file is sourced from), so it isn't available yet at this point.
#
# A first attempt deferred the call via PROMPT_COMMAND, but bindings.sh
# (sourced right after this file) loads and attaches ble.sh, which only
# re-evaluates PROMPT_COMMAND on its own per-keypress prompt cycle — so the
# deferred call only fired after the user pressed a key, not immediately.
#
# Instead, source devi_toolkit.bashrc ourselves right here and call
# devi-activate synchronously, during ~/.bashrc's own startup — the same way
# the "Sourced ROS ..." banner already prints without needing a keypress.
# ~/.bashrc sources the same file again later at its own pace;
# devi_toolkit.bashrc only (re)defines functions/aliases (aside from a
# harmless duplicate PATH entry for ccache), so sourcing it twice is safe.
[ -f /.dockerenv ] || return 0

_devi_toolkit_rc="$HOME/indoor_uav/indoor_setup/devi_toolkit.bashrc"
if [ -f "$_devi_toolkit_rc" ]; then
    source "$_devi_toolkit_rc"
    command -v devi-activate &>/dev/null && devi-activate
fi
unset _devi_toolkit_rc
