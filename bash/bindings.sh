bind '"\C-r": "history | cut -c 8- | fzf --preview='{}' --height 40% --reverse --ansi --no-sort --tac | xargs -r -I {} sh -c '\''{}'\''\n"'
