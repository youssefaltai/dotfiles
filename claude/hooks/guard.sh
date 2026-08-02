#!/usr/bin/env bash
# Claude Code PreToolUse guard — shared by every Claude profile on this machine.
#
# Purpose: make delegation safe by CONSTRUCTION. A prompt asking an agent to be
# careful is a request; this is a guarantee. It reads the tool-call JSON on
# stdin and exits 2 to block, which works even in bypass / auto-accept modes.
#
# Scope: Bash command strings only. File-path protection (secrets, ~/.ssh,
# credentials) is handled by deny rules in settings.json.
#
# Design rules:
#   - Deny only what is irreversible or destroys unpushed/uncommitted work.
#     Anything recoverable from git or a backup is allowed through.
#   - Every denial names the safe alternative, so the agent can re-route
#     instead of retrying blindly.
#   - Blocked != forbidden. You can always run the command yourself in a
#     terminal; the guard constrains the agent, not you.
#
# Strictness follows the context, mirroring `strict` in ~/.config/contexts.toml:
# everything under ~/work except ~/work/personal is an employer or client tree
# and gets the tighter rails.

input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"
cmd="$(printf '%s'  "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
cwd="$(printf '%s'  "$input" | jq -r '.cwd // empty' 2>/dev/null)"
[ -n "$cwd" ] || cwd="$PWD"

[ "$tool" = "Bash" ] || exit 0
[ -n "$cmd" ] || exit 0

deny()  { echo "BLOCKED by guard.sh: $1" >&2; exit 2; }
match() { printf '%s' "$cmd" | grep -Eiq "$1"; }

# Strict = employer/client tree. Personal work gets more rope.
strict=0
case "$cwd" in
  "$HOME"/work/personal|"$HOME"/work/personal/*) strict=0 ;;
  "$HOME"/work/*)                                strict=1 ;;
esac

# =============================================================================
# A. Account and credential safety
# =============================================================================
match 'claude[[:space:]]+auth[[:space:]]+(login|logout)' \
  && deny "claude auth login/logout is blocked. Switching accounts is a manual step."

match 'CLAUDE_CODE_OAUTH_TOKEN' \
  && deny "Setting CLAUDE_CODE_OAUTH_TOKEN can destroy the Keychain login."

match 'security[[:space:]].*(delete-generic-password|claude code-credentials)' \
  && deny "Keychain operations on Claude credentials are blocked."

match 'rm[[:space:]].*(~|\$HOME)/\.claude(-[a-z]+)?/?([[:space:]]|$)' \
  && deny "Removing a Claude profile directory is blocked."

# =============================================================================
# B. Catastrophic filesystem deletes
# =============================================================================
match 'rm[[:space:]]+(-[A-Za-z]+[[:space:]]+)*(/|~|~/|\$HOME|\$HOME/|/\*)([[:space:]]|$)' \
  && deny "Catastrophic rm targeting home or root is blocked."

# Recursive force-delete is fine in scratch/build dirs, not in source trees.
if printf '%s' "$cmd" | grep -Eiq 'rm[[:space:]]+[^|;&]*-[A-Za-z]*r[A-Za-z]*f|rm[[:space:]]+[^|;&]*-[A-Za-z]*f[A-Za-z]*r'; then
  match 'node_modules|\.next|dist|build|\.turbo|target|Pods|\.dart_tool|/tmp/|/var/folders/|\.venv|__pycache__|\.gradle/caches|scratchpad' \
    || deny "rm -rf outside build/cache dirs is blocked. Delete specific paths, or move them to ~/.Trash."
fi

match '(^|[^a-z])(mkfs|diskutil[[:space:]]+erase|dd[[:space:]]+[^|;&]*of=/dev/)' \
  && deny "Disk-destructive command is blocked."

# =============================================================================
# C. Git operations that destroy unpushed or uncommitted work
# =============================================================================
match 'git[[:space:]][^|;&]*reset[[:space:]][^|;&]*--hard' \
  && deny "git reset --hard discards uncommitted work. Use 'git stash -u' first, or run it yourself."

match 'git[[:space:]][^|;&]*clean[[:space:]][^|;&]*-[A-Za-z]*[fd]' \
  && deny "git clean deletes untracked files irrecoverably. Review 'git clean -n' first and run it yourself."

match 'git[[:space:]][^|;&]*checkout[[:space:]]+(--[[:space:]]+)?\.([[:space:]]|$)|git[[:space:]][^|;&]*restore[[:space:]][^|;&]*[[:space:]]\.([[:space:]]|$)' \
  && deny "Discarding all local changes is blocked. Stash them instead: git stash -u"

match 'git[[:space:]][^|;&]*(filter-branch|filter-repo)|git[[:space:]][^|;&]*reflog[[:space:]]+expire|git[[:space:]][^|;&]*gc[[:space:]][^|;&]*--prune=(now|all)' \
  && deny "History rewriting / reflog expiry destroys the recovery path. Manual only."

match 'git[[:space:]][^|;&]*branch[[:space:]][^|;&]*-[A-Za-z]*D([[:space:]]|$)' \
  && deny "Force-deleting a branch can lose unmerged commits. Use 'git branch -d', or do it yourself."

# --force-with-lease still rewrites remote history; it only checks you had seen
# the current tip first. Safe enough on your own branches, never on a shared one.
if match 'git[[:space:]][^|;&]*push[[:space:]][^|;&]*(--force(-with-lease)?([[:space:]]|=|$)|[[:space:]]-f([[:space:]]|$))'; then
  [ "$strict" = "1" ] \
    && deny "Force-push is blocked in employer/client repos — it can destroy a colleague's work. Manual only."
  match 'force-with-lease' \
    || deny "Plain --force can clobber remote commits. Use --force-with-lease."
fi

# Direct pushes to a shared trunk in an employer/client repo. Check BOTH the
# checked-out branch and any branch named explicitly in the refspec — pushing
# `origin main` from a feature branch is the same mistake.
if [ "$strict" = "1" ] && match 'git[[:space:]][^|;&]*push'; then
  trunk='main|master|develop|development|production|staging|release'
  branch="$(git -C "$cwd" branch --show-current 2>/dev/null)"
  case "$branch" in
    main|master|develop|development|production|staging|release|release/*)
      deny "Direct push from '$branch' is blocked in an employer/client repo. Work on a feature branch and open a PR."
      ;;
  esac
  if printf '%s' "$cmd" | grep -Eq "push[[:space:]]+[^[:space:]|;&]+[[:space:]]+(HEAD:)?($trunk)([[:space:]]|$|:)"; then
    deny "Pushing directly to a shared trunk is blocked in an employer/client repo. Open a PR instead."
  fi
fi

# =============================================================================
# D. Secrets — printing into the transcript, or staging into git
# =============================================================================
# Private keys are suffixed per context (id_ed25519_reckit, _noon, _dolab...),
# so the pattern must not require the bare name to end there. The .pub variants
# are public and deliberately still readable.
# Enumerate the env suffixes that actually carry secrets rather than matching
# `.env.*` wholesale — .env.example / .sample / .template are committed
# templates, and blocking those breaks ordinary work for no security gain.
secret='\.env($|[^.a-zA-Z])|\.env\.(local|production|prod|development|dev|staging|stage|test|secret)|id_ed25519[A-Za-z0-9_-]*([[:space:]]|$)|id_rsa[A-Za-z0-9_-]*([[:space:]]|$)|\.pem([[:space:]]|$)|\.p12|\.jks|\.keystore|credentials\.json'

match "(cat|bat|less|more|head|tail|xxd|strings|base64|cp|scp)[[:space:]][^|;&]*($secret)" \
  && deny "Printing or copying secret material is blocked. Reference the path, not its contents."

match "git[[:space:]][^|;&]*add[[:space:]][^|;&]*($secret)" \
  && deny "Staging secret material is blocked. Add it to .gitignore instead."

# =============================================================================
# E. Outward-facing / irreversible publishing
# =============================================================================
match '(npm|pnpm|yarn)[[:space:]]+publish' \
  && deny "Publishing a package is outward-facing and irreversible. Manual only."

match 'gh[[:space:]]+repo[[:space:]]+delete|gh[[:space:]]+release[[:space:]]+delete|gh[[:space:]]+secret[[:space:]]+delete' \
  && deny "Deleting a GitHub repo, release or secret is blocked. Manual only."

match '(vercel|wrangler|fly|railway|eas)[[:space:]][^|;&]*(deploy|publish|submit)[^|;&]*--prod|vercel[[:space:]][^|;&]*--prod' \
  && deny "Production deploy is blocked. Use a preview environment, or run it yourself."

match 'supabase[[:space:]]+db[[:space:]]+reset|drop[[:space:]]+database|DROP[[:space:]]+TABLE|TRUNCATE[[:space:]]+TABLE' \
  && deny "Destructive database operation is blocked."

exit 0
