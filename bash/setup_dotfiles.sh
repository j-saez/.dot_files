#!/usr/bin/env bash

set -e

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

mkdir -p "$(dirname "$BLERC_TARGET")"
[ -L "$BLERC_TARGET" ] || [ -e "$BLERC_TARGET" ] && rm -f "$BLERC_TARGET"
ln -sf "$DEST_DIR/bash/blerc" "$BLERC_TARGET"
echo "Linked $BLERC_TARGET -> $DEST_DIR/bash/blerc"

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
    if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.default-applications.terminal exec "$HOME/.local/bin/ghostty-maximized"
        echo "Pointed GNOME's default terminal (Ctrl+Alt+T) at ghostty-maximized"
    fi
fi

# ---------------------------------------------------------------------------
# nvim — install latest stable if not already present
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
    if curl -fL "$url" -o "$tmp_dir/nvim.tar.gz"; then
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

if command -v nvim &>/dev/null; then
    echo "nvim already installed: $(nvim --version | head -1)"
else
    echo "nvim not found — installing latest stable version..."
    _install_nvim
fi

# ---------------------------------------------------------------------------
# Node.js — install via nvm if not already present (needed for LSP servers
# such as pyright and dockerfile-language-server)
# ---------------------------------------------------------------------------

NVM_DIR="$HOME/.nvm"

_install_node() {
    echo "Installing nvm..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
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
# npm global packages — prettier (null-ls formatter) and tree-sitter-cli
# (nvim-treesitter requirement).  Node must already be on PATH at this point.
# ---------------------------------------------------------------------------

# Re-source nvm in case _install_node just ran and npm isn't on PATH yet.
if [ -s "$NVM_DIR/nvm.sh" ] && ! command -v npm &>/dev/null; then
    \. "$NVM_DIR/nvm.sh"
fi

if command -v npm &>/dev/null; then
    _npm_globals=()
    command -v prettier    &>/dev/null || _npm_globals+=(prettier)
    command -v tree-sitter &>/dev/null || _npm_globals+=(tree-sitter-cli)

    if [ ${#_npm_globals[@]} -gt 0 ]; then
        echo "Installing npm global packages: ${_npm_globals[*]}"
        npm install -g "${_npm_globals[@]}"
    else
        echo "prettier and tree-sitter-cli already installed"
    fi
else
    echo "WARNING: npm not available — skipping prettier and tree-sitter-cli"
fi

# ---------------------------------------------------------------------------
# stylua — Lua formatter required by none-ls / null-ls
# ---------------------------------------------------------------------------

_install_stylua() {
    local arch
    arch=$(uname -m)
    local stylua_zip

    case "$arch" in
        x86_64)  stylua_zip="stylua-linux-x86_64.zip" ;;
        aarch64) stylua_zip="stylua-linux-aarch64.zip" ;;
        *)
            echo "Unsupported architecture for stylua: $arch. Install manually."
            return 1
            ;;
    esac

    local url="https://github.com/JohnnyMorganz/StyLua/releases/latest/download/$stylua_zip"
    local tmp_dir
    tmp_dir=$(mktemp -d)

    echo "Downloading stylua ($arch)..."
    if curl -fL "$url" -o "$tmp_dir/stylua.zip"; then
        python3 -c "import zipfile; zipfile.ZipFile('$tmp_dir/stylua.zip').extractall('$tmp_dir')"
        mkdir -p "$HOME/.local/bin"
        mv "$tmp_dir/stylua" "$HOME/.local/bin/stylua"
        chmod +x "$HOME/.local/bin/stylua"
        echo "stylua installed to $HOME/.local/bin/stylua"
    else
        echo "ERROR: failed to download stylua." >&2
        rm -rf "$tmp_dir"
        return 1
    fi
    rm -rf "$tmp_dir"
}

if command -v stylua &>/dev/null; then
    echo "stylua already installed: $(stylua --version)"
else
    echo "stylua not found — installing latest stable version..."
    _install_stylua
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
# ble.sh — bash line editor: ghost text, syntax highlighting, completion UI
# ---------------------------------------------------------------------------

BLE_SH_DIR="$DEST_DIR/bash/ble.sh"

_install_blesh() {
    echo "Installing ble.sh build dependency: gawk..."
    sudo apt install -y gawk
    echo "Cloning ble.sh..."
    git clone --recursive https://github.com/akinomyoga/ble.sh "$BLE_SH_DIR"
    echo "Building and installing ble.sh..."
    make -C "$BLE_SH_DIR" install PREFIX="$HOME/.local"
    echo "ble.sh installed to $HOME/.local/share/blesh/"
}

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
    curl -fL "$zig_url" -o "$tmp_dir/$zig_tarball"
    tar -xf "$tmp_dir/$zig_tarball" -C "$tmp_dir"
    local zig_bin="$tmp_dir/zig-linux-${arch}-${zig_version}/zig"

    echo "Downloading ghostty $version source tarball..."
    local src_url="https://release.files.ghostty.org/${version}/ghostty-${version}.tar.gz"
    curl -fL "$src_url" -o "$tmp_dir/ghostty.tar.gz"
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
#   2. Personal aliases / bindings.
#   3. Container auto-setup — runs this script on first entry into a container
#      where ~/.dot_files is mounted but symlinks don't exist yet.
BASHRC="$HOME/.bash_aliases_local"

# Remove old inline venv lines superseded by container_venv.sh
REMOVE_LINES=(
    "[ -f /.dockerenv ] && [ ! -d \"\$HOME/.venv\" ] && python3 -m venv \"\$HOME/.venv\""
    "[ -f /.dockerenv ] && [ -f \"\$HOME/.venv/bin/activate\" ] && source \"\$HOME/.venv/bin/activate\""
    "case :\$PATH: in *:/usr/local/go/bin:*) ;; *) export PATH=\"\$PATH:/usr/local/go/bin\" ;; esac"
)
for line in "${REMOVE_LINES[@]}"; do
    if grep -Fxq "$line" "$BASHRC" 2>/dev/null; then
        grep -Fxv "$line" "$BASHRC" > "${BASHRC}.tmp" && mv "${BASHRC}.tmp" "$BASHRC"
        echo "Removed from $BASHRC: $line"
    fi
done

SOURCE_LINES=(
    "case :\$PATH: in *:\$HOME/.local/bin:*) ;; *) export PATH=\"\$HOME/.local/bin:\$PATH\" ;; esac"
    "case :\$PATH: in *:/usr/local/go/bin:*) ;; *) export PATH=\"/usr/local/go/bin:\$PATH\" ;; esac"
    "[ -s \"\$HOME/.nvm/nvm.sh\" ] && \\. \"\$HOME/.nvm/nvm.sh\""
    "[ -f /.dockerenv ] && export TERM=xterm-256color"
    "[ -f /.dockerenv ] && [ -f \"\$HOME/.dot_files/bash/container_venv.sh\" ] && source \"\$HOME/.dot_files/bash/container_venv.sh\""
    "source \$HOME/.dot_files/bash/alias.sh"
    "source \$HOME/.dot_files/bash/bindings.sh"
    "source \$HOME/.dot_files/bash/ros2_completion.sh"
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
