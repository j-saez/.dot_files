#!/usr/bin/env bash
# patch_devi_toolkit.sh
#
# Idempotently patches ~/indoor_uav/indoor_setup/devi_toolkit.bashrc so that
# ~/.dot_files and ~/.ssh keys are mounted into the dev container when
# devi-docker-run is used.
#
# SSH strategy: mount individual files found in ~/.ssh (skipping the ones the
# original script already handles: authorized_keys, id_rsa, id_rsa.pub).
# This avoids the Docker conflict where a directory bind-mount is silently
# dropped when a child path is already individually bind-mounted.

set -e

TARGET="$HOME/indoor_uav/indoor_setup/devi_toolkit.bashrc"
DOT_FILES_MARKER="dot_files_mount"
# Use '+=' as marker: the loop appends with +=, the old broken approach used '='
SSH_NEW_MARKER='ssh_mount+='
PTRACE_MARKER="ptrace_cap"
DAP_SETUP_MARKER="setup_dap_ptrace"
GO_INSTALL_MARKER="install_go"
CLAUDE_INSTALL_MARKER="install_claude"

# ── Guard: skip if indoor_setup isn't present ───────────────────────────────

if [ ! -f "$TARGET" ]; then
    echo "[patch_devi_toolkit] $TARGET not found — skipping (indoor_setup not cloned yet?)"
    exit 0
fi

# ── Check which patches have already been applied ───────────────────────────

DOT_FILES_PATCHED=false
grep -q "$DOT_FILES_MARKER" "$TARGET" && DOT_FILES_PATCHED=true

SSH_PATCHED=false
grep -q "$SSH_NEW_MARKER" "$TARGET" && SSH_PATCHED=true

PTRACE_PATCHED=false
grep -q "$PTRACE_MARKER" "$TARGET" && PTRACE_PATCHED=true

DAP_SETUP_PATCHED=false
grep -q "$DAP_SETUP_MARKER" "$TARGET" && DAP_SETUP_PATCHED=true

GO_INSTALL_PATCHED=false
grep -q "$GO_INSTALL_MARKER" "$TARGET" && GO_INSTALL_PATCHED=true

CLAUDE_INSTALL_PATCHED=false
grep -q "$CLAUDE_INSTALL_MARKER" "$TARGET" && CLAUDE_INSTALL_PATCHED=true

if $DOT_FILES_PATCHED && $SSH_PATCHED && $PTRACE_PATCHED && $DAP_SETUP_PATCHED && $GO_INSTALL_PATCHED && $CLAUDE_INSTALL_PATCHED; then
    echo "[patch_devi_toolkit] Already patched — nothing to do."
    exit 0
fi

# ── Patch 1: mount ~/.dot_files ──────────────────────────────────────────────

if ! $DOT_FILES_PATCHED; then
    sed -i '/^  local indoor_env=""$/a\  local dot_files_mount=""\n  if [ -d "$HOME/.dot_files" ]; then\n    dot_files_mount="--volume $HOME/.dot_files:/home/developer/.dot_files:rw"\n  fi' "$TARGET"
    sed -i '/^    \$indoor_env \\$/a\    $dot_files_mount \\' "$TARGET"
    echo "[patch_devi_toolkit] Applied dot_files mount patch."
fi

# ── Patch 2: mount ~/.ssh individual files ───────────────────────────────────
#
# Loops over ~/.ssh/* and mounts each file individually, skipping the ones the
# original _docker_run_command already handles (authorized_keys, id_rsa,
# id_rsa.pub). This picks up tii_gitlab, tii_gitlab.pub, known_hosts, config,
# and any other keys present — without conflicting with existing file mounts.

if ! $SSH_PATCHED; then
    python3 - "$TARGET" << 'PYEOF'
import sys

target = sys.argv[1]
with open(target) as f:
    content = f.read()

NEW_DECL = (
    '  local ssh_mount=""\n'
    '  for _ssh_f in "$HOME/.ssh"/*; do\n'
    '    [ -f "$_ssh_f" ] || continue\n'
    '    _ssh_n=$(basename "$_ssh_f")\n'
    '    case "$_ssh_n" in authorized_keys|id_rsa|id_rsa.pub) continue ;; esac\n'
    '    ssh_mount+=" --volume $_ssh_f:/home/developer/.ssh/$_ssh_n:ro"\n'
    '  done'
)

# Case 1: old broken directory-mount approach → replace it
OLD_DECL = (
    '  local ssh_mount=""\n'
    '  if [ -d "$HOME/.ssh" ]; then\n'
    '    ssh_mount="--volume $HOME/.ssh:/home/developer/.ssh:ro"\n'
    '  fi'
)
if OLD_DECL in content:
    content = content.replace(OLD_DECL, NEW_DECL, 1)
    with open(target, 'w') as f:
        f.write(content)
    print("[patch_devi_toolkit] Fixed ssh_mount: replaced directory mount with individual file mounts.")
    sys.exit(0)

# Case 2: fresh install (no ssh_mount at all) → insert new block
if 'local ssh_mount' not in content:
    content = content.replace(
        '  local dot_files_mount=""',
        '  local dot_files_mount=""\n' + NEW_DECL,
        1
    )
    content = content.replace(
        '    $dot_files_mount \\',
        '    $dot_files_mount \\\n    $ssh_mount \\',
        1
    )
    with open(target, 'w') as f:
        f.write(content)
    print("[patch_devi_toolkit] Applied SSH individual file mount patch.")
    sys.exit(0)

print("[patch_devi_toolkit] WARNING: unexpected state — SSH patch not applied. Manual fix needed.")
sys.exit(1)
PYEOF
fi

# ── Patch 3: add SYS_PTRACE capability (required for DAP / gdb process attach) ─

if ! $PTRACE_PATCHED; then
    sed -i '/^  local dot_files_mount=""$/i\  local ptrace_cap="--cap-add=SYS_PTRACE --security-opt seccomp=unconfined"' "$TARGET"
    sed -i '/^    \$dot_files_mount \\$/i\    $ptrace_cap \\' "$TARGET"
    echo "[patch_devi_toolkit] Applied ptrace capability patch."
fi

# ── Patch 4: run setup_dap_ptrace.sh automatically after container creation ───
#
# Injects a call to setup_dap_ptrace.sh inside devi-docker-run, right before
# devi-docker-exec, so ptrace_scope and gdb capabilities are configured every
# time a container is created or restarted.

if ! $DAP_SETUP_PATCHED; then
    sed -i '/^    devi-docker-exec \$image_version$/i\    bash "$HOME/.dot_files/bash/tii-dev-scripts/setup_dap_ptrace.sh" "$container_name" 2>\&1 || true' "$TARGET"
    echo "[patch_devi_toolkit] Applied DAP ptrace auto-setup patch."
fi

# ── Patch 5: install Go automatically after container creation ──────────────
#
# Injects a call to install_go.sh inside devi-docker-run, right before
# devi-docker-exec, so Go is present every time a container is created or
# restarted.

if ! $GO_INSTALL_PATCHED; then
    sed -i '/^    devi-docker-exec \$image_version$/i\    bash "$HOME/.dot_files/bash/tii-dev-scripts/install_go.sh" "$container_name" 2>\&1 || true' "$TARGET"
    echo "[patch_devi_toolkit] Applied Go install patch."
fi

# ── Patch 6: install Claude Code automatically after container creation ─────
#
# Injects a call to install_claude.sh inside devi-docker-run, right before
# devi-docker-exec, so Claude Code is present every time a container is
# created or restarted.

if ! $CLAUDE_INSTALL_PATCHED; then
    sed -i '/^    devi-docker-exec \$image_version$/i\    bash "$HOME/.dot_files/bash/tii-dev-scripts/install_claude.sh" "$container_name" 2>\&1 || true' "$TARGET"
    echo "[patch_devi_toolkit] Applied Claude Code install patch."
fi

echo "[patch_devi_toolkit] Done."
