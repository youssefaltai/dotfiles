export PATH="$HOME/.local/bin:$PATH"

# --- Always in tmux ---------------------------------------------------------
# Land every interactive terminal inside tmux: attach to the persistent "main"
# session if it exists, else create it (new-session -A -s). `exec` replaces this
# shell, so quitting tmux closes the terminal like a normal exit. Runs early so
# we jump in before sourcing the heavy plugins below. Guards:
#   $TMUX empty       don't nest — the inner shell re-sources this file
#   -o interactive    skip scripts and other non-interactive invocations
#   -t 1              stdout is a tty — avoids "not a terminal" from tmux
#   $NVIM empty       don't hijack a shell spawned inside nvim's :terminal
#   command -v tmux   no-op if tmux somehow isn't on PATH yet
if [[ -z "$TMUX" && -o interactive && -t 1 && -z "$NVIM" ]] \
   && command -v tmux >/dev/null; then
  exec tmux new-session -A -s main
fi
# ----------------------------------------------------------------------------

# --- XDG Base Directory spec ------------------------------------------------
# Funnel all app config/data/state/cache into predictable dirs so $HOME stays
# clean and your whole setup = one ~/.config folder (your dotfiles repo).
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

# --- Dart / pub cache -------------------------------------------------------
# Dart & Flutter download packages into ~/.pub-cache by default (clutters $HOME,
# grows large). PUB_CACHE is the officially supported override. Docs:
# dart.dev/tools/pub/environment-variables. The existing cache was moved here so
# nothing re-downloads; run `dart pub get` / `flutter pub get` in a project once
# to repoint its .dart_tool/package_config.json at the new path.
export PUB_CACHE="$XDG_CACHE_HOME/pub"
# ----------------------------------------------------------------------------

# --- npm --------------------------------------------------------------------
# npm ignores XDG: it defaults its cache to ~/.npm and per-user config to
# ~/.npmrc. The officially documented npm_config_* env vars relocate both under
# XDG. userconfig points at the file itself (not a dir) and notably can't be set
# from inside .npmrc. Docs: docs.npmjs.com/cli/v11/using-npm/config.
export npm_config_cache="$XDG_CACHE_HOME/npm"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
# ----------------------------------------------------------------------------

# --- Docker -----------------------------------------------------------------
# The Docker CLI stores config (config.json, contexts/, creds) in ~/.docker by
# default. DOCKER_CONFIG relocates that directory. Docs:
# docs.docker.com/reference/cli/docker. (Note: Docker *Desktop* recreates
# ~/.docker regardless of this var — not an issue here, this machine runs the
# brew CLI without Desktop.)
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
# ----------------------------------------------------------------------------

# --- Context7 ----------------------------------------------------------------
# Free API key for context7.com — up-to-date library docs for LLMs.
# Key stored in opencode's data dir (not in dotfiles).
export CONTEXT7_API_KEY="$(< "$HOME/.local/share/opencode/context7_key")"
# ----------------------------------------------------------------------------

# --- CocoaPods --------------------------------------------------------------
# CocoaPods stores its specs repos, cache and templates in ~/.cocoapods by
# default. CP_HOME_DIR relocates that whole tree (source: lib/cocoapods/
# config.rb -> ENV['CP_HOME_DIR']); granular CP_CACHE_DIR/CP_REPOS_DIR also
# exist. It's data-like, so it lives under XDG_DATA_HOME. Existing dir moved
# here so nothing re-downloads.
export CP_HOME_DIR="$XDG_DATA_HOME/cocoapods"
# ----------------------------------------------------------------------------

# --- GitHub Copilot CLI -----------------------------------------------------
# Copilot CLI defaults its config/auth to ~/.copilot. COPILOT_HOME replaces the
# whole path; we set it explicitly because its automatic XDG_CONFIG_HOME support
# is buggy (creates a dot-prefixed $XDG_CONFIG_HOME/.copilot — github/copilot-cli
# issue #1750). COPILOT_CACHE_HOME splits ephemeral cache out of the config dir.
export COPILOT_HOME="$XDG_CONFIG_HOME/copilot"
export COPILOT_CACHE_HOME="$XDG_CACHE_HOME/copilot"
# ----------------------------------------------------------------------------

# --- Atuin ------------------------------------------------------------------
# atuin defaults its log output to ~/.atuin/logs (outside XDG). ATUIN_LOG_DIR
# redirects logs to XDG_STATE_HOME, keeping $HOME clean. The main config and
# DB stay at ~/.config/atuin and ~/.local/share/atuin respectively.
export ATUIN_LOG_DIR="$XDG_STATE_HOME/atuin"
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

# --- OpenCode -----------------------------------------------------------------
# Prevent OpenCode from scanning Claude Code fallback locations (skills, etc.),
# keeping it fully independent.
export OPENCODE_DISABLE_CLAUDE_CODE=1
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

# Note: `v` in normal mode stays at zsh's default (visual-mode) — we don't bind
# it to edit-command-line, so it never drops the line into nvim.

# Vim text objects (ci" di( ciw ya{ vi> ...). All three widgets ship with zsh
# itself (/usr/share/zsh/$ZSH_VERSION/functions), so this needs no plugin — it
# stays within the no-framework rule. Bound only in operator-pending (viopp,
# used after c/d/y) and visual (after v) keymaps, so the rest of vi mode is
# untouched. select-word-match reads the typed i/a to pick inner-vs-around.
autoload -Uz select-bracketed select-quoted select-word-match
zle -N select-bracketed
zle -N select-quoted
zle -N select-word-match
for km in viopp visual; do
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do   # (), [], {}, <>, and b/B aliases
    bindkey -M $km -- "$c" select-bracketed
  done
  for c in {a,i}{\',\",\`}; do                # '', "", ``
    bindkey -M $km -- "$c" select-quoted
  done
  for c in {a,i}{w,W}; do                      # iw/aw (word) and iW/aW (WORD)
    bindkey -M $km -- "$c" select-word-match
  done
done
unset km c
# ----------------------------------------------------------------------------

# --- Prompt & plugins -------------------------------------------------------
# Starship: fast Rust prompt, single-file config at ~/.config/starship.toml
# (colored arrow, compact directory, git branch, slow-command duration).
eval "$(starship init zsh)"

# zsh-autosuggestions: ghost-text suggestion from history; press -> to accept.
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# zsh-syntax-highlighting: colors valid (green) / invalid (red) commands live.
# MUST be sourced LAST — it wraps every other line-editor widget.
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
# ----------------------------------------------------------------------------

