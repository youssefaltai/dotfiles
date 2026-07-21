#!/usr/bin/env bash
# Claude Code status line: [profile] model  dir  ⎇ branch
# Receives session JSON on stdin; profile is derived from CLAUDE_CONFIG_DIR.

input="$(cat)"
dir="$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)"
model="$(printf '%s' "$input" | jq -r '.model.display_name // empty' 2>/dev/null)"
[ -n "$dir" ] || dir="$PWD"

case "${CLAUDE_CONFIG_DIR:-}" in
  *.claude-reckit) profile="reckit" ;;
  *)               profile="personal" ;;
esac

branch=""
if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  b="$(git -C "$dir" branch --show-current 2>/dev/null)"
  [ -n "$b" ] && branch="  ⎇ ${b}"
fi

short="${dir/#$HOME/~}"
printf '[%s] %s  %s%s' "$profile" "${model:-?}" "$short" "$branch"
