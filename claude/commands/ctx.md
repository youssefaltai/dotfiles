---
description: Brief me on a context — what's in flight, what's blocked, what's next
argument-hint: "[context name, or blank for the current directory]"
allowed-tools: Bash, Read, Glob, Grep
---

Re-entering a context after working in a different one costs the most time of
anything in this workflow. Reconstruct the state of `$1` (or the current
directory's context if no argument) so work can resume immediately.

## Gather

Run these; do not ask before running them, they are all read-only.

1. `ctx which` (or `ctx which ~/work/$1`) — identity, GitHub account, Claude
   profile, stack, rails. State plainly if the active Claude profile does not
   match the context.
2. Read the matching file in `~/work/personal/life/contexts/` — conventions,
   people, current focus, anything marked TODO.
3. For each git repo in the context directory:
   - current branch, and whether the tree is dirty (`git status --short`)
   - unpushed commits (`git log @{u}.. --oneline`), if an upstream exists
   - last 5 commits with relative dates
   - stashes (`git stash list`)
4. Open PRs authored by this context's account:
   `GH_CONFIG_DIR=~/.config/<gh_config> gh pr list --author @me --state open`
   plus review-requested ones. Use the context's own gh profile, not the default.
5. If a Linear MCP is connected, the issues assigned to this person that are in
   progress.

## Report

Lead with **what is in flight** — dirty trees, unpushed commits, open PRs,
in-progress issues. That is what the next hour is spent on.

Then **what is blocked or waiting** — PRs awaiting review, review requests
owed to others, anything stale for more than a few days.

Then **what is next**, from the context file's current-focus section.

Rules:
- Absolute dates and real numbers ("3 unpushed commits, oldest 2026-07-28"),
  never "recently" or "a few".
- If a repo is clean and has nothing open, say so in one line. Do not pad.
- If the context file's current-focus section is still `TODO`, say that
  explicitly and offer to fill it in from what you just found.
- Do not modify anything. This command reads.
