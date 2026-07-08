---
description: >-
  Review the pending changes for reuse, simplification, efficiency, and
  altitude cleanups, then apply the fixes. Quality only — /code-review hunts
  bugs; this does not.
  Usage: /simplify [path or scope hint]
---

Simplify the pending changes. Scope hint (may be empty): $ARGUMENTS

!`git status --short && echo --- && git diff HEAD --stat | tail -5`

Scope: the pending diff (staged + unstaged + untracked source files), or the
paths in the scope hint. Only code the diff touched — do not refactor
neighboring code that happens to be imperfect.

## What to look for
- **Reuse**: the diff reimplements something that already exists in the
  codebase (helper, util, existing pattern) — replace with the existing thing.
  Search before concluding it doesn't exist.
- **Simplification**: needless indirection, single-use abstractions, dead
  branches, conditions that collapse, cleverness where plain code reads
  better. The test: would the next reader get it faster after the change?
- **Efficiency**: obvious waste on a hot or repeated path — N+1 calls,
  re-computation in loops, loading everything to use one field. Skip
  micro-optimizations on cold paths.
- **Altitude**: logic sitting at the wrong level — validation in the render
  layer, business rules in a route handler, config hardcoded where a
  parameter exists.
- **Consistency**: the diff diverges from the file's established naming,
  error handling, or idiom without reason.

Not in scope: bugs (that's /code-review), style-only churn a formatter would
fix, and rewrites that change behavior. Every edit here must be
behavior-preserving.

## Apply
1. Collect candidate cleanups first; discard any where the "simpler" version
   loses a real property (error detail, laziness, type narrowing).
2. Apply the survivors with the Edit tool — smallest diff that achieves each
   cleanup, matching the surrounding style.
3. Re-run whatever fast checks the project has (typecheck, lint, targeted
   tests) to confirm nothing regressed. If a check fails, revert that edit —
   never leave the tree worse than you found it.

## Output
- One line per applied cleanup: `file:line — what changed and why it's better`.
- One line per considered-and-rejected candidate worth mentioning (max 3).
- If the diff is already clean, say exactly that and stop — do not invent work.
