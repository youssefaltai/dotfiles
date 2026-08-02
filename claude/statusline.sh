#!/usr/bin/env bash
# Claude Code status line:  ctx·profile  model  dir  ⎇ branch±  [STRICT]
#
# The context is derived from the working directory, mirroring contexts.toml,
# and the Claude profile from CLAUDE_CONFIG_DIR. Showing both matters because
# they can disagree: noon and dolab-marcom work runs on the *personal* Claude
# profile, so "which account is this billing to" is not guessable from the
# directory alone.
#
# Derived with pure shell — no python, no `ctx` call — because this renders on
# every prompt and a 50ms interpreter start is felt.

input="$(cat)"
dir="$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)"
model="$(printf '%s' "$input" | jq -r '.model.display_name // empty' 2>/dev/null)"
[ -n "$dir" ] || dir="$PWD"

# --- context, from the path -------------------------------------------------
ctx="—"; strict=""
case "$dir" in
  "$HOME"/work/personal*)     ctx="personal" ;;
  "$HOME"/work/freelance/*)   ctx="freelance/$(basename "${dir#$HOME/work/freelance/}" 2>/dev/null)"; strict=1 ;;
  "$HOME"/work/freelance*)    ctx="freelance"; strict=1 ;;
  "$HOME"/work/*)             ctx="${dir#$HOME/work/}"; ctx="${ctx%%/*}"; strict=1 ;;
  "$HOME"/.config*)           ctx="dotfiles" ;;
esac

# --- Claude profile, from the env -------------------------------------------
case "${CLAUDE_CONFIG_DIR:-}" in
  *.claude-reckit) profile="reckit" ;;
  *)               profile="personal" ;;
esac

# --- git branch + dirty flag ------------------------------------------------
branch=""
if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  b="$(git -C "$dir" branch --show-current 2>/dev/null)"
  [ -n "$b" ] || b="$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)"
  if [ -n "$b" ]; then
    git -C "$dir" diff --quiet --ignore-submodules HEAD 2>/dev/null || b="${b}±"
    branch="  ⎇ ${b}"
  fi
fi

short="${dir/#$HOME/~}"
# Braces are required: `$ctx·` would absorb the multibyte separator into the
# variable name and expand to nothing.
tag="${ctx}"
[ "$ctx" != "$profile" ] && tag="${ctx}·${profile}"
[ -n "$strict" ] && tag="${tag} ⚠"

printf '[%s] %s  %s%s' "$tag" "${model:-?}" "$short" "$branch"
