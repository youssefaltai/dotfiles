# ~/.local/bin holds self-managed binaries (the Claude Code CLI lives here).
# ~/.config/bin holds this machine's own scripts, versioned in the dotfiles repo
# — `ctx` (context wiring generator) among them.
export PATH="$HOME/.config/bin:$HOME/.local/bin:$PATH"

# --- Auto-attach to tmux (OPT-IN, currently OFF) ----------------------------
# Land every interactive terminal inside tmux: attach to the persistent "main"
# session if it exists, else create it. `exec` replaces this shell, so quitting
# tmux closes the terminal like a normal exit.
#
# Disabled by choice — set TMUX_AUTOATTACH=1 (in .zprofile, or per-terminal) to
# turn it back on without editing this file. It was previously commented out
# outright, which left it unclear whether that was deliberate or half-finished.
#
# Guards: don't nest ($TMUX), interactive only, stdout is a tty (avoids "not a
# terminal" from tmux), and don't hijack nvim's :terminal ($NVIM).
if [[ -n "${TMUX_AUTOATTACH:-}" && -z "$TMUX" && -o interactive && -t 1 && -z "$NVIM" ]] \
   && command -v tmux >/dev/null; then
  exec tmux new-session -A -s main
fi
# ----------------------------------------------------------------------------

# --- XDG paths and tool relocations -----------------------------------------
# Moved to ~/.config/zsh/env.zsh, sourced from ~/.zshenv, because this file is
# read ONLY by interactive shells. Anything launched otherwise — a script, an
# IDE build task, a launchd job — never saw them, so those tools kept writing
# to ~/.npm, ~/.pub-cache and friends while `ls ~` looked clean.
# ----------------------------------------------------------------------------

# --- API keys (Context7 library docs, Exa search) ---------------------------
# Consumed by Claude Code MCP servers. Kept in ~/.local/share/machine/keys so
# they are never committed to the dotfiles repo. Read defensively: an
# unconditional `$(< file)` on a missing path breaks every new shell, which is
# exactly what happened when the old opencode data dir was deleted.
_keydir="$XDG_DATA_HOME/machine/keys"
[[ -r "$_keydir/context7_key" ]] && export CONTEXT7_API_KEY="$(< "$_keydir/context7_key")"
[[ -r "$_keydir/exa_key" ]]      && export EXA_API_KEY="$(< "$_keydir/exa_key")"
unset _keydir
# ----------------------------------------------------------------------------

# --- Claude Code profiles ---------------------------------------------------
# On macOS ALL Claude creds live in the Keychain (NOT in a .credentials.json
# file -- that's the Linux/headless path). The Keychain service name is:
#   "Claude Code-credentials-<first 8 hex of sha256(absolute config-dir path)>"
# The DEFAULT profile (no CLAUDE_CONFIG_DIR) uses the un-suffixed
# "Claude Code-credentials". CLAUDE_CONFIG_DIR just selects which item is used.
#   personal -> bare `claude`     (default Keychain item; Max x20 subscription)
#   reckit   -> ~/.claude-reckit  (its own Keychain item, youssef@goreckit.com)
# Per-directory switching: ~/work/reckit/mise.toml sets CLAUDE_CONFIG_DIR for
# the whole reckit tree; everywhere else the personal default applies. noon,
# dolab-marcom and freelance all run on the personal account. The aliases below
# are explicit overrides for when you're outside those dirs.
#
# Both accounts are normal and re-authenticatable — the old irreplaceable
# account is gone. A PreToolUse hook still blocks `claude auth login/logout`
# and the Keychain item, so those fail until the hook is relaxed; that is a
# guardrail against accidents, not a warning that recovery is impossible.
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

export PATH=$PATH:$HOME/.maestro/bin
