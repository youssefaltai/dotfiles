#!/usr/bin/env bash
# install.sh — reproduce this machine's config on a fresh Mac.
# Idempotent: safe to re-run. Automates the mechanical parts only; SSH keys,
# ~/.ssh/config, gh auth, and the (irreplaceable) Claude login are manual — see
# README.md §3. This script never touches secrets or the Claude credentials.
set -euo pipefail

CFG="$HOME/.config"
step() { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }
skip() { printf '    \033[2m· %s\033[0m\n' "$1"; }

# --- 0. Sanity -------------------------------------------------------------
[ "$(uname -s)" = "Darwin" ] || { echo "This installer is macOS-only." >&2; exit 1; }
[ -d "$CFG/.git" ] || { echo "Run after cloning this repo to ~/.config (see README §1)." >&2; exit 1; }
command -v git >/dev/null || { echo "git missing — run: xcode-select --install" >&2; exit 1; }

# --- 1. ~/.zshenv — the only home dotfile (points ZDOTDIR at ~/.config/zsh) -
step "~/.zshenv (ZDOTDIR bootstrap)"
ZSHENV_BODY='# ~/.zshenv — the only zsh file that must live in $HOME.
# Bootstraps XDG-based zsh config: point zsh at ~/.config/zsh for everything else.
export ZDOTDIR="$HOME/.config/zsh"'
if [ -f "$HOME/.zshenv" ] && grep -q 'ZDOTDIR="$HOME/.config/zsh"' "$HOME/.zshenv"; then
  skip "already points ZDOTDIR at ~/.config/zsh"
else
  printf '%s\n' "$ZSHENV_BODY" > "$HOME/.zshenv"
  echo "    written"
fi

# --- 2. Homebrew -----------------------------------------------------------
step "Homebrew (/opt/homebrew)"
if [ -x /opt/homebrew/bin/brew ]; then
  skip "already installed"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# --- 3. Brew bundle --------------------------------------------------------
step "brew bundle (packages + casks from Brewfile)"
brew bundle --file="$CFG/Brewfile"

# --- 4. mise runtimes ------------------------------------------------------
step "mise (trust + install runtimes)"
if command -v mise >/dev/null; then
  mise trust "$CFG/mise/config.toml" >/dev/null 2>&1 || true
  mise install || true
else
  skip "mise not on PATH yet — run 'mise install' after restarting your shell"
fi

# --- 5. Claude Code per-profile wiring -------------------------------------
# Writes settings.json etc. Safe here: the guard hook it references isn't active
# during a fresh install. It does NOT log in or touch credentials.
step "Claude Code wiring (claude/bootstrap.sh)"
bash "$CFG/claude/bootstrap.sh"

# --- 6. Flip origin to SSH (clone was HTTPS to bootstrap without keys) ------
step "git remote origin → SSH"
SSH_URL="git@github.com:youssefaltai/dotfiles.git"
if [ "$(git -C "$CFG" remote get-url origin 2>/dev/null)" = "$SSH_URL" ]; then
  skip "already SSH"
else
  git -C "$CFG" remote set-url origin "$SSH_URL"
  echo "    set to $SSH_URL"
fi

# --- 7. ~/work skeleton ----------------------------------------------------
step "~/work directory skeleton"
mkdir -p "$HOME/work/personal" "$HOME/work/reckit" "$HOME/work/noon"

# --- Done ------------------------------------------------------------------
cat <<'DONE'

Automated setup complete. Restart your shell:  exec zsh

Remaining MANUAL steps (secrets / irreplaceable account) — see README.md §3:
  a. SSH keys  : id_ed25519_{personal,reckit,noon}  (restore or ssh-keygen)
  b. ~/.ssh/config host aliases + ssh-add --apple-use-keychain
  c. gh auth login  (personal, then reckit, then noon via GH_CONFIG_DIR)
  d. Claude login   : ⚠ DO NOT re-login — restore from Passwords.app blob only
  e. fvm install <version>  (only for reckit Flutter work)
DONE
