#
# Zsh Configuration — no plugin manager
#

ZSH_DIR="${ZDOTDIR:-${HOME}}/.zsh"
ZSH_PLUGINS="${ZSH_DIR}/plugins"

# ===================
# Environment options
# ===================

setopt AUTO_CD
setopt AUTO_PUSHD
autoload -Uz is-at-least && if is-at-least 5.8; then setopt CD_SILENT; fi
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt PUSHD_TO_HOME
setopt EXTENDED_GLOB

# History
if (( ! ${+HISTFILE} )) typeset -g HISTFILE=${ZDOTDIR:-${HOME}}/.zhistory
HISTSIZE=20000
SAVEHIST=10000
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY

# I/O
setopt INTERACTIVE_COMMENTS
setopt NO_CLOBBER

# Job control
setopt LONG_LIST_JOBS
setopt NO_BG_NICE
setopt NO_CHECK_JOBS
setopt NO_HUP

# =====
# Input
# =====

bindkey -e
WORDCHARS=${WORDCHARS//[\/]}

[[ ${TERM} != dumb ]] && () {
  zmodload -F zsh/terminfo +b:echoti +p:terminfo
  typeset -gA key_info
  key_info=(
    Control      '\C-'
    ControlLeft  '\e[1;5D \e[5D \e\e[D \eOd \eOD'
    ControlRight '\e[1;5C \e[5C \e\e[C \eOc \eOC'
    Escape       '\e'
    Meta         '\M-'
    Backspace    '^?'
    Delete       '^[[3~'
    BackTab      "${terminfo[kcbt]}"
    Left         "${terminfo[kcub1]}"
    Down         "${terminfo[kcud1]}"
    Right        "${terminfo[kcuf1]}"
    Up           "${terminfo[kcuu1]}"
    End          "${terminfo[kend]}"
    F1           "${terminfo[kf1]}"
    F2           "${terminfo[kf2]}"
    F3           "${terminfo[kf3]}"
    F4           "${terminfo[kf4]}"
    F5           "${terminfo[kf5]}"
    F6           "${terminfo[kf6]}"
    F7           "${terminfo[kf7]}"
    F8           "${terminfo[kf8]}"
    F9           "${terminfo[kf9]}"
    F10          "${terminfo[kf10]}"
    F11          "${terminfo[kf11]}"
    F12          "${terminfo[kf12]}"
    Home         "${terminfo[khome]}"
    Insert       "${terminfo[kich1]}"
    PageDown     "${terminfo[knp]}"
    PageUp       "${terminfo[kpp]}"
  )

  local key
  for key (${(s: :)key_info[ControlLeft]}) bindkey ${key} backward-word
  for key (${(s: :)key_info[ControlRight]}) bindkey ${key} forward-word
  bindkey ${key_info[Delete]} delete-char
  if [[ -n ${key_info[Home]} ]] bindkey ${key_info[Home]} beginning-of-line
  if [[ -n ${key_info[End]} ]] bindkey ${key_info[End]} end-of-line
  if [[ -n ${key_info[PageUp]} ]] bindkey ${key_info[PageUp]} up-line-or-history
  if [[ -n ${key_info[PageDown]} ]] bindkey ${key_info[PageDown]} down-line-or-history
  if [[ -n ${key_info[Insert]} ]] bindkey ${key_info[Insert]} overwrite-mode
  if [[ -n ${key_info[Left]} ]] bindkey ${key_info[Left]} backward-char
  if [[ -n ${key_info[Right]} ]] bindkey ${key_info[Right]} forward-char
  bindkey ' ' magic-space
  bindkey "${key_info[Escape]}." insert-last-word
  bindkey "${key_info[Escape]}_" insert-last-word
  autoload -Uz edit-command-line && zle -N edit-command-line && \
      bindkey "${key_info[Control]}x${key_info[Control]}e" edit-command-line
  if [[ -n ${key_info[BackTab]} ]] bindkey ${key_info[BackTab]} reverse-menu-complete
  autoload -Uz bracketed-paste-url-magic && zle -N bracketed-paste bracketed-paste-url-magic
  autoload -Uz url-quote-magic && zle -N self-insert url-quote-magic
  bindkey ${key_info[Backspace]} backward-delete-char

  if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} && \
      ! ${+functions[_start_application_mode]} && ! ${+functions[_stop_application_mode]} )); then
    functions[_start_application_mode]=${widgets[zle-line-init]#user:}'
echoti smkx'
    functions[_stop_application_mode]=${widgets[zle-line-finish]#user:}'
echoti rmkx'
    zle -N zle-line-init _start_application_mode
    zle -N zle-line-finish _stop_application_mode
  fi

  _input_deferred_init_precmd() {
    if (( ${+functions[history-substring-search-up]} && ${+functions[history-substring-search-down]} )); then
      local key
      for key ('^[[A' ${key_info[Up]} '^P') bindkey ${key} history-substring-search-up
      for key ('^[[B' ${key_info[Down]} '^N') bindkey ${key} history-substring-search-down
    fi
    precmd_functions=(${precmd_functions:#_input_deferred_init_precmd})
    unfunction _input_deferred_init_precmd
  }
  autoload -Uz add-zsh-hook && add-zsh-hook precmd _input_deferred_init_precmd
}

# ==============
# Terminal title
# ==============

[[ ${TERM} != dumb ]] && () {
  setopt prompt{percent,subst}
  autoload -Uz add-zsh-hook
  if [[ ${TERM_PROGRAM} == Apple_Terminal ]]; then
    termtitle_update_precmd() { print -n "\E]7;${PWD}\a" }
  else
    case ${TERM} in
      screen) termtitle_update_precmd() { print -Pn '\Ek%n@%m: %~\E\\' } ;;
      *)      termtitle_update_precmd() { print -Pn '\E]0;%n@%m: %~\a' } ;;
    esac
  fi
  add-zsh-hook precmd termtitle_update_precmd
}

# =======
# Utility
# =======

if (( ! ${+PAGER} )); then
  if (( ${+commands[less]} )); then
    export PAGER=less
  else
    export PAGER=more
  fi
fi
if (( ! ${+LESS} )); then
  export LESS='--ignore-case --jump-target=4 --LONG-PROMPT --no-init --quit-if-one-screen --RAW-CONTROL-CHARS'
fi

# File downloads
if (( ${+commands[aria2c]} )); then
  alias get='aria2c --max-connection-per-server=5 --continue'
elif (( ${+commands[axel]} )); then
  alias get='axel --num-connections=5 --alternate'
elif (( ${+commands[wget]} )); then
  alias get='wget --continue --progress=bar --timestamping'
elif (( ${+commands[curl]} )); then
  alias get='curl --continue-at - --location --progress-bar --remote-name --remote-time'
fi

alias df='df -h'
alias du='du -h'

# Colours
if [[ -z ${NO_COLOR} ]]; then
  if (( ! ${+GREP_COLOR} )) export GREP_COLOR='37;45'
  if (( ! ${+GREP_COLORS} )) export GREP_COLORS="mt=${GREP_COLOR}"
  if [[ ${OSTYPE} == (openbsd|solaris)* ]]; then
    if (( ${+commands[ggrep]} )) alias grep='ggrep --color=auto'
  elif (( ${+commands[grep]} )); then
    alias grep='grep --color=auto'
  fi
  if (( ! ${+LESS_TERMCAP_mb} )) export LESS_TERMCAP_mb=$'\E[1;31m'
  if (( ! ${+LESS_TERMCAP_md} )) export LESS_TERMCAP_md=$'\E[1;31m'
  if (( ! ${+LESS_TERMCAP_me} )) export LESS_TERMCAP_me=$'\E[0m'
  if (( ! ${+LESS_TERMCAP_ue} )) export LESS_TERMCAP_ue=$'\E[0m'
  if (( ! ${+LESS_TERMCAP_us} )) export LESS_TERMCAP_us=$'\E[1;32m'
fi

# ls
if whence dircolors >/dev/null && ls --version &>/dev/null; then
  # GNU
  alias lx='ll -X'
  if [[ -z ${NO_COLOR} ]]; then
    if [[ -s ${HOME}/.dir_colors ]]; then
      eval "$(dircolors --sh ${HOME}/.dir_colors)"
    elif (( ! ${+LS_COLORS} )); then
      export LS_COLORS='di=1;34:ln=35:so=32:pi=33:ex=31:bd=1;36:cd=1;33:su=30;41:sg=30;46:tw=30;42:ow=30;43'
    fi
    alias ls='ls --group-directories-first --color=auto'
  else
    alias ls='ls --group-directories-first'
  fi
  alias chmod='chmod --preserve-root -v'
  alias chown='chown --preserve-root -v'
else
  # BSD
  if [[ -z ${NO_COLOR} ]]; then
    export CLICOLOR=1
    if (( ! ${+LSCOLORS} )) export LSCOLORS=ExfxcxdxbxGxDxabagacad
    if [[ ${OSTYPE} == openbsd* && ${+commands[colorls]} -ne 0 ]]; then
      alias ls=colorls
    fi
  fi
fi

alias ll='ls -lh'
alias l='ll -A'
alias lm="l | ${PAGER}"
alias lk='ll -Sr'
alias lt='ll -tr'
if (( ${+commands[lsd]} )); then
  alias ls=lsd
  alias lr='ll --tree'
  alias lx='ll -X'
else
  alias lr='ll -R'
  alias lc='lt -c'
fi

if (( ${+commands[safe-rm]} && ! ${+commands[safe-rmdir]} )); then
  alias rm=safe-rm
fi

# ===========
# Git aliases
# ===========

typeset -g _git_log_fuller_format='%C(bold yellow)commit %H%C(auto)%d%n%C(bold)Author: %C(blue)%an <%ae> %C(cyan)%ai (%ar)%n%C(bold)Commit: %C(blue)%cn <%ce> %C(cyan)%ci (%cr)%C(reset)%n%+B'
typeset -g _git_log_oneline_format='%C(bold yellow)%h%C(reset) %s%C(auto)%d%C(reset)'
typeset -g _git_log_oneline_medium_format='%C(bold yellow)%h%C(reset) %<(50,trunc)%s %C(bold blue)%an %C(cyan)%as (%ar)%C(auto)%d%C(reset)'

() {
  local gprefix=G

  alias ${gprefix}='git'

  # Branch (b)
  alias ${gprefix}b='git branch'
  alias ${gprefix}bc='git checkout -b'
  alias ${gprefix}bd='git checkout --detach'
  alias ${gprefix}bl='git branch --list -vv'
  alias ${gprefix}bL='git branch --list -vv --all'
  alias ${gprefix}bn='git branch --no-contains'
  alias ${gprefix}bm='git branch --move'
  alias ${gprefix}bM='git branch --move --force'
  alias ${gprefix}bR='git branch --force'
  alias ${gprefix}bs='git show-branch'
  alias ${gprefix}bS='git show-branch --all'
  alias ${gprefix}bu='git branch --unset-upstream'

  # Commit (c)
  alias ${gprefix}c='git commit --verbose'
  alias ${gprefix}ca='git commit --verbose --all'
  alias ${gprefix}cA='git commit --verbose --patch'
  alias ${gprefix}cm='git commit --message'
  alias ${gprefix}co='git checkout'
  alias ${gprefix}cO='git checkout --patch'
  alias ${gprefix}cf='git commit --amend --reuse-message HEAD'
  alias ${gprefix}cF='git commit --verbose --amend'
  alias ${gprefix}cp='git cherry-pick'
  alias ${gprefix}cP='git cherry-pick --no-commit'
  alias ${gprefix}cr='git revert'
  alias ${gprefix}cR='git reset "HEAD^"'
  alias ${gprefix}cs='git show --pretty=format:"${_git_log_fuller_format}"'
  alias ${gprefix}cS='git commit --verbose -S'
  alias ${gprefix}cu='git commit --fixup'
  alias ${gprefix}cU='git commit --squash'
  alias ${gprefix}cv='git verify-commit'

  # Conflict (C)
  alias ${gprefix}Cl='git --no-pager diff --name-only --diff-filter=U'
  alias ${gprefix}Ca="git add \$(${gprefix}Cl)"
  alias ${gprefix}Ce="git mergetool \$(${gprefix}Cl)"
  alias ${gprefix}Co='git checkout --ours --'
  alias ${gprefix}CO="${gprefix}Co \$(${gprefix}Cl)"
  alias ${gprefix}Ct='git checkout --theirs --'
  alias ${gprefix}CT="${gprefix}Ct \$(${gprefix}Cl)"

  # Data (d)
  alias ${gprefix}d='git ls-files'
  alias ${gprefix}dc='git ls-files --cached'
  alias ${gprefix}dx='git ls-files --deleted'
  alias ${gprefix}dm='git ls-files --modified'
  alias ${gprefix}du='git ls-files --other --exclude-standard'
  alias ${gprefix}dk='git ls-files --killed'
  alias ${gprefix}di='git status --porcelain --ignored=matching | sed -n "s/^!! //p"'
  alias ${gprefix}dI='git ls-files --ignored --exclude-per-directory=.gitignore --cached'

  # Fetch (f)
  alias ${gprefix}f='git fetch'
  alias ${gprefix}fa='git fetch --all'
  alias ${gprefix}fp='git fetch --all --prune'
  alias ${gprefix}fc='git clone'
  alias ${gprefix}fm='git pull --no-rebase'
  alias ${gprefix}fr='git pull --rebase'
  alias ${gprefix}fu='git pull --ff-only --all --prune'

  # Grep (g)
  alias ${gprefix}g='git grep'
  alias ${gprefix}gi='git grep --ignore-case'
  alias ${gprefix}gl='git grep --files-with-matches'
  alias ${gprefix}gL='git grep --files-without-match'
  alias ${gprefix}gv='git grep --invert-match'
  alias ${gprefix}gw='git grep --word-regexp'

  # Help (h)
  alias ${gprefix}h='git help'
  alias ${gprefix}hw='git help --web'

  # Index (i)
  alias ${gprefix}ia='git add --verbose'
  alias ${gprefix}iA='git add --patch'
  alias ${gprefix}iu='git add --verbose --update'
  alias ${gprefix}iU='git add --verbose --all'
  alias ${gprefix}id='git diff --no-ext-diff --cached'
  alias ${gprefix}iD='git diff --no-ext-diff --cached --word-diff'
  alias ${gprefix}ir='git reset'
  alias ${gprefix}iR='git reset --patch'
  alias ${gprefix}ix='git rm --cached -r'
  alias ${gprefix}iX='git rm --cached -rf'

  # Log (l)
  alias ${gprefix}l='git log --date-order --pretty=format:"${_git_log_fuller_format}"'
  alias ${gprefix}ls='git log --date-order --stat --pretty=format:"${_git_log_fuller_format}"'
  alias ${gprefix}ld='git log --date-order --stat --patch --pretty=format:"${_git_log_fuller_format}"'
  alias ${gprefix}lf='git log --date-order --stat --patch --follow --pretty=format:"${_git_log_fuller_format}"'
  alias ${gprefix}lo='git log --date-order --pretty=format:"${_git_log_oneline_format}"'
  alias ${gprefix}lO='git log --date-order --pretty=format:"${_git_log_oneline_medium_format}"'
  alias ${gprefix}lg='git log --date-order --graph --pretty=format:"${_git_log_oneline_format}"'
  alias ${gprefix}lG='git log --date-order --graph --pretty=format:"${_git_log_oneline_medium_format}"'
  alias ${gprefix}lv='git log --date-order --show-signature --pretty=format:"${_git_log_fuller_format}"'
  alias ${gprefix}lc='git shortlog --summary --numbered'
  alias ${gprefix}lr='git reflog'

  # Merge (m)
  alias ${gprefix}m='git merge'
  alias ${gprefix}ma='git merge --abort'
  alias ${gprefix}mc='git merge --continue'
  alias ${gprefix}mC='git merge --no-commit'
  alias ${gprefix}mF='git merge --no-ff'
  alias ${gprefix}ms='git merge --squash'
  alias ${gprefix}mS='git merge -S'
  alias ${gprefix}mv='git merge --verify-signatures'
  alias ${gprefix}mt='git mergetool'

  # Push (p)
  alias ${gprefix}p='git push'
  alias ${gprefix}pf='git push --force-with-lease'
  alias ${gprefix}pF='git push --force'
  alias ${gprefix}pa='git push --all'
  alias ${gprefix}pA='git push --all && git push --tags --no-verify'
  alias ${gprefix}pt='git push --tags'
  alias ${gprefix}pc='git push --set-upstream origin "$(git-branch-current 2>/dev/null)"'
  alias ${gprefix}pp='git pull origin "$(git-branch-current 2>/dev/null)" && git push origin "$(git-branch-current 2>/dev/null)"'

  # Rebase (r)
  alias ${gprefix}r='git rebase'
  alias ${gprefix}ra='git rebase --abort'
  alias ${gprefix}rc='git rebase --continue'
  alias ${gprefix}ri='git rebase --interactive --autosquash'
  alias ${gprefix}rs='git rebase --skip'
  alias ${gprefix}rS='git rebase --exec "git commit --amend --no-edit --no-verify -S"'

  # Remote (R)
  alias ${gprefix}R='git remote'
  alias ${gprefix}Rl='git remote --verbose'
  alias ${gprefix}Ra='git remote add'
  alias ${gprefix}Rx='git remote rm'
  alias ${gprefix}Rm='git remote rename'
  alias ${gprefix}Ru='git remote update'
  alias ${gprefix}Rp='git remote prune'
  alias ${gprefix}Rs='git remote show'
  alias ${gprefix}RS='git remote set-url'

  # Stash (s)
  alias ${gprefix}s='git stash'
  alias ${gprefix}sa='git stash apply'
  alias ${gprefix}sx='git stash drop'
  alias ${gprefix}sl='git stash list'
  alias ${gprefix}sd='git stash show --patch --stat'
  alias ${gprefix}sp='git stash pop'
  alias ${gprefix}ss='git stash save --include-untracked'
  alias ${gprefix}sS='git stash save --patch --no-keep-index'
  alias ${gprefix}sw='git stash save --include-untracked --keep-index'
  alias ${gprefix}si='git stash push --staged'
  alias ${gprefix}su='git stash show --patch | git apply --reverse'

  # Submodule (S)
  alias ${gprefix}S='git submodule'
  alias ${gprefix}Sa='git submodule add'
  alias ${gprefix}Sf='git submodule foreach'
  alias ${gprefix}Si='git submodule init'
  alias ${gprefix}SI='git submodule update --init --recursive'
  alias ${gprefix}Sl='git submodule status'
  alias ${gprefix}Ss='git submodule sync'
  alias ${gprefix}Su='git submodule update --remote'

  # Tag (t)
  alias ${gprefix}t='git tag'
  alias ${gprefix}tl='git tag --list --sort=-committerdate'
  alias ${gprefix}ts='git tag --sign'
  alias ${gprefix}tv='git verify-tag'
  alias ${gprefix}tx='git tag --delete'

  # Working tree (w)
  alias ${gprefix}ws='git status --short --branch'
  alias ${gprefix}wS='git status'
  alias ${gprefix}wd='git diff --no-ext-diff'
  alias ${gprefix}wD='git diff --no-ext-diff --word-diff'
  alias ${gprefix}wr='git reset --soft'
  alias ${gprefix}wR='git reset --hard'
  alias ${gprefix}wc='git clean --dry-run'
  alias ${gprefix}wC='git clean -d --force'
  alias ${gprefix}wm='git mv'
  alias ${gprefix}wM='git mv -f'
  alias ${gprefix}wx='git rm -r'
  alias ${gprefix}wX='git rm -rf'

  # Worktrees (W)
  alias ${gprefix}W='git worktree'
  alias ${gprefix}Wa='git worktree add'
  alias ${gprefix}Wl='git worktree list'
  alias ${gprefix}Wm='git worktree move'
  alias ${gprefix}Wp='git worktree prune'
  alias ${gprefix}Wx='git worktree remove'
  alias ${gprefix}WX='git worktree remove --force'

  # Switch (y)
  alias ${gprefix}y='git switch'
  alias ${gprefix}yc='git switch --create'
  alias ${gprefix}yd='git switch --detach'

  # Misc
  alias ${gprefix}..='cd "$(git rev-parse --show-toplevel 2>/dev/null || print .)"'
}

# ==================================
# Autoloaded functions & prompt
# ==================================

# Duration info (requires zsh/datetime)
zmodload -F zsh/datetime +p:EPOCHREALTIME

# Add custom functions to fpath
fpath=(${ZSH_DIR}/functions $fpath)
autoload -Uz duration-info-preexec duration-info-precmd git-info git-action coalesce git-branch-current

# Prompt (asciiship)
source ${ZSH_DIR}/prompt.zsh

# =================
# Third-party plugins
# =================

# zsh-vi-mode
if [[ -d ${ZSH_PLUGINS}/zsh-vi-mode ]]; then
  source ${ZSH_PLUGINS}/zsh-vi-mode/zsh-vi-mode.plugin.zsh
fi

# fzf history search
if [[ -d ${ZSH_PLUGINS}/zsh-fzf-history-search ]]; then
  source ${ZSH_PLUGINS}/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh
fi

# Additional completions (fpath only, no sourcing needed)
if [[ -d ${ZSH_PLUGINS}/zsh-completions ]]; then
  fpath=(${ZSH_PLUGINS}/zsh-completions/src $fpath)
fi

# ==========
# Completion
# ==========

() {
  builtin emulate -L zsh -o EXTENDED_GLOB

  local zdumpfile=${ZDOTDIR:-${HOME}}/.zcompdump

  autoload -Uz compinit && compinit -C -d ${zdumpfile} && [[ -e ${zdumpfile} ]] || return 1

  # Compile the dump file for speed
  if [[ ! ${zdumpfile}.zwc -nt ${zdumpfile} ]] zcompile ${zdumpfile}
}

setopt ALWAYS_TO_END
setopt COMPLETE_IN_WORD
setopt NO_CASE_GLOB
setopt NO_LIST_BEEP

zstyle ':completion::complete:*' use-cache on
zstyle ':completion:*' menu select
zstyle ':completion:*:matches' group yes
zstyle ':completion:*:options' description yes
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}' '+r:|[._-]=* r:|=*' '+l:|=*'
zstyle ':completion:*' insert-tab false
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec)|prompt_*)'
zstyle ':completion:*:*:-subscript-:*' tag-order 'indexes' 'parameters'

if (( ${+LS_COLORS} )); then
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
else
  zstyle ':completion:*:default' list-colors ${(s.:.):-di=1;34:ln=35:so=32:pi=33:ex=31:bd=1;36:cd=1;33:su=30;41:sg=30;46:tw=30;42:ow=30;43}
fi
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*' squeeze-slashes true

zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes

zstyle -e ':completion:*:hosts' hosts 'reply=(
  ${=${=${=${${(f)"$(cat {/etc/ssh/ssh_,~/.ssh/}known_hosts{,2} 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
  ${=${(f)"$(cat /etc/hosts 2>/dev/null; (( ${+commands[ypcat]} )) && ypcat hosts 2>/dev/null)"}%%(\#)*}
  ${=${${${${(@M)${(f)"$(cat ~/.ssh/config{,.d/*(N)} 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'
zstyle ':completion:*:*:*:users' ignored-patterns \
  '_*' adm amanda apache avahi beaglidx bin cacti canna clamav daemon dbus \
  distcache dovecot fax ftp games gdm gkrellmd gopher hacluster haldaemon \
  halt hsqldb ident junkbust ldap lp mail mailman mailnull mldonkey mysql \
  nagios named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
  operator pcap postfix postgres privoxy pulse pvm quagga radvd rpc rpcuser \
  rpm shutdown squid sshd sync uucp vcsa xfs
zstyle ':completion:*' single-ignored show
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# =============================
# Plugins that must be last
# =============================

ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Syntax highlighting (must be after completion)
if [[ -d ${ZSH_PLUGINS}/zsh-syntax-highlighting ]]; then
  source ${ZSH_PLUGINS}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# History substring search (must be after syntax highlighting)
if [[ -d ${ZSH_PLUGINS}/zsh-history-substring-search ]]; then
  source ${ZSH_PLUGINS}/zsh-history-substring-search/zsh-history-substring-search.zsh
fi

# Autosuggestions
if [[ -d ${ZSH_PLUGINS}/zsh-autosuggestions ]]; then
  source ${ZSH_PLUGINS}/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# ===============
# Custom settings
# ===============

export PATH="$HOME/.local/bin:$PATH"

# NeoVim (Linux only)
if [[ "$(uname)" == "Linux" && -d "/opt/nvim-linux-x86_64/bin" ]]; then
  export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
fi

export XDG_CONFIG_HOME="$HOME/.config"

# Flutter/Dart (FVM)
export PATH="$HOME/fvm/default/bin/:$PATH"

# Dotfiles convenience aliases
alias dotfiles="cd ~/dotfiles"
alias dotfiles-sync="cd ~/dotfiles && git pull"
alias dotfiles-push="cd ~/dotfiles && git add -u && git commit -m 'sync dotfiles' && git push"
