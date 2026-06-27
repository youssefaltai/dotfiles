export PATH="$HOME/.local/bin:$PATH"

# --- XDG Base Directory spec ------------------------------------------------
# Funnel all app config/data/state/cache into predictable dirs so $HOME stays
# clean and your whole setup = one ~/.config folder (your future dotfiles repo).
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
# ----------------------------------------------------------------------------

# --- FVM (Flutter Version Management) ---------------------------------------
# fvm defaults its SDK cache to ~/fvm (non-hidden, clutters $HOME). Redirect it
# under XDG_DATA_HOME so $HOME stays clean. FVM_CACHE_PATH is the supported var
# (FVM_HOME is the deprecated legacy fallback). Docs: fvm.app/documentation.
export FVM_CACHE_PATH="$XDG_DATA_HOME/fvm"
# ----------------------------------------------------------------------------

# --- Default editor ---------------------------------------------------------
# Make Neovim the editor for everything that respects $EDITOR/$VISUAL: git
# commit/rebase, `Ctrl-X Ctrl-E` to edit the command line in nvim, Claude Code's
# external-editor key (Ctrl+G), etc. nvim is brew-managed (containment rule).
export EDITOR="nvim"
export VISUAL="nvim"
# ----------------------------------------------------------------------------

# --- Claude Code profiles ---------------------------------------------------
# On macOS ALL Claude creds live in the Keychain (NOT in a .credentials.json
# file -- that's the Linux/headless path). The Keychain service name is:
#   "Claude Code-credentials-<first 8 hex of sha256(absolute config-dir path)>"
# The DEFAULT profile (no CLAUDE_CONFIG_DIR) uses the un-suffixed
# "Claude Code-credentials". CLAUDE_CONFIG_DIR just selects which item is used.
#   personal -> bare `claude`  (default Keychain item; already signed in)
#   reckit   -> ~/.claude-reckit  (its own Keychain item)
#
# !! PERSONAL ACCOUNT IS IRREPLACEABLE: the login cannot be redone. NEVER run
# !! `claude auth logout`/`login`, delete its Keychain item, or set
# !! CLAUDE_CODE_OAUTH_TOKEN on personal. Recovery blob: Passwords.app entry
# !! "Claude Code old account credentials" (no-login restore path).
#
# NOTE: CLAUDE_CONFIG_DIR is real but UNDOCUMENTED/unsupported (issue #33430).
alias claude-personal='env -u CLAUDE_CONFIG_DIR claude'
alias claude-reckit='CLAUDE_CONFIG_DIR="$HOME/.claude-reckit" claude'
# ----------------------------------------------------------------------------

# --- mise: runtimes, env vars, tasks (per-project) --------------------------
# Activates per-directory tool versions + [env] vars. Config is XDG-clean
# (~/.config/mise, ~/.local/share/mise). Project files with an [env] block
# (e.g. NVIM_APPNAME / CLAUDE_CONFIG_DIR switches) need a one-time `mise trust`.
eval "$(mise activate zsh)"
# ----------------------------------------------------------------------------

# --- CLI tools --------------------------------------------------------------
eval "$(zoxide init zsh)"                    # `z <dir>` smart jump, `zi` interactive
eval "$(atuin init zsh --disable-up-arrow)"  # Ctrl-R history UI (up-arrow stays native)
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --git --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'
alias lg='lazygit'
# ----------------------------------------------------------------------------

# --- Vi mode (ZLE) ----------------------------------------------------------
# Vi keybindings on the command line. Insert mode is the default; Esc -> normal
# mode (hjkl/w/b/ciw/etc). atuin already binds Ctrl-R in insert mode and `/` in
# normal mode (see init above), so history search keeps working in both modes.
bindkey -v
export KEYTIMEOUT=1                 # 10ms Esc lag -> snappy mode switching

# Cursor shape tracks the mode: steady block in normal, steady bar in insert.
function zle-keymap-select {
  case $KEYMAP in
    vicmd)      printf '\e[2 q' ;;  # block
    viins|main) printf '\e[6 q' ;;  # bar
  esac
}
zle -N zle-keymap-select
function zle-line-init { printf '\e[6 q' }  # each new prompt starts in insert
zle -N zle-line-init

# Keep a few emacs-style edits in insert mode (muscle memory + saner backspace).
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^?' backward-delete-char   # backspace past the insert point
bindkey -M viins '^H' backward-delete-char

# `v` in normal mode opens the current command line in $EDITOR (nvim).
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line
# ----------------------------------------------------------------------------

# --- Prompt & plugins -------------------------------------------------------
# Starship: fast Rust prompt, single-file config (~/.config/starship.toml when
# we add one; the default is already clean, so nothing to configure yet).
eval "$(starship init zsh)"

# zsh-autosuggestions: ghost-text suggestion from history; press -> to accept.
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# zsh-syntax-highlighting: colors valid (green) / invalid (red) commands live.
# MUST be sourced LAST — it wraps every other line-editor widget.
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
# ----------------------------------------------------------------------------
