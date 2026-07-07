#!/usr/bin/env bash
# Fixes ros2 tab-completion inside the dev Docker container.
# Has no effect on the host machine.
#
# Two problems solved here:
#
# 1. ROS2 setup.bash may not be sourced yet (needed for argcomplete functions).
#    Sourced below as a fallback; /etc/bash.bashrc in the image already does it.
#
# 2. The team's ros2() wrapper in ~/.bash_functions (deployed by devi-provision,
#    NOT safe to modify) uses `2>&1 | grep` which pipes stdout through grep into
#    /dev/null — exactly where argcomplete (via FD 8) writes completions. This
#    file is sourced from ~/.bash_aliases_local, which runs *before*
#    ~/.bash_functions in ~/.bashrc, so a simple ros2() override here gets
#    immediately clobbered. Instead, we register a custom completion function
#    that calls the ros2 binary directly (type -P), bypassing the wrapper,
#    regardless of what ~/.bash_functions does later.

[ -f /.dockerenv ] || return 0

# Ensure setup.bash is sourced so __python_argcomplete_run* are defined.
_ros2_auto_source() {
    local setup_file=""
    if [ -n "${DEVI_UNDERLAY_PATH}" ] && [ -f "${DEVI_UNDERLAY_PATH}/setup.bash" ]; then
        setup_file="${DEVI_UNDERLAY_PATH}/setup.bash"
    elif [ -d "/opt/ros" ]; then
        local distro
        distro=$(find /opt/ros -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | head -n 1)
        [ -n "$distro" ] && setup_file="/opt/ros/$distro/setup.bash"
    fi
    [ -f "$setup_file" ] && source "$setup_file"
}
_ros2_auto_source
unset -f _ros2_auto_source

# Custom completion that calls the ros2 binary directly via type -P, bypassing
# any ros2() shell function wrapper. Mirrors _python_argcomplete exactly but
# substitutes __python_argcomplete_run with the binary path so the broken
# 2>&1|grep pipe in the wrapper never gets involved.
# IFS must be $'\013' (^K / vertical tab) — that is the delimiter argcomplete
# uses to separate completions in its output.
_ros2_completion_direct() {
    local IFS=$'\013'
    local script=""
    local SUPPRESS_SPACE=0
    if compopt +o nospace 2>/dev/null; then
        SUPPRESS_SPACE=1
    fi
    local ros2_bin
    ros2_bin="$(type -P ros2 2>/dev/null)" || return 1
    COMPREPLY=( $(IFS="$IFS" \
        COMP_LINE="$COMP_LINE" \
        COMP_POINT="$COMP_POINT" \
        COMP_TYPE="$COMP_TYPE" \
        _ARGCOMPLETE_COMP_WORDBREAKS="$COMP_WORDBREAKS" \
        _ARGCOMPLETE=1 \
        _ARGCOMPLETE_SHELL="bash" \
        _ARGCOMPLETE_SUPPRESS_SPACE="$SUPPRESS_SPACE" \
        __python_argcomplete_run "$ros2_bin") )
    if [[ $? != 0 ]]; then
        unset COMPREPLY
    elif [[ $SUPPRESS_SPACE == 1 ]] && [[ "${COMPREPLY-}" =~ [=/:]$ ]]; then
        compopt -o nospace
    fi
}
complete -o bashdefault -o default -o nospace -F _ros2_completion_direct ros2

# devi-activate (and any other command that sources a ROS setup file) calls
# `register-python-argcomplete3 ros2` which resets the registration back to
# _python_argcomplete.  Re-register after every command where that happens.
_ensure_ros2_completion() {
    local spec
    spec=$(complete -p ros2 2>/dev/null)
    [[ $spec == *_ros2_completion_direct* ]] || \
        complete -o bashdefault -o default -o nospace -F _ros2_completion_direct ros2
}
[[ $PROMPT_COMMAND == *_ensure_ros2_completion* ]] || \
    PROMPT_COMMAND="_ensure_ros2_completion${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
