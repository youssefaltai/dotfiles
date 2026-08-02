#!/usr/bin/env bash
# Claude Code SessionStart hook — orient every new session.
#
# Lives here rather than in hooks/ because hooks/ is deny-listed for agent
# edits (so the agent cannot weaken its own guard). statusline.sh sits here for
# the same reason. Both are still referenced from settings.json by full path.
#
# Emits the active context, identity, GitHub account, Claude profile and rails
# so a session never starts guessing which hat it is wearing. Wrong-account or
# wrong-profile work is the expensive mistake this prevents: it stays invisible
# until a commit lands under the wrong email or on the wrong subscription.
#
# Contract: stdout becomes session context. This must NEVER fail a session —
# every branch exits 0, and anything unexpected produces no output rather than
# an error.

set -uo pipefail

input="$(cat 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
[ -n "$cwd" ] || cwd="$PWD"
[ -d "$cwd" ] || exit 0

CTX="$HOME/.config/bin/ctx"
[ -x "$CTX" ] || exit 0

# `ctx which` exits 1 outside any context — that is normal, not an error.
out="$("$CTX" which "$cwd" 2>/dev/null)" || exit 0
[ -n "$out" ] || exit 0

printf '## Active context\n\n%s\n' "$out"

# Warn only when the Claude profile does not match what the context expects.
# `ctx which` prints "  claude  <profile>"; compare against CLAUDE_CONFIG_DIR.
want="$(printf '%s' "$out" | awk '/^[[:space:]]*claude[[:space:]]/ {print $2}')"
case "${CLAUDE_CONFIG_DIR:-}" in
  *.claude-reckit) have="reckit" ;;
  *)               have="personal" ;;
esac
if [ -n "$want" ] && [ "$want" != "$have" ]; then
  printf '\n**Profile mismatch**: this context expects the `%s` Claude profile, but the active one is `%s`. Work here bills to `%s`.\n' \
    "$want" "$have" "$have"
fi

exit 0
