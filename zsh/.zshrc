export PATH="$HOME/.local/bin:$PATH"

# --- XDG Base Directory spec ------------------------------------------------
# Funnel all app config/data/state/cache into predictable dirs so $HOME stays
# clean and your whole setup = one ~/.config folder (your future dotfiles repo).
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
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
