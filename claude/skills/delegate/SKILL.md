---
name: delegate
description: Protocol for running a task end-to-end without supervision. Use when Youssef hands over a whole piece of work and goes to do something else — anything phrased as "handle this", "take care of X", "do this while I...", or any multi-step task in an employer or client repo.
---

# Delegating a task end-to-end

Youssef runs two full-time jobs plus client work. The value here is being able
to hand over a whole task and stop thinking about it. That only works if the
result can be trusted without re-checking — so the bar is not "produced
something", it is "produced something verified, with the blast radius bounded
and the trail visible".

## 1. Establish the contract before touching anything

Write down, in one short block:

- **Goal** — what "done" means, observably. If that cannot be stated
  concretely, the task is not yet specified: ask now, before doing work.
- **Scope** — what is explicitly *not* included. Delegated tasks drift.
- **Verification** — what will be run to prove it works. Decide this *first*;
  choosing it afterward biases toward whatever happens to pass.

If the task is ambiguous in a way that changes the work, ask **once**, up
front, with your recommended default — not halfway through.

## 2. Bound the blast radius

- `ctx which` first. Confirm the context, and that the active Claude profile
  matches it. Employer and client repos run under strict rails.
- Never start from a dirty tree. If `git status` is not clean, stop and report
  — those changes are not yours and you may not know what they are.
- Work on a feature branch, never a shared trunk.
- For anything touching an employer or client repo, or anything wide-reaching,
  use a **worktree** so the main checkout is untouched.
- Commit at meaningful checkpoints so there is always a point to return to.

## 3. Do the work

Follow `~/.claude/working-rules.md` — it is not optional, and it governs.
In particular:

- Measure, do not theorise. A mechanism found by reading is a hypothesis.
- Prefer the cheapest, most likely explanation first.
- Read the whole error before acting on its first line.
- Change one variable at a time when isolating a cause.

## 4. Verify before claiming done

Run what you said you would in step 1. Then:

- **Calibrate every negative.** "No errors", "not found", "tests pass" mean
  nothing until you have shown the check can fail. Run it against a known-bad
  case. Most false completions come from an uncalibrated negative.
- Check counts, not just exit codes. How many tests ran? Did any skip?
- For per-context changes, verify in more than one context.
- On anything substantial, hand the claims to the **verifier** agent before
  reporting.

## 5. Report

Structure, always in this order:

1. **What was done** — and what it changes for the user.
2. **How it was verified** — the exact commands and their real output. Not
   "tested and working".
3. **What was NOT done** — skipped, blocked, out of scope, or left for a human.
   This section is mandatory. If it is genuinely empty, say "nothing".
4. **What needs a human** — decisions, credentials, interactive logins,
   anything the guard blocked.

Never report as done what is partially done. A task reported at 90% with the
missing 10% named is useful; one reported at 100% that is actually 90% costs
more than not doing it.

## When to stop and ask

Stop, report, and wait — do not improvise — if:

- The guard blocks something and the workaround would defeat its purpose.
- The task needs a credential, an interactive login, or an outward-facing
  action that was not authorised.
- What you find contradicts the premise of the task.
- Finishing would need a destructive operation on someone else's work.

Stopping with a clear question costs minutes. Guessing wrong in an employer
repo costs far more.
