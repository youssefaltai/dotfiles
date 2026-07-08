---
description: >-
  Verify that a code change actually works by exercising it end-to-end and
  observing real behavior — not just tests or typechecks.
  Usage: /verify [what to verify — defaults to the pending changes]
---

Verify this change works: $ARGUMENTS

!`git status --short | head -20`

The bar: **observed behavior, not inference**. A typecheck passing, code
"looking right", or unit tests that don't touch the changed path do not count
as verification.

## Steps
1. **Identify the affected flow.** From the pending diff (or the description
   above), determine what user-visible or caller-visible behavior changed.
   If the diff touches only tests/docs with no runtime surface, say so and
   STOP — there is nothing to drive.
2. **Find the project's own way to run.** Check the project for run
   instructions (AGENTS.md, README, package.json scripts, Makefile, mise
   tasks) and prefer those over guessing.
3. **Drive the flow.** Run the app/CLI/server and exercise the changed path
   with real input: invoke the CLI with the flag that changed, hit the
   endpoint that was modified, render the screen that was edited. Long-running
   processes: start them, probe them, then shut them down cleanly.
4. **Observe and compare.** Capture the actual output/response/render and
   check it against what the change was supposed to do. Also probe one
   adjacent case the change could plausibly have broken.
5. **Run the relevant tests** (the targeted subset, not the whole suite unless
   it's fast) as a supplement — never as the sole evidence.

## Output
- **Verdict:** verified / broken / partially verified — first line.
- **Evidence:** the command(s) run and the observed output that proves it,
  trimmed to the deciding lines.
- If broken: what was expected vs what happened, and where it diverges —
  report it; do not silently start fixing unless asked.
- If verification was impossible (missing creds, no runnable entry point),
  say exactly what blocked it and what you checked instead. Never present
  inference as observation.
