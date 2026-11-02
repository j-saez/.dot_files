# Host-side personalisation of the team's devi-docker-run, without patching
# devi_toolkit.bashrc.
#
# devi-docker-run ends up calling `docker run --name indoor_nav_container ...`
# (create) or `docker start indoor_nav_container` (reuse). This `docker`
# function sits in front of the real binary, adjusts only those two calls and
# passes every other docker invocation through untouched.
#
#   create: add the extra mounts/caps below, drop the read-only nvim bind
#           (setup_dotfiles.sh links ~/.config/nvim itself) and make the
#           /media bind live (rslave).
#   create/start: once the container is up, run the tii-dev-scripts steps.
#
# Sourced from ~/.bash_aliases_local on the host only. Since the team script
# is untouched, a `git pull` of indoor_setup never conflicts with it.

_DOTDOCKER_CONTAINER="indoor_nav_container"

# Echo the extra `docker run` arguments, one per line.
_dotdocker_extra_args() {
    local f n claude_bin

    [ -d "$HOME/.dot_files" ] &&
        printf '%s\n' --volume "$HOME/.dot_files:/home/developer/.dot_files:rw"

    # Individual files (a directory bind is dropped by Docker when a child
    # path is already mounted); skip the ones devi_toolkit.bashrc handles.
    for f in "$HOME/.ssh"/*; do
        [ -f "$f" ] || continue
        n=$(basename "$f")
        case "$n" in authorized_keys | id_rsa | id_rsa.pub) continue ;; esac
        printf '%s\n' --volume "$f:/home/developer/.ssh/$n:ro"
    done

    # gdb/DAP process attach.
    printf '%s\n' --cap-add=SYS_PTRACE --security-opt seccomp=unconfined

    # Host Claude Code binary; linked into ~/.local/bin after startup. Mounted
    # outside ~/.local so Docker does not create ~/.local/bin as root.
    if [ -L "$HOME/.local/bin/claude" ]; then
        claude_bin=$(readlink -f "$HOME/.local/bin/claude")
        printf '%s\n' --volume "$claude_bin:/opt/claude-host-bin:ro"
    fi
}

# Steps for a container that is now up. Failures never abort the caller.
_dotdocker_post_start() {
    local c="$_DOTDOCKER_CONTAINER" s="$HOME/.dot_files/bash/tii-dev-scripts"

    # Docker creates ~/.config as root for the starship bind mount.
    command docker exec -u root "$c" chown developer:developer /home/developer/.config 2>&1 || true
    local script
    for script in setup_dap_ptrace.sh install_go.sh install_apt_pkgs.sh; do
        [ -f "$s/$script" ] && { bash "$s/$script" "$c" 2>&1 || true; }
    done
    command docker exec "$c" bash -c '[ -e /opt/claude-host-bin ] && mkdir -p ~/.local/bin && ln -sf /opt/claude-host-bin ~/.local/bin/claude' 2>&1 || true
}

docker() {
    local has_name=false a
    case "$1" in
    run)
        for a in "$@"; do [ "$a" = "$_DOTDOCKER_CONTAINER" ] && has_name=true; done
        if $has_name && [ -d "$HOME/.dot_files" ]; then
            local args=() extra=() prev=""
            mapfile -t extra < <(_dotdocker_extra_args)
            shift
            for a in "$@"; do
                if [ "$prev" = "--volume" ] && [[ $a == *:/home/developer/.config/nvim:ro ]]; then
                    # Drop the "--volume" already queued along with its value.
                    unset 'args[${#args[@]}-1]'
                    prev=""
                    continue
                fi
                case "$a" in
                type=bind,source=/media,target=/media) a="$a,bind-propagation=rslave" ;;
                esac
                args+=("$a")
                prev="$a"
            done
            command docker run "${extra[@]}" "${args[@]}"
            local rc=$?
            [ $rc -eq 0 ] && _dotdocker_post_start
            return $rc
        fi
        ;;
    start)
        if [ "$2" = "$_DOTDOCKER_CONTAINER" ]; then
            command docker "$@"
            local rc=$?
            [ $rc -eq 0 ] && _dotdocker_post_start
            return $rc
        fi
        ;;
    esac
    command docker "$@"
}
