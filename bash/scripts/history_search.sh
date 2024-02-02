#!/bin/bash

# Function to get the command history, display it, and filter with fzf
get_command() {
    history | cut -c 8- | fzf --preview 'echo {}' --height 40% --reverse --ansi --no-sort --tac
}

# Get the selected command
selected_command=$(get_command)

# Check if a command was selected
if [ -n "$selected_command" ]; then
    # Execute the selected command
    eval "$selected_command"
else
    echo "No command selected."
fi
