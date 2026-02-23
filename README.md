# Dotfiles

Personal dotfiles for tmux and neovim configuration.

## Contents

- **`.tmux.conf`** — Tmux configuration with TPM (Tmux Plugin Manager)
- **`.config/nvim/`** — Neovim configuration (kickstart.nvim-based with lazy.nvim)

## Installation

### On a new machine

1. Clone the repository:
   ```bash
   git clone https://github.com/<username>/dotfiles ~/dotfiles
   cd ~/dotfiles
   ```

2. Run the install script:
   ```bash
   ./install.sh
   ```

   This will:
   - Create symlinks from `~/.tmux.conf` and `~/.config/nvim` to the dotfiles repo
   - Backup any existing configs to `.bak` files
   - Install TPM (Tmux Plugin Manager) if not already present

3. Start tmux and install plugins:
   ```bash
   tmux
   # Press: Ctrl+b, then I (capital i) to install plugins
   ```

4. Open neovim:
   ```bash
   nvim
   ```
   - Lazy.nvim will automatically download and install all plugins
   - Mason will auto-install LSP servers on first open

## Configuration Files

### Tmux (`~/.tmux.conf`)

Uses TPM for plugin management. Install plugins with `prefix + I`.

### Neovim (`~/.config/nvim`)

- **`init.lua`** — Main entry point
- **`lua/kickstart/`** — Core plugins and settings
- **`lua/custom/`** — Personal customizations

Plugins are managed with [lazy.nvim](https://github.com/folke/lazy.nvim).

## Updating

Make changes in `~/dotfiles`, then commit and push:

```bash
cd ~/dotfiles
git add .
git commit -m "description of changes"
git push
```

## Uninstalling

To revert to non-symlinked configs:

```bash
# Remove symlinks and restore backups (if they exist)
rm ~/.tmux.conf ~/.config/nvim
if [ -f ~/.tmux.conf.bak ]; then mv ~/.tmux.conf.bak ~/.tmux.conf; fi
if [ -d ~/.config/nvim.bak ]; then mv ~/.config/nvim.bak ~/.config/nvim; fi
```
