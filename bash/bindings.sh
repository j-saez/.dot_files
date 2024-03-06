function command_history_search() {
    command=$(history | fzf --preview 'echo {}' --reverse --ansi --no-sort --tac | sed 's/^ *[0-9]* *//')
    eval "$command"
}

bind -x '"\C-r": command_history_search'

