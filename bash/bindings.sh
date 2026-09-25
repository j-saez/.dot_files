# bash-completion — provides completion data for git, docker, kubectl, etc.
[[ -f /usr/share/bash-completion/bash_completion ]] && \
    source /usr/share/bash-completion/bash_completion

# Everything below (ble.sh, fzf-powered Ctrl+R/Tab) is laptop-only (set via
# setup_dotfiles.sh, see bash/dotfiles_profile.sh) — it changes the shell's
# look and default keybindings for anyone using the account, not just you.
# On a "shared" profile this leaves plain bash-completion for Tab and bash's
# native reverse-i-search for Ctrl+R.
if [[ "${DOTFILES_PROFILE:-personal}" = personal ]]; then

# ble.sh must be loaded before everything else that touches readline below
[[ $- == *i* ]] && [[ -f "$HOME/.local/share/blesh/ble.sh" ]] && \
    source "$HOME/.local/share/blesh/ble.sh" --noattach

# Vim-style paging shared by every fzf popup below: ctrl-j/ctrl-k already move
# down/up by default in fzf, ctrl-h/ctrl-l have no built-in meaning in a flat
# list so we bind them to half-page paging instead.
_fzf_vim_nav_bind='ctrl-h:half-page-up,ctrl-l:half-page-down'

# ---------------------------------------------------------------------------
# History search — Ctrl+R via fzf
# ---------------------------------------------------------------------------

command_history_search() {
    local raw
    raw=$(history | tac \
        | fzf --multi --reverse --ansi --no-sort --bind="${_fzf_vim_nav_bind}" \
        | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//') || return
    [[ -z $raw ]] && return

    # Multiple picks (via tab) don't form a valid line on their own, so chain
    # them with && instead of splicing the raw command lines together.
    local -a commands
    mapfile -t commands <<< "$raw"

    local selected_command
    printf -v selected_command '%s && ' "${commands[@]}"
    selected_command="${selected_command% && }"

    READLINE_LINE=$selected_command
    READLINE_POINT=${#selected_command}
}

bind -x '"\C-r": command_history_search'

# ---------------------------------------------------------------------------
# Tab completion — fzf-tab-completion by lincheney
# ---------------------------------------------------------------------------
# NOTE: fzf-bash-completion.sh carries a local patch (see
# bash/fzf-tab-completion.local.patch) that forces --no-multi when completing
# the command word itself, so only file/dir/subcommand arguments are
# multi-selectable. Reapply that patch after `git submodule update`.

export FZF_COMPLETION_OPTS="--multi --bind=${_fzf_vim_nav_bind}"

FZF_TAB_COMPLETION="$HOME/.dot_files/bash/fzf-tab-completion/bash/fzf-bash-completion.sh"
if [[ -f "$FZF_TAB_COMPLETION" ]]; then
    source "$FZF_TAB_COMPLETION"
    bind -x '"\t": fzf_bash_completion'
fi

# ble.sh must attach at the very end
[[ ${BLE_VERSION-} ]] && ble-attach

fi
