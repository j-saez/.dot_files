###############
## Functions ##
###############

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
        # Confirm before removing the selected images
        read -p "Are you sure you want to remove images: $selected_images? (y/n): " confirmation
        if [ "$confirmation" = "y" ]; then
            # Remove the images
            docker rmi $selected_images
            echo "Images removed."
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
