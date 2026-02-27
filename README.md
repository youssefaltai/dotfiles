# Dotfiles

Personal dotfiles for zsh, tmux, and neovim configuration. No plugin managers for zsh — all plugins are cloned and sourced directly.

## Contents

- **`.zshrc`** — Zsh shell configuration (autosuggestions, syntax highlighting, vi-mode, git aliases, completions)
- **`.zshenv`** — Zsh environment setup
- **`zsh/`** — Zsh functions and prompt theme
- **`.tmux.conf`** — Tmux configuration with TPM (Tmux Plugin Manager)
- **`.config/nvim/`** — Neovim configuration (kickstart.nvim-based with lazy.nvim)
- **`.config/ghostty/`** — Ghostty terminal config (macOS only)

## Installation

```bash
git clone https://github.com/<username>/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

This will:
- Symlink config files to your home directory (backs up existing configs to `.bak`)
- Clone zsh plugins to `~/.zsh/plugins/`
- Install TPM (Tmux Plugin Manager)

### Post-install

1. Restart your shell or `source ~/.zshrc`
2. Start tmux and install plugins: `Ctrl+b` then `I`
3. Open neovim — lazy.nvim auto-installs plugins, Mason auto-installs LSP servers

## Zsh Plugins

All plugins are cloned by `install.sh` and sourced directly from `~/.zsh/plugins/`:

| Plugin | Description |
|--------|-------------|
| [zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode) | Vi keybinding mode |
| [zsh-fzf-history-search](https://github.com/joshskidmore/zsh-fzf-history-search) | FZF-based history search |
| [zsh-completions](https://github.com/zsh-users/zsh-completions) | Additional completion definitions |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Fish-like syntax highlighting |
| [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) | Fish-like history search |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Fish-like autosuggestions |

Built-in modules (inlined in `.zshrc` and `zsh/`): environment options, input key bindings, terminal title, utility aliases, git aliases, completion config, [asciiship](https://github.com/zimfw/asciiship) prompt theme with duration info and git status.

## Updating

```bash
cd ~/dotfiles
git add -u && git commit -m "sync dotfiles" && git push
```

To update zsh plugins:

```bash
for dir in ~/.zsh/plugins/*/; do git -C "$dir" pull; done
```

## Uninstalling

```bash
# Remove symlinks and restore backups
rm ~/.zshrc ~/.zshenv ~/.tmux.conf
rm ~/.zsh/functions ~/.zsh/prompt.zsh
rm -rf ~/.zsh/plugins
rm -rf ~/.config/nvim ~/.config/ghostty
# Restore backups if they exist
for f in ~/.zshrc.bak ~/.zshenv.bak ~/.tmux.conf.bak; do
  [ -f "$f" ] && mv "$f" "${f%.bak}"
done
```
