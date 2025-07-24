###############
## Functions ##
###############

function fzf_kill() {
    # Use ps and fzf with multi-select
    selected_processes=$(ps -e -o pid,comm --sort=start_time | fzf --multi --reverse --header "Select one or more processes to kill (Tab to select, Enter to confirm):" | awk '{print $1}')

    # Check if any process was selected
    if [ -n "$selected_processes" ]; then
        echo "Selected PIDs:"
        echo "$selected_processes"

        read -p "Are you sure you want to kill the selected process(es)? (y/n): " confirmation
        if [ "$confirmation" = "y" ]; then
            # Loop through each selected PID and kill
            for pid in $selected_processes; do
                kill -9 "$pid" && echo "Killed process $pid" || echo "Failed to kill process $pid"
            done
        else
            echo "No processes were killed."
        fi
    else
        echo "No process selected. Exiting."
    fi
}

function fzf_docker_container_kill() {
  # Get all containers with their IDs and names
  container_info=$(docker ps -a --format "{{.ID}}\t{{.Names}}")  # -a to list all containers, not just running

  # Use fzf to select multiple containers
  selected_containers=$(echo "$container_info" | fzf -m --reverse --preview 'docker inspect --format "{{.State.Status}} {{.Image}} ({{.Name}})" {}' --header "Select containers to kill (use TAB to select multiple):")

  # Check if any containers were selected
  if [ -n "$selected_containers" ]; then
    # Confirm before killing the selected containers
    read -p "Are you sure you want to kill containers: $selected_containers? (y/n): " confirmation
    if [ "$confirmation" = "y" ]; then
      # Iterate over each selected container
      while read -r line; do
        container_id=$(echo "$line" | awk '{print $1}')  # Extract container ID
        # Check the state of the container
        state=$(docker inspect --format '{{.State.Status}}' "$container_id" 2>/dev/null)  # Suppress errors
        # If the container is running, stop it
        if [ "$state" = "running" ]; then
          echo "Stopping container: $container_id"
          docker stop "$container_id"
        fi
        # Remove the container (whether it was running or not)
        echo "Removing container: $container_id"
        docker rm "$container_id"
      done <<< "$selected_containers"

      echo "Containers killed."
    else
      echo "Containers not killed."
    fi
  else
    echo "No containers selected. Exiting."
  fi
}

function fzf_docker_image_kill() {
    # Get images with their IDs and tags/digests
    image_info=$(docker images --format "{{.ID}} {{.Repository}}:{{.Tag}}")

    # Use fzf to select multiple images
    selected_images=$(echo "$image_info" | fzf -m --reverse --header "Select images to remove (use TAB to select multiple):" | awk '{print $1}')

    # Check if any images were selected
    if [ -n "$selected_images" ]; then
        # Confirm deletion
        read -p "Are you sure you want to remove images: $selected_images? (y/n): " confirmation
        if [ "$confirmation" = "y" ]; then
            # Try to remove without forcing
            if docker rmi $selected_images; then
                echo "Images removed successfully."
            else
                echo "Some images could not be removed without force."
                read -p "Do you want to retry removal with force? (y/n): " force_confirm
                if [ "$force_confirm" = "y" ]; then
                    docker rmi -f $selected_images && echo "Images forcibly removed."
                else
                    echo "Force removal skipped."
                fi
            fi
        else
            echo "Images not removed."
        fi
    else
        echo "No images selected. Exiting."
    fi
}

#############
## Aliases ##
#############

alias fkill='fzf_kill'
alias fdrm='fzf_docker_container_kill'
alias fdrmi='fzf_docker_image_kill'
alias ll='ls -lF'
alias lla='ls -alF'

# Set alias for kubectl to kubecolor if kubecolor is installed
if command -v kubecolor &> /dev/null; then
    alias kubectl=kubecolor
fi
