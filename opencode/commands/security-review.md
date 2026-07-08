---
description: >-
  Security review of the pending changes on the current branch (or a given
  scope) — findings verified adversarially before reporting.
  Usage: /security-review [path or scope hint]
---

Run a security review. Scope hint (may be empty): $ARGUMENTS

!`git status --short && echo --- && git diff HEAD --stat | tail -5`

## Phase 0 — Scope
- Default scope: pending changes on the current branch (staged + unstaged +
  untracked source files). If a scope hint names paths, review those instead.
- If there are no pending changes and no scope hint, say so and STOP — do not
  wander into a whole-repo audit uninvited.
- Read the full diff (`git diff HEAD`, plus untracked files) before judging
  anything. Pull surrounding context with Read for every flagged hunk — most
  false positives die on the next 20 lines of context.

## Phase 1 — Review (yourself, inline)
Work through the security lenses that apply to the diff; skip irrelevant ones:
- **Injection**: SQL/command/template injection; unsanitized input reaching
  shells, queries, eval, deserializers.
- **AuthN/AuthZ**: missing/weakened checks, privilege paths, insecure-direct
  object references, trust-boundary crossings.
- **Secrets**: credentials/tokens/keys in code, logs, error messages, or
  committed config; secrets flowing to third parties.
- **Input & path handling**: path traversal, SSRF targets, unsafe file
  writes, zip-slip, prototype pollution.
- **Web**: XSS sinks, CSRF-relevant state changes, unsafe redirects, CORS or
  CSP loosening.
- **Crypto & transport**: home-rolled crypto, weak algorithms/modes, disabled
  TLS verification, predictable randomness in security contexts.
- **Dependencies & config**: new deps with known-bad reputations, debug flags
  or permissive defaults shipping to production.

A finding requires a **concrete attack path**: attacker-controlled input →
mechanism → impact. "This looks unsafe" without a path is not a finding.

## Phase 2 — Adversarial verification
For every high-severity finding, spawn a `finding-verifier` subagent to try to
refute it against the real code (parallel `task` calls, one per finding). Drop
findings the verifier refutes; mark unresolved disagreements as "uncertain".
Low/medium findings: verify yourself by re-reading the code path end to end.

## Output
- **Verdict line**: N findings (H/M/L split) or a clean bill for the reviewed
  scope — scope stated explicitly.
- Per finding: severity, `file:line`, the attack path in 1-2 sentences, and a
  concrete fix. Most severe first.
- Do NOT edit any files — this command reports; fixing is a separate request.
- No filler advice ("consider adding rate limiting") untethered to the diff.
