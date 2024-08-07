function fzf_kill() {
    # Use ps and fzf to select a process
    selected_process=$(ps -e -o pid,comm | fzf --reverse --header "Select a process to kill:" | awk '{print $1}')

    # Check if a process was selected
    if [ -n "$selected_process" ]; then
        # Confirm before killing the selected process
        read -p "Are you sure you want to kill process $selected_process? (y/n): " confirmation
        if [ "$confirmation" = "y" ]; then
            # Kill the selected process with SIGKILL (-9)
            kill -9 "$selected_process"
            echo "Process $selected_process killed."
        else
            echo "Process not killed."
        fi
    else
        echo "No process selected. Exiting."
    fi
}

alias fkill='fzf_kill'
alias ll='ls -lF'
alias lla='ls -alF'
