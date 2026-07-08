---
description: >-
  Fast fact-check — verify one specific claim with paired confirm/refute
  searches, escalating to a verifier panel only if contested.
  Usage: /fact-check <claim>
---

Fact-check this claim:

$ARGUMENTS

You are verifying ONE specific claim quickly and reliably. This is the
lightweight sibling of /deep-research — no fan-out, no report. Do the quick
pass yourself; spawn subagents only to break a genuine tie.

## Phase 0 — Scope
- If the claim above is empty, or it is an open-ended question rather than a
  checkable statement (e.g. "what's the best X"), say so, point to
  /deep-research, and STOP.
- If it is ambiguous in a way that changes the answer (missing version, date,
  region, units), ask ONE clarifying question and STOP.
- Otherwise restate it as a single falsifiable sentence before checking.

## Phase 1 — Quick pass (yourself, inline — no subagents)
1. Run TWO `websearch` calls: one phrased to CONFIRM the claim, one phrased to
   REFUTE it (e.g. append "false", "debunked", "criticism", or search for the
   opposite statement).
2. `webfetch` the 1-2 highest-quality results — prefer primary sources
   (official docs, papers, standards, first-party announcements) over
   secondary coverage; skip SEO spam and content farms. For time-sensitive
   claims check publish dates; stale evidence weakens the verdict.
3. Judge:
   - **confirmed** — credible supporting evidence, no credible contradiction.
   - **refuted** — credible contradicting evidence outweighs support.
   - **unverifiable** — no sufficiently credible evidence either way.
   - **contested** — credible sources genuinely disagree → go to Phase 2.

Only a genuine conflict between credible sources escalates. Confirmed,
refuted, and unverifiable all end here.

## Phase 2 — Tiebreak panel (only if contested)
Spawn 3 `claim-verifier` subagents IN A SINGLE MESSAGE (parallel `task`
calls). Each prompt must include: the claim (as both the research question and
the claim under review), the best supporting source URL + its quality rating +
a supporting quote from Phase 1, and the contradicting source URL you found.
Do NOT tell voters how other voters voted.

Tally by each voter's `verdict` field (a failed/garbage subagent is an
abstention, never a pass):
- ≥2 "refuted" → **refuted**
- ≥2 "supported" → **confirmed**
- ≥2 "unverifiable" → **unverifiable**
- anything else (splits/abstentions) → **contested** — report that honestly
  with the vote tally; do not force a verdict.

## Output — one screen, no report
- **Verdict:** confirmed / refuted / contested / unverifiable, with confidence
  (high/medium/low) and the vote tally if Phase 2 ran.
- **Why:** 1-3 sentences including the deciding quote.
- **Sources:** the 1-3 URLs that decided it, each marked primary/secondary.
- **Counter-evidence:** one line, if any credible contradiction was found.
- **Caveat:** one line only if time-sensitive or the sources were weak.
