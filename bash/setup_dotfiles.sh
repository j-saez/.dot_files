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
# The choice is saved to PROFILE_FILE so re-running the script (e.g. the
# container auto-setup hook in ~/.bash_aliases_local) doesn't re-prompt; pass
# --profile=personal|shared explicitly to change it later.
# ---------------------------------------------------------------------------

PROFILE_FILE="$HOME/.dotfiles_profile"
PROFILE=""
PROFILE_DESC_PERSONAL="your own machine — install everything"
PROFILE_DESC_SHARED="an account/computer other people use too (skips ble.sh, fzf Tab/Ctrl+R, the tmux picker default, and the WM/GNOME shortcut changes)"

for arg in "$@"; do
    case "$arg" in
        --profile=*) PROFILE="${arg#*=}" ;;
        --personal) PROFILE="personal" ;;
        --shared) PROFILE="shared" ;;
    esac
done

if [ -z "$PROFILE" ] && [ -f "$PROFILE_FILE" ]; then
    PROFILE=$(cat "$PROFILE_FILE")
fi

if [ -z "$PROFILE" ]; then
    if [ -t 0 ] && command -v fzf &>/dev/null; then
        PROFILE=$(printf '%s\n' \
            "personal   $PROFILE_DESC_PERSONAL" \
            "shared     $PROFILE_DESC_SHARED" \
            | fzf --reverse --header "Select install profile (Esc = personal):" --bind 'ctrl-j:down,ctrl-k:up' \
            | awk '{print $1}') || true
        [ -z "$PROFILE" ] && PROFILE="personal"
    elif [ -t 0 ]; then
        echo "Which install profile is this machine?"
        echo "  1) personal — $PROFILE_DESC_PERSONAL"
        echo "  2) shared   — $PROFILE_DESC_SHARED"
        read -rp "Select [1/2, default 1]: " _profile_choice || true
        case "$_profile_choice" in
            2) PROFILE="shared" ;;
            *) PROFILE="personal" ;;
        esac
    else
        echo "No --profile given and not running interactively — defaulting to 'personal'. Pass --profile=shared to opt into the shared-machine profile."
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

echo "$PROFILE" > "$PROFILE_FILE"
echo "Using profile: $PROFILE (saved to $PROFILE_FILE — re-run with --profile=personal|shared to change)"

# ---------------------------------------------------------------------------
# Repo
# ---------------------------------------------------------------------------

if [ ! -d "$DEST_DIR" ]; then
    echo "Cloning dotfiles repo..."
    git clone "$REPO_URL" "$DEST_DIR"
else
    echo "Dotfiles repo already exists at $DEST_DIR"
fi

# ---------------------------------------------------------------------------
# Symlinks
# ---------------------------------------------------------------------------

# ~/.config is guaranteed to exist; create it if running inside a container
# where the directory may not have been provisioned by Ansible.
mkdir -p "$HOME/.config"

# ble.sh (and its blerc) is laptop-only — see the Profile section above.
if [ "$PROFILE" = personal ]; then
    mkdir -p "$(dirname "$BLERC_TARGET")"
    [ -L "$BLERC_TARGET" ] || [ -e "$BLERC_TARGET" ] && rm -f "$BLERC_TARGET"
    ln -sf "$DEST_DIR/bash/blerc" "$BLERC_TARGET"
    echo "Linked $BLERC_TARGET -> $DEST_DIR/bash/blerc"
fi

if [ -L "$NVIM_TARGET" ] || [ -e "$NVIM_TARGET" ]; then
    echo "Removing existing $NVIM_TARGET"
    rm -rf "$NVIM_TARGET"
fi
ln -s "$DEST_DIR/nvim" "$NVIM_TARGET"
echo "Linked $NVIM_TARGET -> $DEST_DIR/nvim"

if [ -L "$TMUX_TARGET" ] || [ -e "$TMUX_TARGET" ]; then
    echo "Removing existing $TMUX_TARGET"
    rm -rf "$TMUX_TARGET"
fi
ln -s "$DEST_DIR/tmux" "$TMUX_TARGET"
echo "Linked $TMUX_TARGET -> $DEST_DIR/tmux"

# Ghostty is a host-only terminal emulator; skip the symlink inside containers.
if [ "$IN_CONTAINER" = false ]; then
    if [ -L "$GHOSTTY_TARGET" ] || [ -e "$GHOSTTY_TARGET" ]; then
        echo "Removing existing $GHOSTTY_TARGET"
        rm -rf "$GHOSTTY_TARGET"
    fi
    ln -s "$DEST_DIR/ghostty" "$GHOSTTY_TARGET"
    echo "Linked $GHOSTTY_TARGET -> $DEST_DIR/ghostty"

    # Ghostty's `maximize = true` config is ignored at startup on Linux/GTK
    # (https://github.com/ghostty-org/ghostty/issues/11252), so new windows
    # are maximized externally via a wrapper script + a launcher override.
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
    chmod +x "$DEST_DIR/ghostty/ghostty-maximized"
    ln -sf "$DEST_DIR/ghostty/ghostty-maximized" "$HOME/.local/bin/ghostty-maximized"
    sed "s|@GHOSTTY_MAXIMIZED@|$HOME/.local/bin/ghostty-maximized|g" \
        "$DEST_DIR/ghostty/ghostty.desktop" > "$HOME/.local/share/applications/com.mitchellh.ghostty.desktop"
    echo "Installed maximized Ghostty launcher -> $HOME/.local/share/applications/com.mitchellh.ghostty.desktop"

    # GNOME's built-in Ctrl+Alt+T "Launch Terminal" shortcut bypasses the
    # .desktop file entirely and execs org.gnome.desktop.default-applications
    # .terminal directly, so it needs to be pointed at the wrapper too.
    # Skipped on "shared" profiles: this is a GNOME-session-wide default that
    # would repoint Ctrl+Alt+T for anyone else using this account too.
    if [ "$PROFILE" = personal ] && command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.default-applications.terminal exec "$HOME/.local/bin/ghostty-maximized"
        echo "Pointed GNOME's default terminal (Ctrl+Alt+T) at ghostty-maximized"
    fi
fi

# ---------------------------------------------------------------------------
# apt — refresh the package index once so the `apt install` calls below can
# find packages (container images ship with an empty/stale index to keep
# them small, e.g. the "Unable to locate package" errors this used to hit).
# ---------------------------------------------------------------------------

sudo apt-get update

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
    if command -v xbindkeys &>/dev/null; then
        echo "xbindkeys already installed"
    else
        echo "xbindkeys not found — installing..."
        sudo apt install -y xbindkeys
    fi

    mkdir -p "$HOME/.local/bin" "$HOME/.config/autostart"
    chmod +x "$DEST_DIR/wm/raise-or-launch.sh"
    ln -sf "$DEST_DIR/wm/raise-or-launch.sh" "$HOME/.local/bin/raise-or-launch"

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

    if command -v xbindkeys &>/dev/null && [ -n "${DISPLAY:-}" ]; then
        killall xbindkeys 2>/dev/null
        xbindkeys
        echo "Restarted xbindkeys with the new config"
    fi
fi

# ---------------------------------------------------------------------------
# nvim — built from source (both profiles), always rebuilt against upstream's
# `stable` branch (which GitHub/upstream always repoint at the latest stable
# release), same "always reinstall latest" policy the old prebuilt-tarball
# install had. Building from source instead of using the prebuilt release
# tarball avoids depending on whatever glibc those binaries were linked
# against, at the cost of a few minutes of compile time per run.
# ---------------------------------------------------------------------------

echo "Installing nvim build dependencies..."
sudo apt-get install -y ninja-build gettext cmake unzip curl build-essential

_install_nvim() {
    local tmp_dir
    tmp_dir=$(mktemp -d)

    echo "Cloning neovim (stable)..."
    if git clone --branch stable --depth 1 https://github.com/neovim/neovim "$tmp_dir"; then
        echo "Building nvim from source (this will take a few minutes)..."
        # Install to ~/.local so no sudo is required; ~/.local/bin is on PATH
        # via ~/.bash_aliases_local (and via the team bashrc on the host).
        make -C "$tmp_dir" CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$HOME/.local"
        make -C "$tmp_dir" install
        echo "nvim installed to $HOME/.local/bin/nvim"
    else
        echo "ERROR: failed to clone neovim." >&2
        rm -rf "$tmp_dir"
        return 1
    fi
    rm -rf "$tmp_dir"
}

NVIM_LOCAL_BIN="$HOME/.local/bin/nvim"
if [ -x "$NVIM_LOCAL_BIN" ]; then
    echo "nvim currently installed: $("$NVIM_LOCAL_BIN" --version | head -1)"
fi
echo "Building latest stable nvim from source..."
_install_nvim

# ---------------------------------------------------------------------------
# tmux — built from source (both profiles), always rebuilt against the latest
# GitHub release (tmux has no moving "stable" tag/branch like neovim, so the
# latest release tag is resolved via the GitHub API instead). Uses the
# release tarball (not a raw git clone) because it ships a pre-generated
# `configure`, avoiding an autoconf/automake/pkg-config dependency.
# ---------------------------------------------------------------------------

echo "Installing tmux build dependencies..."
sudo apt-get install -y libevent-dev libncurses-dev pkg-config build-essential

_install_tmux() {
    local tmp_dir tarball_url
    tmp_dir=$(mktemp -d)

    echo "Resolving latest tmux release..."
    tarball_url=$(curl -fsSL --retry 3 --retry-delay 2 --retry-connrefused \
        https://api.github.com/repos/tmux/tmux/releases/latest \
        | python3 -c "import json,sys; d=json.load(sys.stdin); print(next(a['browser_download_url'] for a in d['assets'] if a['name'].endswith('.tar.gz')))" 2>/dev/null)

    if [ -z "$tarball_url" ]; then
        echo "ERROR: could not resolve latest tmux release tarball." >&2
        rm -rf "$tmp_dir"
        return 1
    fi

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
if [ -x "$TMUX_LOCAL_BIN" ]; then
    echo "tmux currently installed: $("$TMUX_LOCAL_BIN" -V)"
fi
echo "Building latest tmux from source..."
_install_tmux

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
    _install_node
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
    npm install -g tree-sitter-cli
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
    sudo apt install ripgrep
fi

# ---------------------------------------------------------------------------
# bash-completion — completion data for 200+ commands (git, docker, etc.)
# ---------------------------------------------------------------------------

if dpkg -s bash-completion &>/dev/null 2>&1; then
    echo "bash-completion already installed"
else
    echo "Installing bash-completion..."
    sudo apt install -y bash-completion
fi

# ---------------------------------------------------------------------------
# python3-venv — mason.nvim installs pip-based tools (black, clang-format,
# debugpy) into their own venvs, which fails without it.
# ---------------------------------------------------------------------------

if dpkg -s python3-venv &>/dev/null 2>&1; then
    echo "python3-venv already installed"
else
    echo "Installing python3-venv..."
    sudo apt install -y python3-venv
fi

# ---------------------------------------------------------------------------
# fzf-tab-completion — battle-tested fzf-powered tab completion for bash
# ---------------------------------------------------------------------------

FZF_TAB_COMPLETION_DIR="$DEST_DIR/bash/fzf-tab-completion"

if [ -d "$FZF_TAB_COMPLETION_DIR" ]; then
    echo "Updating fzf-tab-completion..."
    git -C "$FZF_TAB_COMPLETION_DIR" pull --ff-only
else
    echo "Cloning fzf-tab-completion..."
    git clone https://github.com/lincheney/fzf-tab-completion "$FZF_TAB_COMPLETION_DIR"
fi

# ---------------------------------------------------------------------------
# ble.sh — bash line editor: ghost text, syntax highlighting, completion UI.
# Laptop-only (see the Profile section above) — it changes the shell's look
# and default keybindings for anyone using the account, not just you.
# ---------------------------------------------------------------------------

BLE_SH_DIR="$DEST_DIR/bash/ble.sh"

_install_blesh() {
    echo "Installing ble.sh build dependency: gawk..."
    sudo apt install -y gawk
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
        if [ -d "$BLE_SH_DIR" ]; then
            echo "Pulling ble.sh updates..."
            git -C "$BLE_SH_DIR" pull --ff-only
            git -C "$BLE_SH_DIR" submodule update --init --recursive
            make -C "$BLE_SH_DIR" install PREFIX="$HOME/.local"
        fi
    else
        _install_blesh
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
    sudo apt install -y \
        libgtk-4-dev \
        libadwaita-1-dev \
        gettext \
        libxml2-utils

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
        _install_ghostty
    fi
fi

# ---------------------------------------------------------------------------
# snacks.nvim — remove stale lock-file pin so Lazy fetches a version that
# includes the fix for the 'fg' nil healthcheck error.
# ---------------------------------------------------------------------------

LAZY_LOCK="$DEST_DIR/nvim/lazy-lock.json"
if [ -f "$LAZY_LOCK" ] && command -v python3 &>/dev/null; then
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
        grep -Fxv "$line" "$BASHRC" > "${BASHRC}.tmp" && cat "${BASHRC}.tmp" > "$BASHRC" && rm -f "${BASHRC}.tmp"
        echo "Removed from $BASHRC: $line"
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
    "[ -f /.dockerenv ] && [ -d \"\$HOME/.dot_files\" ] && [ ! -L \"\$HOME/.config/nvim\" ] && bash \"\$HOME/.dot_files/bash/setup_dotfiles.sh\""
)

for line in "${SOURCE_LINES[@]}"; do
    if ! grep -Fxq "$line" "$BASHRC" 2>/dev/null; then
        echo "$line" >> "$BASHRC"
        echo "Added to $BASHRC: $line"
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
    chmod +x "$DEST_DIR/bash/link_ssd_bags.sh"
    mkdir -p "$HOME/.config/systemd/user"
    ln -sf "$DEST_DIR/systemd/ssd-bags-symlink.timer" "$HOME/.config/systemd/user/ssd-bags-symlink.timer"
    ln -sf "$DEST_DIR/systemd/ssd-bags-symlink.service" "$HOME/.config/systemd/user/ssd-bags-symlink.service"
    systemctl --user daemon-reload
    systemctl --user enable --now ssd-bags-symlink.timer
    echo "Enabled ssd-bags-symlink.timer — ~/indoor_uav/bags will auto-relink to the SSD within ~20s of javier_ssd being mounted."
fi

# ---------------------------------------------------------------------------
# Cron (host only — cron daemons are not available inside containers)
# ---------------------------------------------------------------------------

if [ "$IN_CONTAINER" = false ]; then
    (crontab -l 2>/dev/null | grep -v -F "$CRON_COMMENT" || true; echo "$CRON_COMMENT"; echo "$CRON_JOB") | crontab -
    echo "Cron job installed to update dotfiles daily at 8 AM."
fi

# ---------------------------------------------------------------------------
# Patch devi_toolkit.bashrc to mount ~/.dot_files into the dev container
# ---------------------------------------------------------------------------

bash "$DEST_DIR/bash/tii-dev-scripts/patch_devi_toolkit.sh"

echo "Setup complete! Please restart your terminal or run: source ~/.bashrc"
