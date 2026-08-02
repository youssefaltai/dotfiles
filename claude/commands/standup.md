---
description: Draft a standup / status update for the current context
argument-hint: "[since when, e.g. yesterday, 3d, 2026-07-28 — default: since yesterday]"
allowed-tools: Bash, Read, Glob, Grep
---

Draft a status update for the current context covering `$1` (default: since
yesterday). Two full-time roles plus client work means writing these several
times over, from the same underlying activity — so derive it from evidence
rather than from memory.

## Gather (read-only)

1. `ctx which` — which context, and therefore which audience and which gh profile.
2. Commits by this person in that window, across every repo in the context:
   `git log --author=<context email> --since=<window> --oneline --all`
3. PRs opened, merged, or reviewed in the window, via the context's gh profile.
4. Current branch state — what is in progress but not yet pushed.
5. If a Linear MCP is connected, issues that changed status in the window.

## Write

Three sections, in this order:

- **Done** — what actually landed. Each item traceable to a commit, PR, or
  issue. Describe the user-visible change, not the diff ("import events now
  surface upload progress", not "refactored the upload handler").
- **In progress** — what is underway, with honest state. If something has been
  in progress for several days, say so rather than restating it as new.
- **Blocked / needs input** — anything waiting on review, a decision, access,
  or another person. Name who, if known.

Rules:
- Match the audience. Reckit and noon are different teams who do not know about
  each other's work — never leak one context's detail into another's update.
- Plain language. No "leveraged", no "circled back".
- If nothing landed in the window, say that. A padded standup is worse than a
  short one.
- Output as plain text ready to paste into Slack. Do not send it anywhere.
- Flag anything you could not verify rather than asserting it.
