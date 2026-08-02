# env.zsh — environment that must apply to EVERY zsh, not just interactive ones.
#
# Sourced from ~/.zshenv, which zsh reads for every invocation: scripts, `zsh -c`,
# login shells, IDE-spawned build tasks, launchd jobs. `.zshrc` is read ONLY by
# interactive shells, which is why these belong here.
#
# Why this file exists
# -------------------
# These relocations used to live in .zshrc. The machine looked clean when you
# typed `ls ~`, but anything not launched from an interactive shell never saw
# the variables and happily wrote to the default $HOME paths. Measured on
# 2026-08-02: ~/.npm held 9,555 files modified in the previous month, and
# ~/.pub-cache held 35,145 — while `npm_config_cache` and `PUB_CACHE` pointed at
# ~/.cache. The relocation was real for you and invisible to everything else.
#
#     zsh -c   'echo $npm_config_cache'  -> UNSET   (was the bug)
#     zsh -lc  'echo $npm_config_cache'  -> UNSET
#     zsh -ic  'echo $npm_config_cache'  -> ~/.cache/npm
#
# Remaining limit: GUI apps launched from Finder/Dock (Xcode, Android Studio)
# inherit their environment from launchd, not from any shell, so they still miss
# these. Fixing that needs `launchctl setenv`, which is a separate decision —
# see system.md §2.

# --- XDG Base Directory spec ------------------------------------------------
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# --- Tools that ignore XDG and need an explicit override --------------------
# Each uses that tool's own officially supported variable; see system.md §2.
export FVM_CACHE_PATH="$XDG_DATA_HOME/fvm"          # else ~/fvm (non-hidden)
export PUB_CACHE="$XDG_CACHE_HOME/pub"              # else ~/.pub-cache
export npm_config_cache="$XDG_CACHE_HOME/npm"       # else ~/.npm
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"      # else ~/.docker
export CP_HOME_DIR="$XDG_DATA_HOME/cocoapods"       # else ~/.cocoapods
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"     # else ~/.gradle (tens of GB)
export ATUIN_LOG_DIR="$XDG_STATE_HOME/atuin"        # else ~/.atuin/logs

# Deliberately NOT setting COLIMA_HOME. colima has native XDG support and will
# use $XDG_CONFIG_HOME/colima on its own — but only when ~/.colima is absent.
# Both currently exist (~/.colima 9.4 GB live, ~/.config/colima 7.9 GB ignored),
# and colima itself warns about this. Pointing a third variable at a third path
# would make it worse. Resolve by hand — see system.md §2.

# --- Editor -----------------------------------------------------------------
# Non-interactive too: git rebase/commit invoked by scripts still needs $EDITOR.
export EDITOR="nvim"
export VISUAL="nvim"
