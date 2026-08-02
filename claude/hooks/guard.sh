#!/usr/bin/env bash
# Claude Code PreToolUse guard — shared by every Claude profile on this machine.
#
# SCOPE, and why it is this narrow:
#
#   This guard covers exactly one thing — the intersection of
#     {commands settings.json auto-approves} AND {damage that cannot be undone}.
#
#   Everything else is deliberately NOT here. `rm`, `dd`, `mkfs`, production
#   deploys and destructive DB commands are not in the allow-list, so Claude
#   Code already prompts on them and a human sees them before they run. Adding
#   guard rules for those bought nothing and cost false positives — the earlier
#   version blocked writing a test harness because the harness *contained* the
#   string `rm -rf`. A guard with false positives gets switched off, which is
#   worse than no guard.
#
#   What IS auto-approved and therefore genuinely unguarded without this file:
#     Bash(git *)   -> reset --hard, clean -fd, push --force, branch -D
#     Bash(gh *)    -> repo/release/secret delete
#     Bash(npm *)   -> publish
#     Bash(find *)  -> -delete, -exec rm
#     Bash(echo *)  -> redirect over this very file
#
# THREAT MODEL: agent error, not a determined adversary. Regex over a command
# string cannot stop deliberate obfuscation (`X=rm; $X -rf`, eval, base64), and
# Bash(python3 *) / Bash(node *) / Bash(make *) can run arbitrary code anyway.
# This is an accident-catcher on a narrow auto-approved surface. It is NOT a
# security boundary — do not treat it as one.
#
# Blocked is not forbidden: anything here, Youssef can run himself in a terminal.
#
# Strictness follows the context, mirroring `strict` in contexts.toml:
# everything under ~/work except ~/work/personal is an employer or client tree.

input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"
cmd="$(printf '%s'  "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
cwd="$(printf '%s'  "$input" | jq -r '.cwd // empty' 2>/dev/null)"
[ -n "$cwd" ] || cwd="$PWD"

[ "$tool" = "Bash" ] || exit 0
[ -n "$cmd" ] || exit 0

deny() { echo "BLOCKED by guard.sh: $1" >&2; exit 2; }

# Match against the command with quoted spans removed. Without this, any string
# that merely MENTIONS a dangerous command is blocked — writing documentation,
# a commit message, or a test harness that contains `git reset --hard` as data.
# That false-positive class is what makes a guard annoying enough to be
# switched off, and it is the dominant one in practice.
#
# The cost is that a genuinely quoted command (`bash -c "git clean -fd"`) slips
# through. That is the obfuscation class, which this guard already concedes it
# cannot cover — see the threat model above. Losing an obfuscation case to gain
# every documentation case is the right trade.
scrubbed="$(printf '%s' "$cmd" | sed -e "s/'[^']*'//g" -e 's/"[^"]*"//g')"
match() { printf '%s' "$scrubbed" | grep -Eiq "$1"; }

strict=0
case "$cwd" in
  "$HOME"/work/personal|"$HOME"/work/personal/*) strict=0 ;;
  "$HOME"/work/*)                                strict=1 ;;
esac
# A command may `cd` into a strict tree from a relaxed one, so also treat any
# explicit mention of a non-personal work path as strict.
if [ "$strict" = "0" ] && match '(~|\$HOME|/Users/[a-z]+)/work/(reckit|noon|dolab-marcom|freelance)'; then
  strict=1
fi

# =============================================================================
# 1. git — destroys uncommitted or unpushed work   [Bash(git *) is auto-approved]
# =============================================================================
match 'git[[:space:]][^|;&]*reset[[:space:]][^|;&]*--hard' \
  && deny "git reset --hard discards uncommitted work. Use 'git stash -u' first, or run it yourself."

match 'git[[:space:]][^|;&]*clean[[:space:]][^|;&]*-[A-Za-z]*[fd]' \
  && deny "git clean deletes untracked files irrecoverably. Review 'git clean -n' first and run it yourself."

match 'git[[:space:]][^|;&]*checkout[[:space:]]+(--[[:space:]]+)?\.([[:space:]]|$)|git[[:space:]][^|;&]*restore[[:space:]][^|;&]*[[:space:]]\.([[:space:]]|$)' \
  && deny "Discarding all local changes is blocked. Stash them instead: git stash -u"

match 'git[[:space:]][^|;&]*branch[[:space:]][^|;&]*-[A-Za-z]*D([[:space:]]|$)' \
  && deny "Force-deleting a branch can lose unmerged commits. Use 'git branch -d', or do it yourself."

match 'git[[:space:]][^|;&]*(filter-branch|filter-repo)|git[[:space:]][^|;&]*reflog[[:space:]]+expire|git[[:space:]][^|;&]*gc[[:space:]][^|;&]*--prune=(now|all)' \
  && deny "History rewriting / reflog expiry destroys the recovery path. Manual only."

# =============================================================================
# 2. git push — rewrites or lands on shared history
# =============================================================================
# `+refspec` is a force push with no --force flag; missing it was a real hole.
if match 'git[[:space:]][^|;&]*push[[:space:]][^|;&]*(--force(-with-lease)?([[:space:]]|=|$)|[[:space:]]-f([[:space:]]|$)|[[:space:]]\+[A-Za-z0-9_./-]*:?)'; then
  [ "$strict" = "1" ] \
    && deny "Force-push is blocked in employer/client repos — it can destroy a colleague's work. Manual only."
  match 'force-with-lease' \
    || deny "Plain --force (or a +refspec) can clobber remote commits. Use --force-with-lease."
fi

if [ "$strict" = "1" ] && match 'git[[:space:]][^|;&]*push'; then
  trunk='main|master|develop|development|production|staging|release'
  branch="$(git -C "$cwd" branch --show-current 2>/dev/null)"
  case "$branch" in
    main|master|develop|development|production|staging|release|release/*)
      deny "Direct push from '$branch' is blocked in an employer/client repo. Work on a feature branch and open a PR." ;;
  esac
  printf '%s' "$cmd" | grep -Eq "push[[:space:]]+[^[:space:]|;&]+[[:space:]]+(\+|HEAD:)?($trunk)([[:space:]]|$|:)" \
    && deny "Pushing directly to a shared trunk is blocked in an employer/client repo. Open a PR instead."
fi

# =============================================================================
# 3. Secrets into git      [Bash(git *) auto-approved; committed secrets persist]
# =============================================================================
# .env.example / .sample / .template are committed templates — enumerate the
# suffixes that actually carry secrets rather than matching .env.* wholesale.
secret='\.env($|[^.a-zA-Z])|\.env\.(local|production|prod|development|dev|staging|stage|test|secret)|id_ed25519[A-Za-z0-9_-]*([[:space:]]|$)|id_rsa[A-Za-z0-9_-]*([[:space:]]|$)|\.pem([[:space:]]|$)|\.p12|\.jks|\.keystore|credentials\.json'
match "git[[:space:]][^|;&]*add[[:space:]][^|;&]*($secret)" \
  && deny "Staging secret material is blocked. Add it to .gitignore instead."

# =============================================================================
# 4. Irreversible outward-facing actions       [Bash(gh *), Bash(npm *) allowed]
# =============================================================================
match 'gh[[:space:]]+(repo|release|secret)[[:space:]]+delete' \
  && deny "Deleting a GitHub repo, release or secret is blocked. Manual only."

match '(npm|pnpm|yarn)[[:space:]]+publish' \
  && deny "Publishing a package is outward-facing and irreversible. Manual only."

# =============================================================================
# 5. find as a deletion tool                          [Bash(find *) auto-approved]
# =============================================================================
match 'find[[:space:]][^|;&]*(-delete|-exec[[:space:]]+rm|-execdir[[:space:]]+rm|-ok[[:space:]]+rm)' \
  && deny "find used to delete in bulk is blocked. List the matches first, then remove specific paths yourself."

# =============================================================================
# 6. Self-protection — the guard and settings must not be edited by the agent
# =============================================================================
# settings.json deny rules cover the Edit tool; these cover the shell, where
# Bash(echo *) would otherwise let `echo "exit 0" > guard.sh` disable everything.
match '(>|>>|tee|cp|mv|install|sed[[:space:]]+-i|chmod|chown|rm|ln)[^|;&]*(\.config/claude/(hooks/|statusline\.sh|session-start\.sh|settings\.)|\.claude(-[a-z]+)?/settings\.json)' \
  && deny "Modifying the guard, its hooks, the statusline or settings.json from the shell is blocked. That is a human action."

match 'CLAUDE_CODE_OAUTH_TOKEN' \
  && deny "Setting CLAUDE_CODE_OAUTH_TOKEN can destroy the Keychain login."

exit 0
