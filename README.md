# Config files

Personal configuration files for Neovim, Tmux, Bash, and Ghostty.

- **Neovim** — lazy.nvim plugin manager, LSP (clangd/pyright/lua_ls), DAP (cppdbg/codelldb), snacks.nvim pickers, diffview, gitsigns, treesitter, and more
- **Tmux** — tmux2k statusbar, popup-based session management, tmux-resurrect/continuum
- **Bash** — ble.sh line editor, fzf-tab-completion, history sync, ROS2 completion, container venv setup
- **Ghostty** — GPU-accelerated terminal emulator config

---

## First-time setup (new machine)

### 1. Clone with submodules

This repo uses git submodules for external tools (`ble.sh`, `fzf-tab-completion`).
Always clone with `--recursive` so they are fetched automatically:

```bash
git clone --recursive https://github.com/j-saez/.dot_files.git ~/.dot_files
```

If you already cloned without `--recursive`, initialize the submodules manually:

```bash
git submodule update --init --recursive
```

### 2. Run the setup script

```bash
bash ~/.dot_files/bash/setup_dotfiles.sh
```

The script will automatically:

- Create symlinks for Neovim (`~/.config/nvim`), Tmux (`~/.config/tmux`), Ghostty (`~/.config/ghostty`), and ble.sh (`~/.config/blesh/init.sh`)
- Install **Neovim** (latest stable, to `~/.local/bin`)
- Install **Node.js** via nvm (required by pyright and other LSP servers)
- Install npm globals: `prettier`, `tree-sitter-cli`
- Install **stylua** (Lua formatter)
- Install **ripgrep**
- Install **bash-completion**
- Build and install **ble.sh** from the submodule
- Clone/update **fzf-tab-completion** from the submodule
- Build and install **Ghostty** from source (host only, skipped inside containers)
- Update `~/.bash_aliases_local` to source aliases, bindings, and ROS2 completion
- Install a daily cron job to auto-update the repo (host only)

> **Containers:** The script detects Docker environments and skips host-only steps
> (ghostty build, cron). It sets up the venv, xclip, and nvim symlinks automatically
> on first shell entry via `~/.bash_aliases_local`.

### 3. Restart your terminal

```bash
source ~/.bash_aliases_local
```

Or open a new terminal — everything will be sourced automatically.

---

## Submodules

| Path | Repo | Purpose |
|------|------|---------|
| `bash/ble.sh` | [akinomyoga/ble.sh](https://github.com/akinomyoga/ble.sh) | Bash line editor: ghost-text suggestions, syntax highlighting |
| `bash/fzf-tab-completion` | [lincheney/fzf-tab-completion](https://github.com/lincheney/fzf-tab-completion) | fzf-powered Tab completion for bash |

### Updating submodules

To pull the latest commit from all submodules:

```bash
git submodule update --remote --merge
git add bash/ble.sh bash/fzf-tab-completion
git commit -m "chore: update submodules"
```

To update a single submodule:

```bash
git submodule update --remote --merge bash/ble.sh
```

---

## Keeping dotfiles up to date

A cron job runs `bash/update_dotfiles.sh` daily at 8 AM (host only).
To update manually:

```bash
git -C ~/.dot_files pull --recurse-submodules
```

---

## Neovim plugins

Plugins are managed by [lazy.nvim](https://github.com/folke/lazy.nvim) and installed automatically on first launch.
Run `:Lazy` inside Neovim to view/update them.

### Key bindings (`;` is the leader key)

| Key | Action |
|-----|--------|
| `;g?` | Git keybindings cheatsheet |
| `;ff` | Find files |
| `;fg` | Grep (append `  .ext` to filter by extension) |
| `;ee` | Toggle file tree (nvim-tree) |
| `;e` | Open parent dir as buffer (oil) |
| `;gC` | Compare commits (Tab to select up to 2, Enter to diff) |
| `;gF` | Diff current file vs a selected commit |

---

## Tmux

Plugins are managed by [TPM](https://github.com/tmux-plugins/tpm) and installed automatically on first launch.

### Session management keybindings

| Key | Action |
|-----|--------|
| `prefix + k` | Kill session(s) — popup with multi-select |
| `prefix + s` | Switch session — popup picker |
| `prefix + n` | New named session — popup |
| `prefix + f` | Sessionizer (project picker) |
| `prefix + g` | Open lazygit |
