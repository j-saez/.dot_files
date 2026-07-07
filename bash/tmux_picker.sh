#!/usr/bin/env bash

TMUX_BIN=/usr/bin/tmux
TMUX_CONF="$HOME/.config/tmux/tmux.conf"

# Pass through any explicit subcommands unchanged
if [ $# -gt 0 ]; then
    exec "$TMUX_BIN" -f "$TMUX_CONF" "$@"
fi

# If the server is not running, restore saved sessions or start fresh
if ! "$TMUX_BIN" -f "$TMUX_CONF" list-sessions &>/dev/null; then
    if [ -L "$HOME/.local/share/tmux/resurrect/last" ]; then
        "$TMUX_BIN" -f "$TMUX_CONF" new-session -d -s main 2>/dev/null
        "$TMUX_BIN" -f "$TMUX_CONF" run-shell \
            "$HOME/.config/tmux/plugins/tmux-resurrect/scripts/restore.sh" 2>/dev/null
    else
        exec "$TMUX_BIN" -f "$TMUX_CONF" new-session
    fi
fi

# Build picker: existing sessions + a "[new session]" entry at the top
choice=$(
    { echo "[new session]"
      "$TMUX_BIN" -f "$TMUX_CONF" list-sessions -F "#{session_name}" 2>/dev/null
    } | fzf --reverse \
            --border rounded \
            --border-label " Sessions " \
            --color "border:cyan,label:cyan" \
            --padding 1,2 \
            --header "↵ attach · select [new session] to create"
)

case "$choice" in
    "[new session]")
        read -rp "  Session name: " sname
        if [ -n "$sname" ]; then
            exec "$TMUX_BIN" -f "$TMUX_CONF" new-session -s "$sname"
        else
            exec "$TMUX_BIN" -f "$TMUX_CONF" new-session
        fi
        ;;
    "")
        # User pressed Esc — do nothing
        exit 0
        ;;
    *)
        if [ -n "$TMUX" ]; then
            exec "$TMUX_BIN" switch-client -t "$choice"
        else
            exec "$TMUX_BIN" -f "$TMUX_CONF" attach-session -t "$choice"
        fi
        ;;
esac
