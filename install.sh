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

# Function to clone a plugin if not already present
clone_plugin() {
  local repo="$1"
  local dest="$2"

  if [ ! -d "$dest" ]; then
    echo "  Cloning $repo..."
    git clone --depth 1 "https://github.com/${repo}.git" "$dest"
  else
    echo "  $repo already installed"
  fi
}

# Create symlinks
echo ""
echo "Setting up symlinks..."
symlink_config "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
symlink_config "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
symlink_config "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"

mkdir -p "$HOME/.zsh"
symlink_config "$DOTFILES_DIR/zsh/functions" "$HOME/.zsh/functions"
symlink_config "$DOTFILES_DIR/zsh/prompt.zsh" "$HOME/.zsh/prompt.zsh"

symlink_config "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"

# Ghostty: macOS only
if [ "$(uname)" = "Darwin" ]; then
  symlink_config "$DOTFILES_DIR/.config/ghostty" "$HOME/.config/ghostty"
  echo "  (Ghostty symlink configured for macOS)"
else
  echo "  Skipping Ghostty symlink (not on macOS)"
fi

# Install zsh plugins
echo ""
echo "Installing zsh plugins..."
ZSH_PLUGINS="$HOME/.zsh/plugins"
mkdir -p "$ZSH_PLUGINS"

clone_plugin "jeffreytse/zsh-vi-mode" "$ZSH_PLUGINS/zsh-vi-mode"
clone_plugin "joshskidmore/zsh-fzf-history-search" "$ZSH_PLUGINS/zsh-fzf-history-search"
clone_plugin "zsh-users/zsh-completions" "$ZSH_PLUGINS/zsh-completions"
clone_plugin "zsh-users/zsh-syntax-highlighting" "$ZSH_PLUGINS/zsh-syntax-highlighting"
clone_plugin "zsh-users/zsh-history-substring-search" "$ZSH_PLUGINS/zsh-history-substring-search"
clone_plugin "zsh-users/zsh-autosuggestions" "$ZSH_PLUGINS/zsh-autosuggestions"

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
echo "Done!"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or: source ~/.zshrc"
echo "  2. Start tmux and install plugins: prefix + I (Ctrl+b then I)"
echo "  3. Open neovim: nvim (lazy.nvim auto-installs plugins)"
