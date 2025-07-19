command_history_search() {
    # Get current session history, reverse it, then select with fzf
    local selected_command
    selected_command=$(history | tac | fzf --reverse --ansi --no-sort | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//') || return

    if [[ -n $selected_command ]]; then
        READLINE_LINE=$selected_command
        READLINE_POINT=${#selected_command}
    fi
}

bind -x '"\C-r": command_history_search'
