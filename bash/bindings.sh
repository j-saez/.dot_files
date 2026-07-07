# ble.sh must be loaded before everything else in this file
[[ $- == *i* ]] && [[ -f "$HOME/.local/share/blesh/ble.sh" ]] && \
    source "$HOME/.local/share/blesh/ble.sh" --noattach

# bash-completion — provides completion data for git, docker, kubectl, etc.
[[ -f /usr/share/bash-completion/bash_completion ]] && \
    source /usr/share/bash-completion/bash_completion

# ---------------------------------------------------------------------------
# History search — Ctrl+R via fzf
# ---------------------------------------------------------------------------

command_history_search() {
    local selected_command
    selected_command=$(history | tac | fzf --reverse --ansi --no-sort | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')  || return

    if [[ -n $selected_command ]]; then
        READLINE_LINE=$selected_command
        READLINE_POINT=${#selected_command}
    fi
}

bind -x '"\C-r": command_history_search'

# ---------------------------------------------------------------------------
# Tab completion — fzf-tab-completion by lincheney
# ---------------------------------------------------------------------------

FZF_TAB_COMPLETION="$HOME/.dot_files/bash/fzf-tab-completion/bash/fzf-bash-completion.sh"
if [[ -f "$FZF_TAB_COMPLETION" ]]; then
    source "$FZF_TAB_COMPLETION"
    bind -x '"\t": fzf_bash_completion'
fi

# ble.sh must attach at the very end
[[ ${BLE_VERSION-} ]] && ble-attach
