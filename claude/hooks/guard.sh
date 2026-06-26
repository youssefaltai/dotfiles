#!/usr/bin/env bash
# Claude Code PreToolUse guard — shared by the personal + reckit profiles.
# Reads the tool-call JSON on stdin. For Bash commands it DENIES a small, tight
# set of irreversible/dangerous operations by exiting 2 (which blocks the call and
# returns the reason to Claude) — this works even in bypass / auto-accept modes.
# File-path protection (secrets, ssh, backups) is handled by deny rules in
# settings.json; this hook only inspects Bash command strings.

input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"

[ "$tool" = "Bash" ] || exit 0
[ -n "$cmd" ] || exit 0

deny()  { echo "BLOCKED by guard.sh: $1" >&2; exit 2; }
match() { printf '%s' "$cmd" | grep -Eiq "$1"; }

# 1. Claude auth — the personal login is irreplaceable.
match 'claude[[:space:]]+auth[[:space:]]+(login|logout)' \
  && deny "claude auth login/logout is forbidden (irreplaceable account)."

# 2. OAuth-token env that can wipe the Keychain login on exit.
match 'CLAUDE_CODE_OAUTH_TOKEN' \
  && deny "Setting CLAUDE_CODE_OAUTH_TOKEN can destroy the Keychain login."

# 3. Keychain operations on Claude credentials.
match 'security[[:space:]].*(delete-generic-password|claude code-credentials)' \
  && deny "Keychain operations on Claude credentials are forbidden."

# 4. Destroying / overwriting the credential backup.
match '(rm|rmdir|mv|truncate|tee|dd|>)[^|;&]*claude-personal-credentials-BACKUP' \
  && deny "The Claude credential backup must not be modified or deleted."

# 5. Removing a whole Claude profile directory.
match 'rm[[:space:]].*(~|\$HOME)/\.claude(-reckit)?/?([[:space:]]|$)' \
  && deny "Removing a Claude profile directory is forbidden."

# 6. Catastrophic recursive deletes of home/root.
match 'rm[[:space:]]+(-[A-Za-z]+[[:space:]]+)*(/|~|~/|\$HOME|\$HOME/|/\*)([[:space:]]|$)' \
  && deny "Catastrophic rm targeting home/root is forbidden."

# 7. Protect the guardrail files themselves from being rewritten via the shell
#    (the Edit/Write tools are blocked by deny rules; this closes the Bash path).
#    Verb may be at start-of-line OR preceded by whitespace.
match '(>|>>|(^|[[:space:]])(tee|cp|mv|ln)[[:space:]]).*(\.claude(-reckit)?/settings\.json|\.config/claude/(hooks/|statusline\.sh))' \
  && deny "Modifying Claude's own settings/guard via the shell is blocked (edit manually if you must)."

exit 0
