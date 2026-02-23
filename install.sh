#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR..."
# Function to create symlink with backup
symlink_config() {
  local source="$1"
  local target="$2"

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "  Backing up existing $target to ${target}.bak"
    mv "$target" "${target}.bak"
  elif [ -L "$target" ]; then
    echo "  Removing existing symlink $target"
    rm "$target"
  fi

  echo "  Symlinking $target -> $source"
  ln -s "$source" "$target"
}

# Create symlinks
echo "Setting up symlinks..."
symlink_config "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
symlink_config "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
symlink_config "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
symlink_config "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"
symlink_config "$DOTFILES_DIR/.config/ghostty" "$HOME/.config/ghostty"

# Install TPM if not present
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo ""
  echo "Installing TPM (Tmux Plugin Manager)..."
  mkdir -p "$HOME/.tmux/plugins"
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  echo "TPM installed at $HOME/.tmux/plugins/tpm"
else
  echo "TPM already installed at $HOME/.tmux/plugins/tpm"
fi

echo ""
echo "✓ Dotfiles installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Start tmux: tmux"
echo "  2. Install tmux plugins: prefix + I (default: Ctrl+b then I)"
echo "  3. Open neovim: nvim"
echo "  4. Lazy.nvim will auto-install plugins and Mason LSP servers"
