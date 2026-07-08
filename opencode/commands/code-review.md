---
description: >-
  Review a diff for real bugs and worthwhile cleanups — parallel reviewer
  lenses, then adversarial verification of every finding. Usage:
  /code-review [scope] where scope is a git range (main..HEAD), "staged",
  a commit, or empty for auto (working tree if dirty, else branch vs main).
---

Run the code-review pipeline on this scope:

$ARGUMENTS

You are the orchestrator. You do NOT hunt for bugs yourself — reviewing is
done by subagents via the `task` tool. Your job is scoping, deduplication,
verification tallying, and the final report. Follow the phases exactly.

## Tuning constants
- LENSES = 4 reviewers: correctness, security, contracts, simplification
- MAX_FINDINGS = 12 findings verified (rank first, never truncate silently)
- VOTES = tiered: 2 independent `finding-verifier` votes per high-severity
  finding, 1 per medium/low; any refutation kills a 1-vote finding, and a
  high-severity finding survives only with 2 confirmations (confirmed +
  uncertain = downgrade to "unverified", report separately)

## Phase 0 — Scope
Resolve what to review, cheaply (`git status`, `git diff --stat` only — do
not read the full diff yourself):
- Scope argument given: use it verbatim — a git range or commit is passed to
  reviewers as `git diff <scope>`; "staged" as `git diff --cached`.
- No argument: if the working tree is dirty (staged, unstaged, or untracked
  files), review that (`git diff HEAD` + untracked files); otherwise review
  the branch (`git diff $(git merge-base main HEAD)..HEAD`; try `master` if
  `main` doesn't exist, and if the branch IS main with a clean tree, review
  the last commit `git diff HEAD~1..HEAD`).
- Empty diff → say so and stop.
Tell the user the resolved scope and its size (files/insertions/deletions)
before continuing. If the diff is huge (>~3000 lines), warn and ask whether
to proceed or narrow.

## Phase 1 — Review (parallel)
Spawn LENSES `code-reviewer` subagents IN A SINGLE MESSAGE (parallel `task`
calls, one per lens). Each prompt must include: the exact git command for the
scope, the list of untracked files to also read (working-tree scope only),
the assigned lens name, and a note of anything the user said to focus on.

## Phase 2 — Dedup + rank
1. Pool all findings. Two findings are duplicates when they point at the same
   defect (same file and overlapping lines, or same root cause) — keep the
   clearer one, note both lenses caught it (that raises confidence).
2. Rank by severity (high > medium > low), tie-break: correctness/security
   over contracts over simplification. Keep the top MAX_FINDINGS; if any were
   dropped over budget, tell the user how many — never truncate silently.
3. Zero findings → report that honestly with the scope stats and stop.

## Phase 3 — Adversarial verify (parallel)
For each kept finding spawn its assigned number of independent
`finding-verifier` subagents (2 for high severity, 1 otherwise), batched
(~6 `task` calls per message). Each prompt must include the finding's full
JSON, the scope's git command, and — for 2-vote findings — an assigned lens
so voters don't duplicate work: voter 1 traces reachability of the failure
path; voter 2 checks the evidence quotes and whether it's pre-existing
rather than introduced. Do NOT tell voters how other voters voted, and do
NOT batch multiple findings into one verifier call.

Tally per the VOTES rule. A verifier that failed or returned garbage is an
abstention, not a confirmation — a finding missing its required votes is
"unverified", never "confirmed". Apply any `corrected_severity` from a
confirming majority.

## Phase 4 — Report
Report to the user (do not edit any files — offer fixes only if asked):
- **Confirmed findings** — most severe first: severity, `file:line`,
  summary, concrete failure scenario, verifier evidence, and which lens(es)
  found it.
- **Unverified** — findings with an "uncertain" outcome: one line each, with
  what would be needed to confirm.
- **Refuted in verification** — one line each (finding → why it died), for
  transparency.
- **Stats** — scope · diff size · findings found / deduped / verified /
  confirmed / refuted.
Close by offering to apply fixes for the confirmed findings.
