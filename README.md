# Config files

This repo contains Javi's configuration files:

- Neovim config
- Tmux config
- Bash config
- Ghostty config

---

## Setup

Run the included script to automatically:

- Clone the repo (if not already present)
- Create symlinks for Neovim (`~/.config/nvim`), Tmux (`~/.config/tmux`), and Ghostty (`~/.config/ghostty`) configs
- Update your `.bashrc` to source the alias and bindings scripts from the repo
- Schedule a daily cron job to update this repo automatically at 8 AM

---

### Usage

Run the setup script:

```bash
bash ~/.dot_files/bash/setup_dotfiles.sh
```
