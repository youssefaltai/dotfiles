---
description: >-
  Deep research — fan-out web searches, fetch sources, adversarially verify
  claims, synthesize a cited report. Usage: /deep-research <question>
---

Run the deep-research pipeline on this question:

$ARGUMENTS

## Preferred path: the deterministic engine
If a `deep_research` tool is available (registered by
`plugins/deep-research.ts`), use it instead of orchestrating manually:
1. If the question is empty or too underspecified to research (e.g. "what car
   should I buy" with no budget/use-case/region), ask 2-3 clarifying questions
   and STOP — wait for answers.
2. Call `deep_research` with the refined, self-contained question.
3. Present its report to the user in full — keep all findings, confidence
   labels, sources, caveats, and the refuted-claims section.

Only if that tool is NOT available, fall back to the manual pipeline below.

## Fallback: manual orchestration
You are the orchestrator. You do NOT search or fetch anything yourself — all
web work is done by subagents via the `task` tool. Your job is decomposition,
deduplication, tallying, and synthesis. Follow the phases exactly.

## Tuning constants
- ANGLES = 5 search angles
- MAX_SOURCES = 15 sources fetched (across all angles, after dedup)
- MAX_CLAIMS = 12 claims verified (the plugin engine uses 25 — manual
  orchestration keeps a smaller budget on purpose)
- VOTES = tiered: 3 verifier votes per `central` claim, 1 per
  `supporting`/`tangential` claim; a majority of the assigned votes refuting
  (2-of-3 or 1-of-1) kills the claim

## Phase 0 — Scope
If the question above is empty or too underspecified to research (e.g. "what
car should I buy" with no budget/use-case/region), ask 2-3 clarifying
questions and STOP — wait for answers before proceeding.

Otherwise decompose the question into ANGLES distinct web-search angles that
together cover it from different directions. Pick angles suited to the domain,
e.g.:
- general: broad/primary · academic/technical · recent news · contrarian/skeptical · practitioner/implementation
- medical: anatomy · common causes · serious differentials · authoritative refs · red flags
- tech: state-of-art · benchmarks · limitations · industry adoption · cost/tradeoffs

Make each query specific enough to surface high-signal results; avoid
redundancy. Briefly show the user the angles before continuing.

## Phase 1 — Search (parallel)
Spawn ANGLES `web-searcher` subagents IN A SINGLE MESSAGE (parallel `task`
calls, one per angle). Each prompt must include: the original question
verbatim, the angle label and rationale, and the search query.

## Phase 2 — Dedup + Fetch (parallel)
1. Pool all returned results. Normalize URLs (lowercase, strip `www.`, strip
   trailing slash, ignore query strings) and drop duplicates — keep the first
   occurrence.
2. Sort by relevance (high > medium > low) and keep the top MAX_SOURCES.
3. Spawn one `source-extractor` subagent per kept source, in parallel batches
   of ~5 `task` calls per message. Each prompt must include the original
   question, the URL, the title, and which angle found it.
4. Tell the user how many sources were dropped as dupes or over budget —
   never truncate silently.

## Phase 3 — Adversarial verify (parallel)
1. Pool all extracted claims. Rank by importance (central > supporting >
   tangential), tie-break by source quality (primary > secondary > blog >
   forum > unreliable). Keep the top MAX_CLAIMS.
2. For each kept claim spawn its assigned number of independent
   `claim-verifier` subagents (3 for `central` claims, 1 otherwise). Batch the
   `task` calls in parallel (~6 per message). Each prompt must include: the
   question, the claim, its source URL and quality rating, its supporting
   quote, and an assigned lens so voters don't duplicate work — voter 1: hunt
   contradicting evidence; voter 2: textual support / source quality (no web
   search); voter 3: recency. Single-vote claims get the contradicting-evidence
   lens. Do NOT tell voters how other voters voted.
3. Tally per claim, three outcomes: REFUTED if a majority of assigned votes
   refuted; CONFIRMED only if a majority of assigned votes are valid AND
   non-refuting (3-vote claims: ≥2 supporting votes; 1-vote claims: 1
   supporting vote — a 1-1 split with a failed third voter is contested, not
   confirmed); otherwise UNVERIFIED. A subagent that failed or returned
   garbage is an abstention, not a pass or a refutation — report unverified
   claims separately, never as refuted.
4. If zero claims were extracted, or all claims are refuted, report that
   honestly (with the vote tallies) and stop — do not pad the report.

## Phase 4 — Synthesize
Write the final report yourself from the surviving claims:
1. Merge claims that say the same thing; combine their sources.
2. Group related claims into findings that directly address the question.
3. Confidence per finding: **high** = multiple primary sources + unanimous
   votes · **medium** = secondary sources or split votes · **low** = single
   source or blog-quality.

Report format:
- **Executive summary** — 3-5 sentences answering the question.
- **Findings** — each with confidence, evidence, vote tally, and source URLs.
- **Refuted claims** — one line each (claim, vote, source) for transparency.
- **Caveats** — what's uncertain, weak sources, time-sensitivity.
- **Open questions** — 2-4 that emerged but weren't answered.
- **Stats** — angles / sources fetched / claims extracted / verified /
  confirmed / killed.
