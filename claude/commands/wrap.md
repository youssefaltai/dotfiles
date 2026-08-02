---
description: End-of-day sweep — nothing uncommitted, unpushed, or forgotten across all contexts
allowed-tools: Bash, Read, Glob, Grep
---

Sweep **every** context, not just the current one. Working across two full-time
jobs plus client work means uncommitted work in a context you last touched
this morning is easy to lose track of entirely.

## Gather (read-only)

For each context in `ctx list`, for each git repo underneath it:

- dirty working tree — `git status --short` (count files, name the notable ones)
- unpushed commits — `git log @{u}.. --oneline` where an upstream exists
- branches with no upstream at all — work that exists only on this machine
- stashes — `git stash list`, with age
- open PRs authored by that context's account, and any review requests owed

Also check: `ctx check` for drift, and whether `~/.config` itself has
uncommitted changes.

## Report

Order by risk — **work that exists in only one place first**:

1. Uncommitted changes and branches with no remote. This is the only category
   that a disk failure destroys. Say exactly which repo and how many files.
2. Committed but unpushed.
3. Open PRs and review requests owed to others.
4. Config drift (`ctx check`, dotfiles status).

Then, one line: **tomorrow's first thing** — the single most obvious next
action from what is in flight.

Rules:
- Real counts and absolute dates.
- If everything is clean, say so in one line per context. Do not manufacture
  concern.
- **Do not commit, push, or stash anything.** This command reports; the human
  decides. Offer the specific commands if something needs doing.
