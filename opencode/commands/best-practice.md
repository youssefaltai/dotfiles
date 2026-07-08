---
description: >-
  Best-practice finder — research the internet for the CURRENT official
  recommendation / industry standard on a topic and return ONE recommendation,
  the evidence that supports it, and why each alternative was rejected.
  Usage: /best-practice <topic or decision>
---

Today's date: !`date +%Y-%m-%d`

Find the current best practice / industry standard for:

$ARGUMENTS

You are settling a DECISION, not writing a survey. The deliverable is exactly
one recommendation, every piece of evidence that supports it, and an explicit
evidence-backed rejection of every other candidate. Your training data is
assumed stale for this — every load-bearing statement must trace to a source
fetched TODAY, and recency is judged against today's date above.

## Ground rules (apply to every phase)
- **Neutral queries**: never name specific candidate tools/products in the
  initial searches — naming candidates biases results toward them. Describe
  the capability ("state management library for React 19") and let candidates
  emerge from the results. Once candidates have emerged from a neutral pass,
  targeted by-name follow-ups for detail are fine.
- **Authority ladder** (higher beats lower when sources disagree):
  1. Official docs, specs, standards bodies (RFCs, W3C, OWASP, NIST, vendor
     documentation for the tool in question)
  2. Release notes, changelogs, deprecation notices, maintainer announcements
  3. Reputable industry surveys/reports (State of JS/DevOps, Thoughtworks
     Radar, etc.) and maintainer/core-team blog posts
  4. Practitioner consensus (conference talks, high-quality blogs)
  5. Forum threads (SO, HN, Reddit) — corroboration only, never the sole basis
- **Recency**: check publish dates on everything. For fast-moving ecosystems,
  guidance older than ~18 months is suspect until re-confirmed against a
  current official source. Explicitly search for deprecation or
  "no longer recommended" signals against whatever you're about to recommend.

## Phase 0 — Scope
- If the topic above is empty, ask for it and STOP.
- If the answer depends on unstated context (ecosystem/language, version,
  scale, greenfield vs existing codebase, team constraints), ask 2-3
  clarifying questions and STOP — a "best practice" without context is how
  wrong recommendations happen.
- Otherwise restate it as a single decision question pinned to today's date
  and the relevant versions, e.g. "As of <today>, what is the officially
  recommended way to do X in Y version Z?". Show it to the user, then proceed.

## Phase 1 — Research

### Preferred path: the deterministic engine
If a `deep_research` tool is available (registered by
`plugins/deep-research.ts`), call it ONCE with the refined decision question,
augmented so the pipeline inherits the rules above. Pass a question of this
shape:

> As of <today's date>, what is the officially recommended / industry-standard
> approach for <decision>? Prioritize official documentation, standards
> bodies, and maintainer guidance over blogs and forums; check publish dates
> and current deprecation status; identify ALL viable candidate approaches
> (do not assume a shortlist) and the evidence for and against each.

### Fallback: manual orchestration
Only if the tool is unavailable. You are the orchestrator — you do not search
or fetch anything yourself; all web work happens in subagents via `task`.
Reuse the /deep-research phases (search → dedup/fetch → adversarial verify)
with the same tuning constants, but FIX the five angles to:
1. **Official guidance** — what do the official docs / standard say today?
2. **Current state** — what changed recently? (include the current year in
   the query; release notes, "what's new", migration guides)
3. **Candidates** — neutral capability-described query to surface ALL viable
   options (no candidate names in the query)
4. **Deprecations & criticism** — anti-patterns, "no longer recommended",
   known pitfalls of the leading approaches
5. **Adoption** — industry surveys, what practitioners actually use in
   production

Then run /deep-research Phases 2-3 unchanged: dedup + fetch via
`source-extractor` subagents, adversarial verification via `claim-verifier`
subagents (tiered: 3 lens-diverse votes per central claim, 1 otherwise; a
majority of refutations kills). Claims about what is "recommended" or
"standard" MUST carry a source-backed quote and date.

## Phase 2 — Decide
Work only from claims that survived verification:
1. Enumerate every candidate approach that emerged from the research.
2. Score each against: official endorsement (authority ladder) · recency of
   that endorsement · real-world adoption · absence of deprecation/criticism
   signals.
3. Pick ONE recommendation only if the evidence genuinely converges on it.
   If credible current sources genuinely disagree, say so — report the top
   contenders with the evidence split and the conditions under which each
   wins. Never force a winner the evidence doesn't support, and never fall
   back to your training-data prior to break a tie.
4. Recency gate: the recommendation must be corroborated by at least one
   verified source that is either official or dated within the last 12
   months. If it isn't, label the recommendation stale-risk explicitly.

## Output
- **Recommendation** — one sentence, phrased "As of <today's date>, ...",
  with confidence (high/medium/low) and what that confidence rests on.
- **Evidence** — every verified finding that supports the recommendation:
  claim, source URL, source tier (official/secondary/etc.), publish date,
  vote tally if verified by panel. All of it — this section is the point.
- **Rejected alternatives** — one entry per other candidate: what it is, why
  it was NOT chosen, and the specific evidence (source + date) behind the
  rejection. "Less popular" is not a rejection; a dated, sourced reason is.
- **What changed recently** — anything in the last ~18 months that would
  surprise someone whose knowledge is a year old (new official guidance,
  deprecations, a former best practice dethroned).
- **Caveats** — contexts where the recommendation flips, weak spots in the
  evidence, time-sensitivity.
- **Refuted claims** — one line each, for transparency (from the verify
  phase).
- **Sources** — full list with tier and date.
