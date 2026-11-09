#!/usr/bin/env bash

set -e
set -o pipefail

REPO_URL="https://github.com/j-saez/.dot_files.git"
DEST_DIR="$HOME/.dot_files"

NVIM_TARGET="$HOME/.config/nvim"
TMUX_TARGET="$HOME/.config/tmux"
GHOSTTY_TARGET="$HOME/.config/ghostty"
BLERC_TARGET="$HOME/.config/blesh/init.sh"

CRON_COMMENT="# dotfiles auto update"
CRON_JOB="0 8 * * * $DEST_DIR/bash/update_dotfiles.sh >/dev/null 2>&1"

IN_CONTAINER=false
[ -f /.dockerenv ] && IN_CONTAINER=true

# --dry-run: read-only checks still run (installed versions, latest release
# tags, what is already linked), but every change is printed instead of made.
DRY_RUN=false
for arg in "$@"; do
    [ "$arg" = "--dry-run" ] && DRY_RUN=true
done

dry() { [ "$DRY_RUN" = true ]; }

run() {
    if dry; then
        echo "[dry-run] $*"
    else
        "$@"
    fi
}

# Success message for a change; silent in dry-run, where run already printed it.
did() { dry || echo "$@"; }

# ---------------------------------------------------------------------------
# Profile — "personal" installs everything as-is. "shared" is for an
# account/machine used by other people too, and skips the bits they tend not
# to want opted into for them on your behalf: ble.sh and fzf hijacking Tab
# and Ctrl+R (bash/bindings.sh — laptop-only), `tmux` launching your session
# picker by default (bash/alias.sh — use `tmux-jsaez` instead), and the
# WM/GNOME changes below (Ctrl+Alt+T override, xbindkeys autostart, Ghostty
# as default terminal). nvim and tmux configs are still installed as the
# default in both profiles.
#
# The profile defaults to "shared" on NVIDIA Jetson boards (which are used by
# the whole team) and to "personal" everywhere else, without prompting. The
# choice is saved to PROFILE_FILE so re-running the script (e.g. the container
# auto-setup hook in ~/.bash_aliases_local) keeps it; pass
# --profile=personal|shared explicitly to change it later.
# ---------------------------------------------------------------------------

PROFILE_FILE="$HOME/.dotfiles_profile"
PROFILE=""

_is_jetson() {
    [ -f /etc/nv_tegra_release ] || grep -qa tegra /proc/device-tree/compatible 2>/dev/null
}

while [ $# -gt 0 ]; do
    case "$1" in
        --profile=*) PROFILE="${1#*=}" ;;
        --profile) PROFILE="${2:-}"; shift ;;   # also accept `--profile shared`
        --personal) PROFILE="personal" ;;
        --shared) PROFILE="shared" ;;
    esac
    shift
done

if [ -z "$PROFILE" ] && [ -f "$PROFILE_FILE" ]; then
    PROFILE=$(cat "$PROFILE_FILE")
fi

if [ -z "$PROFILE" ]; then
    if [ "$IN_CONTAINER" = false ] && _is_jetson; then
        echo "Jetson board detected — defaulting to the 'shared' profile. Pass --profile=personal to override."
        PROFILE="shared"
    else
        PROFILE="personal"
    fi
fi

case "$PROFILE" in
    personal|shared) ;;
    *)
        echo "ERROR: unknown profile '$PROFILE' (expected 'personal' or 'shared')" >&2
        exit 1
        ;;
esac

if dry; then
    echo "[dry-run] write '$PROFILE' to $PROFILE_FILE"
else
    echo "$PROFILE" > "$PROFILE_FILE"
fi
echo "Using profile: $PROFILE (saved to $PROFILE_FILE — re-run with --profile=personal|shared to change)"

# ---------------------------------------------------------------------------
# Optional components — ask (fzf) whether to install tmux, then nvim.
# Falls back to a y/n prompt without fzf, and to "yes" when not interactive
# (e.g. the container auto-run) so unattended runs behave as before.
# Skipping a component leaves any existing install/config untouched.
# ---------------------------------------------------------------------------

ask_install() {
    local name="$1" choice
    if [ -t 0 ] && [ -t 1 ] && command -v fzf &>/dev/null; then
        # Esc / Ctrl-C makes fzf fail: treat as "No".
        choice=$(printf 'Yes\nNo\n' | fzf --reverse --height 20% \
            --header "Install $name? (Enter to select, Esc = No)") || choice=No
        [ "$choice" = Yes ]
    elif [ -t 0 ]; then
        local answer
        read -r -p "Install $name? (y/n): " answer
        [ "$answer" = y ] || [ "$answer" = Y ]
    else
        return 0
    fi
}

INSTALL_TMUX=false
INSTALL_NVIM=false
ask_install tmux && INSTALL_TMUX=true
ask_install nvim && INSTALL_NVIM=true
echo "Install tmux: $INSTALL_TMUX, nvim: $INSTALL_NVIM"

# ---------------------------------------------------------------------------
# Repo
# ---------------------------------------------------------------------------

if [ ! -d "$DEST_DIR" ]; then
    echo "Cloning dotfiles repo..."
    run git clone "$REPO_URL" "$DEST_DIR"
else
    echo "Dotfiles repo already exists at $DEST_DIR"
fi

# ---------------------------------------------------------------------------
# Symlinks
# ---------------------------------------------------------------------------

# Installs only the packages that are missing, and refreshes the apt index
# at most once per run (and not at all when everything is already present).
APT_UPDATED=false
apt_install() {
    local missing=() pkg
    for pkg in "$@"; do
        dpkg -s "$pkg" &>/dev/null || missing+=("$pkg")
    done
    [ ${#missing[@]} -eq 0 ] && return 0
    if [ "$APT_UPDATED" = false ]; then
        run sudo apt-get update
        APT_UPDATED=true
    fi
    run sudo apt-get install -y "${missing[@]}"
}

# Prints the latest release tag of a GitHub repo. Uses the /releases/latest
# redirect, which is not subject to the anonymous API rate limit.
latest_release_tag() {
    curl -fsSL --retry 3 --retry-delay 2 -o /dev/null -w '%{url_effective}' \
        "https://github.com/$1/releases/latest" 2>/dev/null | sed 's#.*/tag/##'
}

# Points $2 at $1, doing nothing if it already is.
link_config() {
    if [ "$(readlink "$2")" = "$1" ]; then
        echo "Already linked $2 -> $1"
        return
    fi
    if [ -L "$2" ] || [ -e "$2" ]; then
        echo "Removing existing $2"
        run rm -rf "$2"
    fi
    run ln -s "$1" "$2"
    did "Linked $2 -> $1"
}

# ~/.config is guaranteed to exist; create it if running inside a container
# where the directory may not have been provisioned by Ansible.
run mkdir -p "$HOME/.config"

# ble.sh (and its blerc) is laptop-only — see the Profile section above.
if [ "$PROFILE" = personal ]; then
    run mkdir -p "$(dirname "$BLERC_TARGET")"
    [ -L "$BLERC_TARGET" ] || [ -e "$BLERC_TARGET" ] && run rm -f "$BLERC_TARGET"
    run ln -sf "$DEST_DIR/bash/blerc" "$BLERC_TARGET"
    did "Linked $BLERC_TARGET -> $DEST_DIR/bash/blerc"
fi

if [ "$INSTALL_NVIM" = true ]; then link_config "$DEST_DIR/nvim" "$NVIM_TARGET"; fi
if [ "$INSTALL_TMUX" = true ]; then link_config "$DEST_DIR/tmux" "$TMUX_TARGET"; fi

# Ghostty is a host-only terminal emulator; skip the symlink inside containers.
if [ "$IN_CONTAINER" = false ]; then
    link_config "$DEST_DIR/ghostty" "$GHOSTTY_TARGET"

    # Ghostty's `maximize = true` config is ignored at startup on Linux/GTK
    # (https://github.com/ghostty-org/ghostty/issues/11252), so new windows
    # are maximized externally via a wrapper script + a launcher override.
    run mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
    run chmod +x "$DEST_DIR/ghostty/ghostty-maximized"
    run ln -sf "$DEST_DIR/ghostty/ghostty-maximized" "$HOME/.local/bin/ghostty-maximized"
    if dry; then
        echo "[dry-run] write Ghostty launcher to $HOME/.local/share/applications/com.mitchellh.ghostty.desktop"
    else
        sed "s|@GHOSTTY_MAXIMIZED@|$HOME/.local/bin/ghostty-maximized|g" \
            "$DEST_DIR/ghostty/ghostty.desktop" > "$HOME/.local/share/applications/com.mitchellh.ghostty.desktop"
    fi
    did "Installed maximized Ghostty launcher -> $HOME/.local/share/applications/com.mitchellh.ghostty.desktop"

    # GNOME's built-in Ctrl+Alt+T "Launch Terminal" shortcut bypasses the
    # .desktop file entirely and execs org.gnome.desktop.default-applications
    # .terminal directly, so it needs to be pointed at the wrapper too.
    # Skipped on "shared" profiles: this is a GNOME-session-wide default that
    # would repoint Ctrl+Alt+T for anyone else using this account too.
    if [ "$PROFILE" = personal ] && command -v gsettings &>/dev/null; then
        run gsettings set org.gnome.desktop.default-applications.terminal exec "$HOME/.local/bin/ghostty-maximized"
        did "Pointed GNOME's default terminal (Ctrl+Alt+T) at ghostty-maximized"
    fi
fi

# ---------------------------------------------------------------------------
# wm — Right Alt+1 / Right Alt+2 raise-or-launch Ghostty / Chrome.
#
# GNOME's built-in custom-keybinding accelerator format has no name for Mod5
# (Right Alt is bound to ISO_Level3_Shift/Mod5 on this keyboard layout,
# distinct from Left Alt/Mod1), so xbindkeys is used instead to grab the
# raw modifier directly.
#
# Skipped entirely on "shared" profiles: xbindkeys autostarts and grabs
# these key combos session-wide, which would affect anyone else using this
# account, not just you.
# ---------------------------------------------------------------------------

if [ "$IN_CONTAINER" = false ] && [ "$PROFILE" = personal ]; then
    apt_install xbindkeys

    run mkdir -p "$HOME/.local/bin" "$HOME/.config/autostart"
    run chmod +x "$DEST_DIR/wm/raise-or-launch.sh"
    run ln -sf "$DEST_DIR/wm/raise-or-launch.sh" "$HOME/.local/bin/raise-or-launch"

    if dry; then
        echo "[dry-run] write $HOME/.xbindkeysrc and $HOME/.config/autostart/xbindkeys.desktop"
    else
        sed \
            -e "s|@RAISE_OR_LAUNCH@|$HOME/.local/bin/raise-or-launch|g" \
            -e "s|@GHOSTTY_MAXIMIZED@|$HOME/.local/bin/ghostty-maximized|g" \
            "$DEST_DIR/wm/xbindkeysrc" > "$HOME/.xbindkeysrc"
        echo "Installed $HOME/.xbindkeysrc"

        cat > "$HOME/.config/autostart/xbindkeys.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=xbindkeys
Comment=Custom X11 keybindings (managed by ~/.dot_files/wm)
Exec=xbindkeys -n
X-GNOME-Autostart-enabled=true
EOF
        echo "Installed $HOME/.config/autostart/xbindkeys.desktop"
    fi

    if command -v xbindkeys &>/dev/null && [ -n "${DISPLAY:-}" ]; then
        run killall xbindkeys 2>/dev/null
        run xbindkeys
        did "Restarted xbindkeys with the new config"
    fi
fi

# ---------------------------------------------------------------------------
# nvim — always install the latest GitHub release (both profiles), from the
# prebuilt release binary rather than compiling from source. Simpler and
# much faster than a from-source build; unlike tmux, nvim publishes an
# official prebuilt binary per architecture, so there's no glibc/toolchain
# concern to trade off against the compile time.
# ---------------------------------------------------------------------------

_install_nvim() {
    local arch
    arch=$(uname -m)
    local nvim_tarball

    case "$arch" in
        x86_64)  nvim_tarball="nvim-linux-x86_64.tar.gz" ;;
        aarch64) nvim_tarball="nvim-linux-arm64.tar.gz" ;;
        *)
            echo "Unsupported architecture: $arch. Install nvim manually."
            return 1
            ;;
    esac

    local url="https://github.com/neovim/neovim/releases/latest/download/$nvim_tarball"
    local tmp_dir
    tmp_dir=$(mktemp -d)

    echo "Downloading nvim ($arch) from GitHub releases..."
    # Avoid set-e aborting before we can clean up tmp_dir on failure.
    if curl -fL --retry 3 --retry-delay 2 --retry-connrefused "$url" -o "$tmp_dir/nvim.tar.gz"; then
        # Install to ~/.local so no sudo is required; ~/.local/bin is on PATH
        # via ~/.bash_aliases_local (and via the team bashrc on the host).
        mkdir -p "$HOME/.local"
        tar -C "$HOME/.local" --strip-components=1 -xzf "$tmp_dir/nvim.tar.gz"
        echo "nvim installed to $HOME/.local/bin/nvim"
    else
        echo "ERROR: failed to download nvim." >&2
        rm -rf "$tmp_dir"
        return 1
    fi
    rm -rf "$tmp_dir"
}

NVIM_LOCAL_BIN="$HOME/.local/bin/nvim"
NVIM_LATEST_TAG=$(latest_release_tag neovim/neovim)
if [ "$INSTALL_NVIM" = false ]; then
    echo "Skipping nvim install"
elif [ -x "$NVIM_LOCAL_BIN" ] && [ -n "$NVIM_LATEST_TAG" ] \
    && [ "$("$NVIM_LOCAL_BIN" --version | head -1)" = "NVIM $NVIM_LATEST_TAG" ]; then
    echo "nvim already up to date ($NVIM_LATEST_TAG)"
else
    echo "Installing latest nvim release from GitHub..."
    run _install_nvim
fi

# ---------------------------------------------------------------------------
# tmux — built from source (both profiles), always rebuilt against the latest
# GitHub release (tmux has no moving "stable" tag/branch like neovim, so the
# latest release tag is resolved via the GitHub API instead). Uses the
# release tarball (not a raw git clone) because it ships a pre-generated
# `configure`, avoiding an autoconf/automake/pkg-config dependency.
# ---------------------------------------------------------------------------

# bison provides yacc, which configure hard-requires to (re)generate the
# cmd-parse.y grammar -- missing on machines that never had other build
# tooling installed on them before (confirmed failure: "configure: error:
# 'yacc not found'" on a bare shared machine).
TMUX_BUILD_DEPS=(libevent-dev libncurses-dev pkg-config build-essential bison)

_install_tmux() {
    local tmp_dir tarball_url
    tmp_dir=$(mktemp -d)

    echo "Resolving latest tmux release..."
    # The /releases/latest redirect is not subject to the 60 req/h anonymous
    # API limit (a shared IP hit "403" there); the API is only the fallback.
    local tag
    tag=$(latest_release_tag tmux/tmux)
    if [ -n "$tag" ] && [[ $tag != *"/"* ]]; then
        tarball_url="https://github.com/tmux/tmux/releases/download/$tag/tmux-$tag.tar.gz"
    else
        tarball_url=$(curl -fsSL --retry 3 --retry-delay 2 --retry-connrefused \
            https://api.github.com/repos/tmux/tmux/releases/latest \
            | python3 -c "import json,sys; d=json.load(sys.stdin); print(next(a['browser_download_url'] for a in d['assets'] if a['name'].endswith('.tar.gz')))" 2>/dev/null)
    fi

    if [ -z "$tarball_url" ]; then
        echo "ERROR: could not resolve latest tmux release tarball." >&2
        rm -rf "$tmp_dir"
        return 1
    fi

    echo "Installing tmux build dependencies..."
    apt_install "${TMUX_BUILD_DEPS[@]}"

    echo "Downloading tmux source ($tarball_url)..."
    if curl -fL --retry 3 --retry-delay 2 --retry-connrefused "$tarball_url" -o "$tmp_dir/tmux.tar.gz"; then
        tar -C "$tmp_dir" --strip-components=1 -xzf "$tmp_dir/tmux.tar.gz"
        echo "Building tmux from source..."
        (cd "$tmp_dir" && ./configure --prefix="$HOME/.local" && make -j"$(nproc)" && make install)
        echo "tmux installed to $HOME/.local/bin/tmux"
    else
        echo "ERROR: failed to download tmux." >&2
        rm -rf "$tmp_dir"
        return 1
    fi
    rm -rf "$tmp_dir"
}

TMUX_LOCAL_BIN="$HOME/.local/bin/tmux"
TMUX_LATEST_TAG=$(latest_release_tag tmux/tmux)
if [ "$INSTALL_TMUX" = false ]; then
    echo "Skipping tmux install"
elif [ -x "$TMUX_LOCAL_BIN" ] && [ -n "$TMUX_LATEST_TAG" ] \
    && [ "$("$TMUX_LOCAL_BIN" -V)" = "tmux $TMUX_LATEST_TAG" ]; then
    echo "tmux already up to date ($TMUX_LATEST_TAG)"
else
    echo "Building latest tmux from source..."
    # Not fatal: set -e would otherwise skip every later setup step.
    run _install_tmux || echo "WARNING: tmux install failed; keeping the existing tmux." >&2
fi

# ---------------------------------------------------------------------------
# Node.js — install via nvm if not already present (needed for LSP servers
# such as pyright and dockerfile-language-server)
# ---------------------------------------------------------------------------

NVM_DIR="$HOME/.nvm"

_install_node() {
    echo "Installing nvm..."
    curl -fsSL --retry 3 --retry-delay 2 --retry-connrefused https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    echo "Installing Node.js LTS via nvm..."
    nvm install --lts
    nvm use --lts
    echo "Node.js installed: $(node --version)"
}

# Source nvm if already installed but not yet on PATH in this session
if [ -s "$NVM_DIR/nvm.sh" ] && ! command -v node &>/dev/null; then
    \. "$NVM_DIR/nvm.sh"
fi

if command -v node &>/dev/null; then
    echo "node already installed: $(node --version)"
else
    echo "node not found — installing via nvm..."
    run _install_node
fi

# ---------------------------------------------------------------------------
# tree-sitter-cli — nvim-treesitter requirement, installed via npm.
# Node must already be on PATH at this point.
# ---------------------------------------------------------------------------

# Re-source nvm in case _install_node just ran and npm isn't on PATH yet.
if [ -s "$NVM_DIR/nvm.sh" ] && ! command -v npm &>/dev/null; then
    \. "$NVM_DIR/nvm.sh"
fi

if command -v tree-sitter &>/dev/null; then
    echo "tree-sitter-cli already installed"
elif command -v npm &>/dev/null; then
    echo "Installing tree-sitter-cli..."
    run npm install -g tree-sitter-cli
else
    echo "WARNING: npm not available — skipping tree-sitter-cli"
fi

# ---------------------------------------------------------------------------
# ripgrep — fast search tool used by nvim and shell
# ---------------------------------------------------------------------------

if command -v rg &>/dev/null; then
    echo "ripgrep already installed: $(rg --version | head -1)"
else
    echo "ripgrep not found — installing latest stable version..."
    apt_install ripgrep
fi

# ---------------------------------------------------------------------------
# bash-completion — completion data for 200+ commands (git, docker, etc.)
# ---------------------------------------------------------------------------

apt_install bash-completion

# ---------------------------------------------------------------------------
# python3-venv — mason.nvim installs pip-based tools (black, clang-format,
# debugpy) into their own venvs, which fails without it.
# ---------------------------------------------------------------------------

apt_install python3-venv

# ---------------------------------------------------------------------------
# fzf-tab-completion — battle-tested fzf-powered tab completion for bash
# ---------------------------------------------------------------------------

FZF_TAB_COMPLETION_DIR="$DEST_DIR/bash/fzf-tab-completion"

if [ -d "$FZF_TAB_COMPLETION_DIR" ]; then
    # As a submodule it sits on a detached HEAD pinned by the parent repo (and
    # carries a local patch), so `git pull` has nothing to follow: leave it to
    # `git submodule update`. Never fatal — set -e would abort the whole setup.
    if git -C "$FZF_TAB_COMPLETION_DIR" symbolic-ref -q HEAD &>/dev/null; then
        echo "Updating fzf-tab-completion..."
        run git -C "$FZF_TAB_COMPLETION_DIR" pull --ff-only \
            || echo "WARNING: fzf-tab-completion update failed; keeping the current version." >&2
    else
        echo "fzf-tab-completion is pinned by the dotfiles repo (detached HEAD); skipping update"
    fi
else
    echo "Cloning fzf-tab-completion..."
    run git clone https://github.com/lincheney/fzf-tab-completion "$FZF_TAB_COMPLETION_DIR"
fi

# ---------------------------------------------------------------------------
# ble.sh — bash line editor: ghost text, syntax highlighting, completion UI.
# Laptop-only (see the Profile section above) — it changes the shell's look
# and default keybindings for anyone using the account, not just you.
# ---------------------------------------------------------------------------

BLE_SH_DIR="$DEST_DIR/bash/ble.sh"

_install_blesh() {
    apt_install gawk
    if [ -d "$BLE_SH_DIR" ]; then
        # Already checked out -- e.g. ~/.dot_files is bind-mounted from the
        # host into a devcontainer, where it's already cloned there. `git
        # clone` into a non-empty directory fails, so update in place
        # instead of cloning over it.
        echo "ble.sh checkout already present at $BLE_SH_DIR — updating..."
        git -C "$BLE_SH_DIR" pull --ff-only
        git -C "$BLE_SH_DIR" submodule update --init --recursive
    else
        echo "Cloning ble.sh..."
        git clone --recursive https://github.com/akinomyoga/ble.sh "$BLE_SH_DIR"
    fi
    echo "Building and installing ble.sh..."
    make -C "$BLE_SH_DIR" install PREFIX="$HOME/.local"
    echo "ble.sh installed to $HOME/.local/share/blesh/"
}

if [ "$PROFILE" = personal ]; then
    if [ -f "$HOME/.local/share/blesh/ble.sh" ]; then
        echo "ble.sh already installed"
        if dry; then
            echo "[dry-run] would pull ble.sh updates and rebuild if anything changed"
        elif [ -d "$BLE_SH_DIR" ]; then
            echo "Pulling ble.sh updates..."
            ble_before=$(git -C "$BLE_SH_DIR" rev-parse HEAD)
            git -C "$BLE_SH_DIR" pull --ff-only
            if [ "$(git -C "$BLE_SH_DIR" rev-parse HEAD)" != "$ble_before" ]; then
                git -C "$BLE_SH_DIR" submodule update --init --recursive
                make -C "$BLE_SH_DIR" install PREFIX="$HOME/.local"
            else
                echo "ble.sh already up to date"
            fi
        fi
    else
        run _install_blesh
    fi
fi

# ---------------------------------------------------------------------------
# ghostty — GPU-accelerated terminal emulator (host only, built from source)
# ---------------------------------------------------------------------------

_install_ghostty() {
    local version="1.3.1"
    local zig_version="0.15.2"
    local arch
    arch=$(uname -m)
    local tmp_dir
    tmp_dir=$(mktemp -d)

    echo "Installing ghostty dependencies..."
    apt_install libgtk-4-dev libadwaita-1-dev gettext libxml2-utils

    # gtk4-layer-shell is not packaged for Ubuntu 24.04, so we build it from source
    # by passing -fno-sys=gtk4-layer-shell to zig build

    echo "Installing Zig $zig_version..."
    local zig_tarball="zig-linux-${arch}-${zig_version}.tar.xz"
    local zig_url="https://ziglang.org/download/${zig_version}/${zig_tarball}"
    curl -fL --retry 3 --retry-delay 2 --retry-connrefused "$zig_url" -o "$tmp_dir/$zig_tarball"
    tar -xf "$tmp_dir/$zig_tarball" -C "$tmp_dir"
    local zig_bin="$tmp_dir/zig-linux-${arch}-${zig_version}/zig"

    echo "Downloading ghostty $version source tarball..."
    local src_url="https://release.files.ghostty.org/${version}/ghostty-${version}.tar.gz"
    curl -fL --retry 3 --retry-delay 2 --retry-connrefused "$src_url" -o "$tmp_dir/ghostty.tar.gz"
    tar -xf "$tmp_dir/ghostty.tar.gz" -C "$tmp_dir"

    echo "Building ghostty (this will take a few minutes)..."
    cd "$tmp_dir/ghostty-${version}"
    "$zig_bin" build -p "$HOME/.local" -Doptimize=ReleaseFast -fno-sys=gtk4-layer-shell

    cd "$HOME"
    rm -rf "$tmp_dir"
    echo "ghostty installed: $(ghostty --version)"
}

if [ "$IN_CONTAINER" = false ]; then
    if command -v ghostty &>/dev/null; then
        echo "ghostty already installed: $(ghostty --version)"
    else
        echo "ghostty not found — building from source..."
        run _install_ghostty
    fi
fi

# ---------------------------------------------------------------------------
# snacks.nvim — remove stale lock-file pin so Lazy fetches a version that
# includes the fix for the 'fg' nil healthcheck error.
# ---------------------------------------------------------------------------

LAZY_LOCK="$DEST_DIR/nvim/lazy-lock.json"
if [ "$INSTALL_NVIM" = false ]; then
    :
elif dry; then
    echo "[dry-run] would remove the snacks.nvim pin from $LAZY_LOCK"
elif [ -f "$LAZY_LOCK" ] && command -v python3 &>/dev/null; then
    python3 -c "
import json
path = '$LAZY_LOCK'
with open(path) as f:
    lock = json.load(f)
if 'snacks.nvim' in lock:
    del lock['snacks.nvim']
    with open(path, 'w') as f:
        json.dump(lock, f, indent=2)
        f.write('\n')
    print('Removed snacks.nvim pin — Lazy will fetch latest on next nvim start')
else:
    print('snacks.nvim already unpinned')
"
fi

# ---------------------------------------------------------------------------
# Pre-install nvim plugins (both profiles) so the first interactive nvim start
# isn't spent waiting on lazy.nvim. `Lazy! install` only clones missing plugins
# (no updates), so it's a fast no-op on re-runs and doesn't touch lazy-lock.json.
# Failure here is non-fatal: lazy will just install on first launch instead.
# ---------------------------------------------------------------------------

if [ "$INSTALL_NVIM" = false ]; then
    :
elif dry; then
    echo "[dry-run] would pre-install nvim plugins (lazy.nvim)"
elif [ -x "$NVIM_LOCAL_BIN" ]; then
    echo "Pre-installing nvim plugins (lazy.nvim)..."
    if timeout 600 "$NVIM_LOCAL_BIN" --headless "+Lazy! install" +qa; then
        echo "nvim plugins installed."
    else
        echo "WARNING: headless plugin install failed — lazy.nvim will retry on first nvim start." >&2
    fi
fi

# ---------------------------------------------------------------------------
# ~/.bash_aliases_local — personal shell customisations
# ---------------------------------------------------------------------------

# We write to ~/.bash_aliases_local (not ~/.bashrc) because ~/.bashrc is
# managed by devi-provision (Ansible) and gets overwritten on each run, while
# ~/.bash_aliases_local is explicitly sourced by the team bashrc and is never
# touched by Ansible.
#
# Line order matters:
#   1. PATH fix — must come first so nvim (installed to ~/.local/bin) is
#      reachable in the same session.  Uses $HOME, not $USER, because Docker
#      sets $HOME but often leaves $USER unset.
#   2. dotfiles_profile.sh — must come before alias.sh/bindings.sh, which
#      read $DOTFILES_PROFILE to decide what to wire up.
#   3. Personal aliases / bindings.
#   4. Container auto-setup — runs this script on first entry into a container
#      where ~/.dot_files is mounted but symlinks don't exist yet.
BASHRC="$HOME/.bash_aliases_local"

# Remove old inline venv lines superseded by container_venv.sh
REMOVE_LINES=(
    "[ -f /.dockerenv ] && [ ! -d \"\$HOME/.venv\" ] && python3 -m venv \"\$HOME/.venv\""
    "[ -f /.dockerenv ] && [ -f \"\$HOME/.venv/bin/activate\" ] && source \"\$HOME/.venv/bin/activate\""
    "case :\$PATH: in *:/usr/local/go/bin:*) ;; *) export PATH=\"\$PATH:/usr/local/go/bin\" ;; esac"
    # container_venv.sh (auto-created ~/.venv) removed — it broke other
    # tooling inside the container (system-site-packages venv shadowing
    # things that expect the system Python).
    "[ -f /.dockerenv ] && [ -f \"\$HOME/.dot_files/bash/container_venv.sh\" ] && source \"\$HOME/.dot_files/bash/container_venv.sh\""
    # devi-activate isn't defined yet at this point in ~/.bashrc (devi_toolkit.bashrc
    # is sourced later), so the direct call was always a silent no-op — superseded by
    # the PROMPT_COMMAND-deferred call in devi_activate.sh.
    "[ -f /.dockerenv ] && command -v devi-activate &>/dev/null && devi-activate"
)
for line in "${REMOVE_LINES[@]}"; do
    if grep -Fxq "$line" "$BASHRC" 2>/dev/null; then
        # $BASHRC may be bind-mounted into the container as an individual
        # file (see bash_mount in devi_toolkit.bashrc), in which case `mv`
        # over it fails with "Device or resource busy" -- rename(2) can't
        # replace an active mount point. Write into the existing inode
        # instead of replacing it.
        if dry; then
            echo "[dry-run] remove from $BASHRC: $line"
        else
            grep -Fxv "$line" "$BASHRC" > "${BASHRC}.tmp" && cat "${BASHRC}.tmp" > "$BASHRC" && rm -f "${BASHRC}.tmp"
            echo "Removed from $BASHRC: $line"
        fi
    fi
done

SOURCE_LINES=(
    "case :\$PATH: in *:\$HOME/.local/bin:*) ;; *) export PATH=\"\$HOME/.local/bin:\$PATH\" ;; esac"
    "case :\$PATH: in *:/usr/local/go/bin:*) ;; *) export PATH=\"/usr/local/go/bin:\$PATH\" ;; esac"
    "export TMUX_CONF_DIR=\"\$HOME/.dot_files/tmux\""
    "[ -s \"\$HOME/.nvm/nvm.sh\" ] && \\. \"\$HOME/.nvm/nvm.sh\""
    "[ -f /.dockerenv ] && export TERM=xterm-256color"
    "[ -f /.dockerenv ] && [ -f \"\$HOME/.dot_files/bash/devi_activate.sh\" ] && source \"\$HOME/.dot_files/bash/devi_activate.sh\""
    "source \$HOME/.dot_files/bash/dotfiles_profile.sh"
    "source \$HOME/.dot_files/bash/alias.sh"
    "source \$HOME/.dot_files/bash/ros2_completion.sh"
    "source \$HOME/.dot_files/bash/bindings.sh"
    "[ -f /.dockerenv ] || source \"\$HOME/.dot_files/bash/docker_wrapper.sh\""
    "[ -f /.dockerenv ] && [ -d \"\$HOME/.dot_files\" ] && [ ! -L \"\$HOME/.config/nvim\" ] && bash \"\$HOME/.dot_files/bash/setup_dotfiles.sh\""
)

for line in "${SOURCE_LINES[@]}"; do
    if ! grep -Fxq "$line" "$BASHRC" 2>/dev/null; then
        if dry; then
            echo "[dry-run] add to $BASHRC: $line"
        else
            echo "$line" >> "$BASHRC"
            echo "Added to $BASHRC: $line"
        fi
    else
        echo "Already in $BASHRC: $line"
    fi
done

# ---------------------------------------------------------------------------
# ssd-bags-symlink — relink ~/indoor_uav/bags to the javier_ssd's bags folder
# whenever the SSD is mounted (systemd --user timer, host only — no
# automount events to poll for inside a container).
# ---------------------------------------------------------------------------

if [ "$IN_CONTAINER" = false ]; then
    run chmod +x "$DEST_DIR/bash/link_ssd_bags.sh"
    run mkdir -p "$HOME/.config/systemd/user"
    run ln -sf "$DEST_DIR/systemd/ssd-bags-symlink.timer" "$HOME/.config/systemd/user/ssd-bags-symlink.timer"
    run ln -sf "$DEST_DIR/systemd/ssd-bags-symlink.service" "$HOME/.config/systemd/user/ssd-bags-symlink.service"
    run systemctl --user daemon-reload
    run systemctl --user enable --now ssd-bags-symlink.timer
    did "Enabled ssd-bags-symlink.timer — ~/indoor_uav/bags will auto-relink to the SSD within ~20s of javier_ssd being mounted."
fi

# ---------------------------------------------------------------------------
# Cron (host only — cron daemons are not available inside containers)
# ---------------------------------------------------------------------------

if [ "$IN_CONTAINER" = false ]; then
    if dry; then
        echo "[dry-run] install cron job: $CRON_JOB"
    else
        (crontab -l 2>/dev/null | grep -v -F "$CRON_COMMENT" || true; echo "$CRON_COMMENT"; echo "$CRON_JOB") | crontab -
    fi
    did "Cron job installed to update dotfiles daily at 8 AM."
fi

if dry; then
    echo "Dry run complete — nothing was changed."
else
    echo "Setup complete! Please restart your terminal or run: source ~/.bashrc"
fi
