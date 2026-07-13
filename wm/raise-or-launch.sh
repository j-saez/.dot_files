#!/usr/bin/env bash
# Cycles through windows whose WM_CLASS matches <class-pattern>: each run
# raises the window after the currently focused one (wrapping around), so
# repeated presses step through every matching window like a mini alt-tab
# scoped to just that app. Runs <launch-cmd...> to start one if none exist.
#
# Usage: raise-or-launch.sh <class-pattern> <launch-cmd> [args...]

set -u

class_pattern="$1"
shift

mapfile -t matches < <(wmctrl -lx | awk -v p="$class_pattern" 'tolower($3) ~ tolower(p) {print $1}')

if [ "${#matches[@]}" -eq 0 ]; then
    "$@" &
    disown
    exit
fi

# wmctrl/xprop print window IDs with inconsistent hex padding, so compare
# as decimal rather than as strings.
active=$(printf '%d' "$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $NF}')" 2>/dev/null || echo -1)

next_index=0
for i in "${!matches[@]}"; do
    if [ "$(printf '%d' "${matches[$i]}")" = "$active" ]; then
        next_index=$(( (i + 1) % ${#matches[@]} ))
        break
    fi
done

wmctrl -i -a "${matches[$next_index]}"
