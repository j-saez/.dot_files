#!/usr/bin/env bash
# setup_dap_ptrace.sh
#
# Configures the dev container for DAP process attach (cppdbg / MIEngine):
#
#   1. Sets ptrace_scope to 0 so cppdbg runs gdb directly without a sudo
#      wrapper or interactive y/N confirmation prompt.
#   2. Grants cap_sys_ptrace to gdb so it can attach as the non-root
#      developer user even with ptrace_scope == 0.
#
# Must be run after every container recreation:
#   ~/.dot_files/bash/tii-dev-scripts/setup_dap_ptrace.sh [container_name]
#
# Requires the container to have been started with --privileged.

set -e

CONTAINER="${1:-indoor_ros2_dev}"

if ! docker inspect "$CONTAINER" &>/dev/null; then
    echo "[setup_dap_ptrace] Container '$CONTAINER' not found or not running."
    exit 1
fi

# ── 1. ptrace_scope = 0 ───────────────────────────────────────────────────────
# With ptrace_scope=1, cppdbg wraps gdb in a sudo script and prompts the user
# for y/N confirmation in the integrated terminal — silently blocking the session.
# Setting it to 0 makes cppdbg generate a plain gdb invocation.

CURRENT_SCOPE=$(docker exec "$CONTAINER" cat /proc/sys/kernel/yama/ptrace_scope 2>/dev/null || echo "unknown")
if [ "$CURRENT_SCOPE" = "0" ]; then
    echo "[setup_dap_ptrace] ptrace_scope already 0 — skipping."
else
    docker exec -u root "$CONTAINER" bash -c "echo 0 > /proc/sys/kernel/yama/ptrace_scope"
    echo "[setup_dap_ptrace] Set ptrace_scope to 0."
fi

# ── 2. cap_sys_ptrace on gdb ─────────────────────────────────────────────────
# Even with ptrace_scope=0, a non-root user needs CAP_SYS_PTRACE to trace
# processes it did not spawn. File capabilities give gdb this power without
# running the whole session as root.

GDB_PATH=$(docker exec "$CONTAINER" which gdb 2>/dev/null || true)
if [ -z "$GDB_PATH" ]; then
    echo "[setup_dap_ptrace] gdb not found inside '$CONTAINER' — skipping cap step."
    exit 0
fi

CURRENT_CAP=$(docker exec "$CONTAINER" getcap "$GDB_PATH" 2>/dev/null || true)
if echo "$CURRENT_CAP" | grep -q "cap_sys_ptrace"; then
    echo "[setup_dap_ptrace] cap_sys_ptrace already set on $GDB_PATH — skipping."
else
    docker exec -u root "$CONTAINER" setcap cap_sys_ptrace+ep "$GDB_PATH"
    echo "[setup_dap_ptrace] Set cap_sys_ptrace+ep on $GDB_PATH."
fi

echo "[setup_dap_ptrace] Done. Container '$CONTAINER' is ready for DAP attach."
