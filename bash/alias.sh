###############
##  History  ##
###############

# Increase history limits (default 1000/2000 is too small)
HISTSIZE=100000
HISTFILESIZE=200000

# After each command: append to file, then reload from file.
# This keeps all terminals in sync and makes new commands immediately
# visible in Ctrl+R without waiting for the session to end.
PROMPT_COMMAND="history -a; history -c; history -r${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

###############
##    fzf    ##
###############

export FZF_DEFAULT_OPTS="--bind 'tab:toggle+down,shift-tab:toggle+up'"

###############
## Functions ##
###############

function fzf_kill() {
    # Sort by %MEM (default / --ram) or %CPU (--cpu), highest first
    local sort_field sort_label
    case "$1" in
        --cpu)
            sort_field="-%cpu"
            sort_label="CPU%"
            ;;
        --ram|"")
            sort_field="-%mem"
            sort_label="MEM%"
            ;;
        *)
            echo "Usage: fkill [--ram|--cpu]"
            return 1
            ;;
    esac

    # Use ps and fzf with multi-select
    selected_processes=$(ps -e -o pid,%cpu,%mem,args --sort="$sort_field" | fzf --multi --reverse --header "Select one or more processes to kill (sorted by $sort_label, Tab to select, Enter to confirm):" | awk '{print $1}')

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

# Identity of the repo a worktree belongs to: its common .git dir, read
# straight from the .git file so it works even when git can't follow it.
# /home/<user>/ is normalised so host and container paths compare equal.
function _cwt_repo_id() {
    local g="$1/.git" id
    if [ -d "$g" ]; then
        id="$g"
    elif [ -f "$g" ]; then
        id=$(sed -n 's/^gitdir: //p' "$g")
        id="${id%/worktrees/*}"
    else
        return 1
    fi
    sed 's#^/home/[^/]*/#~/#' <<< "$id"
}

function fzf_colcon_worktree() {
    # Pick which git worktree colcon should build. Several worktrees of one
    # package repo (e.g. tii-slam/{main,feature/*}) define the same package
    # names, so only one may be visible to colcon: the selected worktree has
    # its COLCON_IGNORE removed, all the others get one.
    # Usage: cwt [dir]   (dir = any folder inside/above the worktrees)
    local start="${1:-$PWD}" seed id wt

    # Seed: the worktree we are in, else the worktrees found below $start
    seed=$(git -C "$start" rev-parse --show-toplevel 2>/dev/null)
    if [ -z "$seed" ]; then
        local found
        found=$(find "$start" -maxdepth 3 -name .git -prune -print 2>/dev/null | xargs -r -n1 dirname)
        [ -z "$found" ] && { echo "No git worktrees found in or around $start."; return 1; }
        local ids
        ids=$(while IFS= read -r wt; do _cwt_repo_id "$wt"; done <<< "$found" | sort -u)
        if [ "$(wc -l <<< "$ids")" -gt 1 ]; then
            echo "Several different repos under $start; cd into one worktree or pass a more specific dir."
            return 1
        fi
        seed=$(head -n1 <<< "$found")
    fi
    id=$(_cwt_repo_id "$seed") || { echo "$seed is not a git worktree."; return 1; }

    # Climb while a parent folder holds more worktrees of the same repo (so
    # running from tii-slam/feature still finds tii-slam/main), then collect.
    local root members=""
    root=$(dirname "$seed")
    local up="$root" i cand
    for i in 1 2 3 4; do
        cand=$(find "$up" -maxdepth 3 -name .git -prune -print 2>/dev/null | xargs -r -n1 dirname)
        local new=""
        while IFS= read -r wt; do
            [ -n "$wt" ] && [ "$(_cwt_repo_id "$wt")" = "$id" ] && new+="$wt"$'\n'
        done <<< "$cand"
        # Union with what we already have; stop once climbing adds nothing
        new=$(printf '%s\n%s' "$members" "$new" | sed '/^$/d' | sort -u)
        if [ "$i" -gt 1 ] && [ "$new" = "$members" ]; then break; fi
        members="$new"; root="$up"
        up=$(dirname "$up")
    done
    members=$(sort <<< "$members" | sed '/^$/d')
    if [ "$(wc -l <<< "$members")" -lt 2 ]; then
        echo "Only one worktree found for this repo; nothing to select."
        return 1
    fi

    # Keep COLCON_IGNORE out of `git status`. info/exclude lives in the
    # common git dir, so one entry covers every worktree of the repo.
    local excl
    excl=$(git -C "$(head -n1 <<< "$members")" rev-parse --path-format=absolute --git-path info/exclude 2>/dev/null)
    if [ -n "$excl" ] && ! grep -qx COLCON_IGNORE "$excl" 2>/dev/null; then
        mkdir -p "$(dirname "$excl")" && echo COLCON_IGNORE >> "$excl"
    fi

    # One line per worktree: "<state>\t<branch>\t<path>" (state is coloured)
    local branch sha state lines=""
    while IFS= read -r wt; do
        branch=$(git -C "$wt" branch --show-current 2>/dev/null)
        if [ -z "$branch" ]; then
            # Empty branch = detached HEAD *or* git failing (e.g. a .git file
            # pointing at a host path that doesn't exist in the container).
            if sha=$(git -C "$wt" rev-parse --short HEAD 2>/dev/null); then
                branch="(detached @ $sha: $(basename "$wt"))"
            else
                branch="(git error: $(basename "$wt"), see 'git -C $wt status')"
            fi
        fi
        if [ -e "$wt/COLCON_IGNORE" ]; then state=$'\e[31mignored\e[0m'; else state=$'\e[32mACTIVE \e[0m'; fi
        lines+="$state"$'\t'"$branch"$'\t'"$wt"$'\n'
    done <<< "$members"

    local selected chosen
    selected=$(printf '%s' "$lines" | fzf --ansi --delimiter $'\t' --reverse --height 40% \
        --header "Worktree to build in $root (Enter to select):")
    [ -z "$selected" ] && return 0
    chosen=$(cut -f3 <<< "$selected")

    while IFS= read -r wt; do
        if [ "$wt" = "$chosen" ]; then
            rm -f "$wt/COLCON_IGNORE"
        else
            touch "$wt/COLCON_IGNORE"
        fi
    done <<< "$members"
    echo "colcon will now build: $chosen"

    # Stale builds: a CMake build dir remembers the source dir it came from
    # and colcon refuses to reuse it for another worktree's copy.
    local ws="$root"
    while [ "$ws" != "/" ] && [ "$(basename "$ws")" != src ]; do ws=$(dirname "$ws"); done
    ws=$(dirname "$ws")
    [ "$ws" = "/" ] || [ ! -d "$ws/build" ] && return 0

    local pkgxml pkg pkgdir cache home_dir stale=()
    while IFS= read -r pkgxml; do
        pkg=$(sed -n 's#.*<name>\(.*\)</name>.*#\1#p' "$pkgxml" | head -n1)
        pkgdir=$(dirname "$pkgxml")
        cache="$ws/build/$pkg/CMakeCache.txt"
        [ -f "$cache" ] || continue
        home_dir=$(sed -n 's/^CMAKE_HOME_DIRECTORY:INTERNAL=//p' "$cache")
        [ -n "$home_dir" ] && [ "$(realpath -m "$home_dir")" != "$(realpath -m "$pkgdir")" ] && stale+=("$pkg")
    done < <(find "$chosen" -maxdepth 3 -name package.xml 2>/dev/null)

    if [ "${#stale[@]}" -gt 0 ]; then
        echo "Built from another worktree: ${stale[*]}"
        read -p "Remove their build/ and install/ dirs in $ws? (y/n): " confirmation
        if [ "$confirmation" = "y" ]; then
            for pkg in "${stale[@]}"; do
                rm -rf "$ws/build/$pkg" "$ws/install/$pkg"
            done
            echo "Removed."
        fi
    fi
}

function copy_path_pwd() {
    # Get current directory
    local dir
    dir=$(pwd)

    # Print the path
    echo "$dir"

    # Replace the current username with a literal, unexpanded $USER
    # so the copied path stays valid across machines/containers where
    # the same path exists under a different user (e.g. host vs docker).
    local dir_copy="${dir//$USER/\$USER}"

    # Auto-install xclip if it's missing
    if ! command -v xclip &> /dev/null; then
        echo "xclip not found, installing..."
        sudo apt-get update && sudo apt-get install -y xclip
    fi

    # Copy to clipboard
    if command -v xclip &> /dev/null; then
        echo -n "$dir_copy" | xclip -selection clipboard
        echo "Copied to clipboard: $dir_copy"
    else
        echo "Failed to install xclip, cannot copy to clipboard"
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
alias pwdc='copy_path_pwd'
alias cwt='fzf_colcon_worktree'
alias worktree-colcon-selection='fzf_colcon_worktree'

function fzf_devi_selector() {
    # Find all commands starting with 'devi-' in the PATH
    local selected_command
    selected_command=$(compgen -c | grep '^devi-' | sort -u | fzf --reverse --height 40% --header "Select a devi- command to execute:" --bind 'ctrl-j:down,ctrl-k:up')

    # Execute the selected command if one was picked
    if [ -n "$selected_command" ]; then
        eval "$selected_command"
    fi
}

function claude_init() {
    local templates_dir="$HOME/.dot_files/claude"
    local profile="$1"

    if [ -z "$profile" ]; then
        profile=$(find "$templates_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | fzf --reverse --height 40% --header "Select a Claude profile to initialize:")
        [ -z "$profile" ] && return 1
    fi

    if [ ! -d "$templates_dir/$profile" ]; then
        echo "Unknown profile: $profile"
        return 1
    fi

    cp -rv --update=none "$templates_dir/$profile/." .
}

alias cinit='claude_init'
alias jsaez-install='bash $HOME/.dot_files/bash/setup_dotfiles.sh'
alias jsaez-uninstall='bash $HOME/.dot_files/bash/uninstall_dotfiles.sh'

alias devi='fzf_devi_selector'
alias devi-='fzf_devi_selector'


# Set alias for kubectl to kubecolor if kubecolor is installed
if command -v kubecolor &> /dev/null; then
    alias kubectl=kubecolor
fi

# On a personal machine, `tmux` itself launches the fzf session picker with
# your config. On a shared account, that would force the picker on anyone
# else who types `tmux`, so it's opt-in there via `tmux-jsaez` instead.
if [ "${DOTFILES_PROFILE:-personal}" = shared ]; then
    alias tmux-jsaez='bash $HOME/.dot_files/bash/tmux_picker.sh'
else
    alias tmux='bash $HOME/.dot_files/bash/tmux_picker.sh'
fi
