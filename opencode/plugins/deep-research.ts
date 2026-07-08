// deep-research.ts — OpenCode plugin registering a `deep_research` custom tool.
//
// Deterministic port of Claude Code's deep-research Workflow script:
//   Scope → pipeline(Search → URL-dedup → Fetch+Extract) → claim-dedup →
//   tiered adversarial Verify (3 lens-diverse votes for the top central
//   claims, 1 for the rest) →
//   Synthesize. Orchestration (loops, dedup, budgets, vote tallies) runs as
//   code here; only the leaf work (search/fetch/verify/synthesize) is done by
//   LLM subagents, driven via the SDK as child sessions of the caller.
//
// Requires the subagent definitions in ../agent/:
//   web-searcher.md · source-extractor.md · claim-verifier.md ·
//   research-analyst.md (tool-less; scoping + synthesis)
//
// Install: place in ~/.config/opencode/plugins/ and restart opencode.

import type { Plugin } from "@opencode-ai/plugin"
import { tool } from "@opencode-ai/plugin"

// ─── Tuning (mirrors the original workflow constants) ───
const VOTES_PER_CLAIM = 3 // votes for CENTRAL claims; lesser claims get 1 (see panel assignment)
const MAX_FETCH = 15
const HIGH_CARVEOUT_PER_ANGLE = 2 // high-relevance fetches allowed past the budget, per angle (searchers over-rate "high"; unlimited carve-out let a run fetch 25/15)
const MAX_VERIFY_CLAIMS = 25
const MAX_CENTRAL_PANELS = 8 // claims that get the full 3-voter panel; extractors rate ~everything "central", which made tiered voting dead code (25×3 = 75 verifier sessions)
const MAX_CLAIMS_PER_SOURCE = 5 // one source can't flood the verify pool (original EXTRACT_SCHEMA maxItems)
const CONCURRENCY = 8 // simultaneous subagent sessions (OpenRouter rate-limit guard)
const JSON_RETRIES = 1 // re-prompts when a subagent returns malformed JSON

// ─── Types ───
type Relevance = "high" | "medium" | "low"
type SourceQuality = "primary" | "secondary" | "blog" | "forum" | "unreliable"
type Importance = "central" | "supporting" | "tangential"

interface SearchResult { url: string; title: string; snippet?: string; relevance: Relevance }
interface Claim { claim: string; quote: string; importance: Importance; sourceUrl: string; sourceQuality: SourceQuality }
interface Verdict { refuted: boolean; evidence: string; confidence: "high" | "medium" | "low"; counterSource?: string }

const relRank: Record<Relevance, number> = { high: 0, medium: 1, low: 2 }
const impRank: Record<Importance, number> = { central: 0, supporting: 1, tangential: 2 }
const qualRank: Record<SourceQuality, number> = { primary: 0, secondary: 1, blog: 2, forum: 3, unreliable: 4 }
const confRank: Record<Verdict["confidence"], number> = { high: 0, medium: 1, low: 2 }

// Tiered voting: full panel only where it matters. Verification is the cost
// center of a run (every vote is a live-websearch subagent), so only the top
// MAX_CENTRAL_PANELS central claims (in ranked order) get VOTES_PER_CLAIM
// votes; everything else gets a single vote. The cap exists because the
// ranking pipeline selects FOR central claims (per-source cap and global
// slice both keep the most important first), so "central" alone can't gate
// the panel — in practice the whole pool qualifies.

// Lens per voter index — three near-identical skeptics re-run the same search;
// diverse lenses buy better failure-mode coverage for the same votes. Index 0
// (the lens single-vote claims get) is the strongest general-purpose check.
const VERIFY_LENSES = [
  "hunt for CONTRADICTING EVIDENCE — websearch for credible sources that dispute, correct, or heavily qualify the claim (checklist item 2)",
  "check TEXTUAL SUPPORT — judge from the material given whether the quote actually supports the claim and whether the source quality matches its strength (checklist items 1, 3, 5); no web search needed",
  "check RECENCY — websearch for newer developments that supersede or outdate the claim (checklist item 4)",
]

// ─── Small helpers ───
function normURL(u: string): string {
  try {
    // Lowercase only the host: paths are case-sensitive on many sites, and the
    // query string distinguishes real pages (youtube.com/watch?v=A vs ?v=B) —
    // stripping either merges distinct sources. Only the fragment is dropped.
    const p = new URL(u)
    return p.hostname.toLowerCase().replace(/^www\./, "") + p.pathname.replace(/\/$/, "") + p.search
  } catch {
    return u.trim()
  }
}

function extractJSON(text: string): unknown | null {
  // A reply may contain several fences (e.g. a quoted example before the real
  // answer): try every fence, ```json-tagged ones first, then the brace span.
  const fences = [...text.matchAll(/```(json)?\s*([\s\S]*?)```/g)]
  const candidates = [
    ...fences.filter((m) => m[1]).map((m) => m[2]),
    ...fences.filter((m) => !m[1]).map((m) => m[2]),
    text.slice(text.indexOf("{"), text.lastIndexOf("}") + 1),
  ]
  for (const c of candidates) {
    if (!c) continue
    try { return JSON.parse(c) } catch { /* try next */ }
  }
  return null
}

function semaphore(limit: number) {
  let active = 0
  const queue: (() => void)[] = []
  return async function <T>(fn: () => Promise<T>): Promise<T> {
    // while, not if: a woken waiter must re-check — another task can slip in
    // between the finisher's decrement and this continuation running, and a
    // single if-check would let both proceed (limit briefly exceeded).
    while (active >= limit) await new Promise<void>((r) => queue.push(r))
    active++
    try { return await fn() } finally { active--; queue.shift()?.() }
  }
}

// ─── Plugin ───
export const DeepResearchPlugin: Plugin = async ({ client, directory }) => {
  const limit = semaphore(CONCURRENCY)

  /** One subagent turn in a fresh child session. Returns validated JSON or null. */
  async function subagent<T>(opts: {
    parentID: string
    agent: string
    title: string
    prompt: string
    validate: (v: any) => v is T
    abort: AbortSignal
  }): Promise<T | null> {
    if (opts.abort.aborted) return null
    return limit(async () => {
      try {
        if (opts.abort.aborted) return null // may have aborted while queued on the semaphore
        const created = await client.session.create({
          body: { parentID: opts.parentID, title: opts.title },
          query: { directory },
          throwOnError: true,
          signal: opts.abort, // abort must cancel the HTTP call, not just skip the next step
        })
        const id = created.data.id
        let prompt = opts.prompt
        for (let attempt = 0; attempt <= JSON_RETRIES; attempt++) {
          if (opts.abort.aborted) return null
          const res = await client.session.prompt({
            path: { id },
            // deep_research must not be visible to its own leaf subagents: a
            // recursive call would re-enter the shared semaphore this run
            // already holds slots on (deadlock) and fan out runaway sessions.
            body: { agent: opts.agent, tools: { deep_research: false }, parts: [{ type: "text", text: prompt }] },
            query: { directory },
            throwOnError: true,
            signal: opts.abort,
          })
          const text = res.data.parts
            .filter((p: any) => p.type === "text")
            .map((p: any) => p.text)
            .join("\n")
          const parsed = extractJSON(text)
          // An `error` field is the agent's honest-failure escape (missing
          // tool, all fetches failed, ...). Treat it as a failed subagent and
          // do NOT re-prompt: the retry nudge below demands JSON-only, and
          // 2026-07-08 showed that pressuring an agent that just said "I
          // can't do this" produces fabricated data, not compliance.
          if (parsed !== null && typeof (parsed as any).error === "string" && (parsed as any).error) return null
          if (parsed !== null && opts.validate(parsed)) return parsed
          prompt =
            "Your previous reply was not valid JSON in the required format. " +
            "Reply again with ONLY the fenced ```json block, exactly matching the format you were given. No prose. " +
            'If you CANNOT complete the task (e.g. a required tool is unavailable), reply with {"error": "one-line reason"} ' +
            "in the fenced ```json block instead — never fabricate results."
        }
        return null
      } catch {
        return null // failed subagent = abstention/skip, handled by caller
      }
    })
  }

  // ─── Validators (port of the workflow's JSON schemas) ───
  const isScope = (v: any): v is { question: string; summary: string; angles: { label: string; query: string; rationale?: string }[] } =>
    v && typeof v.question === "string" && Array.isArray(v.angles) &&
    v.angles.length >= 3 && v.angles.length <= 6 &&
    v.angles.every((a: any) => typeof a?.label === "string" && typeof a?.query === "string")

  const isSearch = (v: any): v is { results: SearchResult[] } =>
    v && Array.isArray(v.results) &&
    v.results.every((r: any) => typeof r?.url === "string" && typeof r?.title === "string" && Object.hasOwn(relRank, r?.relevance ?? ""))

  const isExtract = (v: any): v is { sourceQuality: SourceQuality; publishDate?: string; claims: { claim: string; quote: string; importance: Importance }[] } =>
    v && Object.hasOwn(qualRank, v.sourceQuality ?? "") && Array.isArray(v.claims) &&
    v.claims.every((c: any) => typeof c?.claim === "string" && typeof c?.quote === "string" && Object.hasOwn(impRank, c?.importance ?? ""))

  const isVerdict = (v: any): v is Verdict =>
    v && typeof v.refuted === "boolean" && typeof v.evidence === "string" &&
    Object.hasOwn(confRank, v.confidence ?? "")

  const isReport = (v: any): v is {
    summary: string
    findings: { claim: string; confidence: string; sources: string[]; evidence: string; vote?: string }[]
    caveats: string
    openQuestions?: string[]
  } =>
    v && typeof v.summary === "string" && typeof v.caveats === "string" && Array.isArray(v.findings) &&
    v.findings.every((f: any) =>
      typeof f?.claim === "string" && Array.isArray(f?.sources) &&
      typeof f?.evidence === "string" && Object.hasOwn(confRank, f?.confidence ?? ""))

  // ─── Prompts (verbatim ports) ───
  const scopePrompt = (question: string) =>
    "Decompose this research question into complementary search angles.\n\n" +
    "## Question\n" + question + "\n\n" +
    "## Task\n" +
    "Generate 5 distinct web search queries that together cover the question from different angles. Pick angles that suit the question's domain. Examples:\n" +
    "- broad/primary · academic/technical · recent news · contrarian/skeptical · practitioner/implementation\n" +
    "- For medical: anatomy · common causes · serious differentials · authoritative refs · red flags\n" +
    "- For tech: state-of-art · benchmarks · limitations · industry adoption · cost/tradeoffs\n\n" +
    "Make queries specific enough to surface high-signal results. Avoid redundancy.\n" +
    "Do NOT search the web yourself — this is a planning step only.\n\n" +
    "Reply with ONLY a fenced ```json block:\n" +
    '{ "question": "...", "summary": "1-2 sentence decomposition strategy", "angles": [ { "label": "...", "query": "...", "rationale": "..." } ] }'

  const searchPrompt = (question: string, angle: { label: string; query: string; rationale?: string }) =>
    "## Web Searcher: " + angle.label + "\n\n" +
    'Research question: "' + question + '"\n\n' +
    "Your angle: **" + angle.label + "** — " + (angle.rationale || "") + "\n" +
    "Search query: `" + angle.query + "`"

  const fetchPrompt = (question: string, source: SearchResult, angle: string) =>
    "## Source Extractor\n\n" +
    'Research question: "' + question + '"\n\n' +
    "Fetch and extract key claims from this source:\n" +
    "**URL:** " + source.url + "\n**Title:** " + source.title + "\n**Found via:** " + angle + " search"

  const verifyPrompt = (question: string, claim: Claim, v: number, votes: number) =>
    "## Adversarial Claim Verifier (voter " + (v + 1) + "/" + votes + ")\n\n" +
    "## Research question\n" + question + "\n\n" +
    '## Claim under review\n"' + claim.claim + '"\n\n' +
    "**Source:** " + claim.sourceUrl + " (" + claim.sourceQuality + ")\n" +
    '**Supporting quote:** "' + claim.quote + '"\n\n' +
    "**Your assigned lens:** " + VERIFY_LENSES[v] + ". Prioritize this lens; treat the rest of your checklist as secondary."

  return {
    tool: {
      deep_research: tool({
        description:
          "Deep research harness — deterministic pipeline that fans out web-search subagents across 5 angles, " +
          "fetches and extracts falsifiable claims from up to " + MAX_FETCH + " sources, adversarially verifies each claim (" +
          VOTES_PER_CLAIM + " lens-diverse refuter votes for the top " + MAX_CENTRAL_PANELS + " central claims, 1 for the rest), and returns a fact-checked, cited report. " +
          "Use for deep multi-source research questions. The question must be specific — clarify with the user first if it is underspecified. " +
          "Runs many subagent sessions (typically 30-70 LLM calls); do not use for quick lookups.",
        args: {
          question: tool.schema.string().describe("The refined research question, self-contained and specific."),
        },
        async execute(args, ctx) {
          const QUESTION = args.question.trim()
          if (!QUESTION) return "Error: empty research question."
          const parentID = ctx.sessionID
          const abort = ctx.abort

          // ─── Phase 0: Scope ───
          ctx.metadata({ title: "deep-research: scoping" })
          const scope = await subagent({
            parentID, agent: "research-analyst", title: "deep-research: scope",
            prompt: scopePrompt(QUESTION), validate: isScope, abort,
          })
          if (!scope) return "Error: scope step failed — could not decompose the question into search angles."

          // ─── Shared dedup state (accumulates across angles as they complete) ───
          const seen = new Map<string, string>()
          let dupes = 0
          let budgetDropped = 0
          let searchFailures = 0 // angles whose searcher failed or reported an error (e.g. no search tool)
          let fetchSlots = MAX_FETCH
          type FetchedSource = { url: string; title: string; angle: string; sourceQuality: SourceQuality; publishDate?: string; claims: Claim[] }

          // ─── Pipeline: per angle, search → dedup → fetch+extract (no barrier) ───
          // This phase runs for minutes; re-title the tool call as each subagent
          // completes so the TUI shows live progress instead of a frozen title.
          let searched = 0
          let fetched = 0
          let queued = 0
          const pipelineProgress = () =>
            ctx.metadata({
              title: "deep-research: searched " + searched + "/" + scope.angles.length +
                " angles · fetched " + fetched + "/" + queued + " sources",
            })
          pipelineProgress()
          const perAngle = await Promise.all(
            scope.angles.map(async (angle): Promise<FetchedSource[]> => {
              const search = await subagent({
                parentID, agent: "web-searcher", title: "deep-research search: " + angle.label,
                prompt: searchPrompt(QUESTION, angle), validate: isSearch, abort,
              })
              if (!search) { searchFailures++; searched++; pipelineProgress(); return [] }
              // Dedup + budget. JS is single-threaded: this block runs atomically
              // per angle, so shared state needs no locking.
              const sorted = [...search.results].sort((a, b) => relRank[a.relevance] - relRank[b.relevance])
              const novel: SearchResult[] = []
              // Carve-out: a late angle's high-relevance results are the best
              // sources of the run, so a few may exceed the budget (it goes
              // negative) — but CAPPED per angle. Searchers rate generously
              // ("high" is free to them), and an unlimited carve-out let one
              // run fetch 25 sources against MAX_FETCH=15.
              let carveout = HIGH_CARVEOUT_PER_ANGLE
              for (const r of sorted) {
                const key = normURL(r.url)
                if (seen.has(key)) { dupes++; continue }
                if (fetchSlots <= 0) {
                  if (relRank[r.relevance] === relRank.high && carveout > 0) carveout--
                  else { budgetDropped++; continue }
                }
                seen.set(key, angle.label)
                fetchSlots--
                novel.push(r)
              }
              searched++
              queued += novel.length
              pipelineProgress()
              const extracted = await Promise.all(
                novel.map(async (source): Promise<FetchedSource> => {
                  const ext = await subagent({
                    parentID, agent: "source-extractor",
                    title: "deep-research fetch: " + normURL(source.url).split("/")[0],
                    prompt: fetchPrompt(QUESTION, source, angle.label), validate: isExtract, abort,
                  })
                  fetched++
                  pipelineProgress()
                  if (!ext) return { url: source.url, title: source.title, angle: angle.label, sourceQuality: "unreliable", claims: [] }
                  return {
                    url: source.url, title: source.title, angle: angle.label,
                    sourceQuality: ext.sourceQuality, publishDate: ext.publishDate,
                    // Cap per source (keep the most important claims) so one
                    // over-eager extraction can't flood the verify pool.
                    claims: [...ext.claims]
                      .sort((a, b) => impRank[a.importance] - impRank[b.importance])
                      .slice(0, MAX_CLAIMS_PER_SOURCE)
                      .map((c) => ({ ...c, sourceUrl: source.url, sourceQuality: ext.sourceQuality })),
                  }
                }),
              )
              return extracted
            }),
          )

          const allSources = perAngle.flat()
          const allClaims = allSources.flatMap((s) => s.claims)
          // Dedup near-identical claims from different sources BEFORE the
          // expensive verify phase (one run verified the same "docs do not
          // mention X" claim twice = 6 verifier sessions). Ranked order means
          // the survivor is the best-quality copy. Semantic merging still
          // happens at synthesis; this only kills textual duplicates.
          const claimKey = (c: Claim) => c.claim.toLowerCase().replace(/[^a-z0-9]+/g, " ").trim()
          const seenClaims = new Set<string>()
          let claimDupes = 0
          const rankedClaims = [...allClaims]
            .sort((a, b) => (impRank[a.importance] - impRank[b.importance]) || (qualRank[a.sourceQuality] - qualRank[b.sourceQuality]))
            .filter((c) => {
              const k = claimKey(c)
              if (seenClaims.has(k)) { claimDupes++; return false }
              seenClaims.add(k)
              return true
            })
            .slice(0, MAX_VERIFY_CLAIMS)
          // Panel assignment: full panel for the first MAX_CENTRAL_PANELS
          // central claims (ranked order = most important first), 1 vote for
          // the rest — see the comment on MAX_CENTRAL_PANELS.
          let centralPanels = 0
          const votesAssigned = rankedClaims.map((c) =>
            c.importance === "central" && centralPanels++ < MAX_CENTRAL_PANELS ? VOTES_PER_CLAIM : 1,
          )

          const statsLine = (extra: string) =>
            "angles: " + scope.angles.length + " (searchFailures: " + searchFailures + ") · sources: " + allSources.length +
            " · claims: " + allClaims.length + " · claimDupes: " + claimDupes +
            " · urlDupes: " + dupes + " · budgetDropped: " + budgetDropped + extra

          if (rankedClaims.length === 0) {
            if (searchFailures >= scope.angles.length) {
              return "Deep research FAILED at the search phase for: " + QUESTION + "\n" +
                "All " + scope.angles.length + " search angles failed or reported errors — the websearch tool is likely " +
                "unavailable (needs OPENCODE_ENABLE_EXA=1 or the opencode provider). Nothing was researched; fix the tool and retry.\n" + statsLine("")
            }
            return "Deep research found NO extractable claims for: " + QUESTION + "\n" +
              (searchFailures > 0 ? searchFailures + "/" + scope.angles.length + " search angles failed; the rest returned nothing usable. " : "") +
              "All " + allSources.length + " fetched sources were empty, irrelevant, or failed.\n" + statsLine("")
          }

          // ─── Verify: tiered adversarial votes (barrier — claim pool must be complete) ───
          const votesTotal = votesAssigned.reduce((n, v) => n + v, 0)
          let votesDone = 0
          const verifyProgress = () =>
            ctx.metadata({
              title: "deep-research: verifying " + rankedClaims.length + " claims — " +
                votesDone + "/" + votesTotal + " votes",
            })
          verifyProgress()
          const voted = await Promise.all(
            rankedClaims.map(async (claim, ci) => {
              const votes = votesAssigned[ci]
              const killAt = Math.floor(votes / 2) + 1 // majority of assigned votes refutes (3-vote: 2, 1-vote: 1)
              const verdicts = (
                await Promise.all(
                  Array.from({ length: votes }, (_, v) =>
                    subagent({
                      parentID, agent: "claim-verifier",
                      title: "deep-research verify v" + (v + 1) + ": " + claim.claim.slice(0, 40),
                      prompt: verifyPrompt(QUESTION, claim, v, votes), validate: isVerdict, abort,
                    }).then((x) => { votesDone++; verifyProgress(); return x }),
                  ),
                )
              ).filter((x): x is Verdict => x !== null)
              const refuted = verdicts.filter((v) => v.refuted).length
              const support = verdicts.length - refuted
              // Three outcomes, not two: a majority refuting kills ON THE
              // MERITS; a majority of valid, NON-REFUTING votes confirms
              // (support, not mere vote count — a 1-1 split with a failed
              // third voter is contested, not confirmed); anything else
              // (errored/aborted verifiers) is an INFRA failure —
              // "unverified", which must never read as refuted.
              const status: "confirmed" | "refuted" | "unverified" =
                refuted >= killAt ? "refuted" : support >= killAt ? "confirmed" : "unverified"
              return { ...claim, verdicts, refutedVotes: refuted, status, votesAssigned: votes }
            }),
          )
          const confirmed = voted.filter((c) => c.status === "confirmed")
          const killed = voted.filter((c) => c.status === "refuted")
          const unverified = voted.filter((c) => c.status === "unverified")
          const voteStr = (c: (typeof voted)[number]) => (c.verdicts.length - c.refutedVotes) + "-" + c.refutedVotes
          const refutedBlock = killed.length
            ? "\n## Refuted claims (transparency)\n" + killed.map((c) => '- "' + c.claim + '" (' + c.sourceUrl + ", vote " + voteStr(c) + ")").join("\n")
            : ""
          const unverifiedBlock = unverified.length
            ? "\n## Unverified claims (verifier failures — NOT refuted)\n" +
              unverified.map((c) => '- "' + c.claim + '" (' + c.sourceUrl + ", valid votes " + c.verdicts.length + "/" + c.votesAssigned + ")").join("\n")
            : ""

          if (confirmed.length === 0) {
            const summary = killed.length === 0
              ? "verification infrastructure failed — no claim received enough valid verifier votes to adjudicate (rate limits or subagent errors). NOTHING was refuted; retry the run."
              : unverified.length === 0
                ? "ALL " + voted.length + " claims were refuted by adversarial verification.\nResearch inconclusive — sources may be low-quality or claims overstated."
                : "no claim survived: " + killed.length + " refuted on the merits, " + unverified.length + " unverified (verifier failures — not adjudicated; consider retrying)."
            return "Deep research: " + summary + "\n" +
              refutedBlock + unverifiedBlock + "\n\n" + statsLine(" · confirmed: 0 · killed: " + killed.length + " · unverified: " + unverified.length)
          }

          // ─── Synthesize ───
          ctx.metadata({ title: "deep-research: synthesizing " + confirmed.length + " confirmed claims" })
          const block = confirmed
            .map((c, i) => {
              const best = c.verdicts.filter((v) => !v.refuted).sort((a, b) => confRank[a.confidence] - confRank[b.confidence])[0]
              return "### [" + i + "] " + c.claim + "\nVote: " + voteStr(c) + " · Source: " + c.sourceUrl + " (" + c.sourceQuality + ")\n" +
                'Quote: "' + c.quote + '"\nVerifier evidence (' + (best?.confidence ?? "low") + "): " + (best?.evidence ?? "") + "\n"
            })
            .join("\n")

          const report = await subagent({
            parentID, agent: "research-analyst", title: "deep-research: synthesize",
            prompt:
              "## Synthesis: research report\n\n**Question:** " + QUESTION + "\n\n" +
              confirmed.length + " claims survived adversarial verification (" + VOTES_PER_CLAIM + " votes for the top central claims, 1 otherwise; majority refutation kills). Merge semantic duplicates and synthesize.\n\n" +
              "## Confirmed claims\n" + block + refutedBlock + unverifiedBlock + "\n\n" +
              "## Instructions\n" +
              "1. Identify claims that say the same thing — merge them, combine their sources.\n" +
              "2. Group related claims into coherent findings. Each finding should directly address the research question.\n" +
              "3. Assign confidence per finding: high (multiple primary sources, unanimous votes), medium (secondary sources or split votes), low (single source or blog-quality).\n" +
              "4. Write a 3-5 sentence executive summary answering the research question.\n" +
              "5. Note caveats: what's uncertain, what sources were weak, what time-sensitivity applies.\n" +
              "6. List 2-4 open questions that emerged but weren't answered.\n\n" +
              "Do NOT search the web — synthesize only from the material above.\n" +
              "Reply with ONLY a fenced ```json block:\n" +
              '{ "summary": "...", "findings": [ { "claim": "...", "confidence": "high|medium|low", "sources": ["url"], "evidence": "...", "vote": "3-0" } ], "caveats": "...", "openQuestions": ["..."] }',
            validate: isReport, abort,
          })

          const stats = statsLine(" · verified: " + voted.length + " · confirmed: " + confirmed.length + " · killed: " + killed.length + " · unverified: " + unverified.length)

          if (!report) {
            // Salvage: synthesis failed — return verified claims raw rather than discarding the run.
            return "Deep research report (synthesis step failed — raw verified claims below)\n\n" +
              "**Question:** " + QUESTION + "\n\n## Verified claims\n" +
              confirmed.map((c) => '- "' + c.claim + '" — ' + c.sourceUrl + " (vote " + voteStr(c) + ')\n  Quote: "' + c.quote + '"').join("\n") +
              refutedBlock + unverifiedBlock + "\n\n**Stats:** " + stats
          }

          return {
            title: "deep-research: " + confirmed.length + "/" + voted.length + " claims confirmed",
            output:
              "# Deep research report\n\n**Question:** " + QUESTION + "\n\n" +
              "## Executive summary\n" + report.summary + "\n\n" +
              "## Findings\n" +
              report.findings
                .map((f) => "- **[" + f.confidence + (f.vote ? " · " + f.vote : "") + "]** " + f.claim + "\n  " + f.evidence + "\n  Sources: " + f.sources.join(" · "))
                .join("\n") + "\n" +
              refutedBlock + unverifiedBlock + "\n\n" +
              "## Caveats\n" + report.caveats + "\n\n" +
              (report.openQuestions?.length ? "## Open questions\n" + report.openQuestions.map((q) => "- " + q).join("\n") + "\n\n" : "") +
              "**Stats:** " + stats + "\n\n" +
              "Present this report to the user in full (you may reformat, but keep all findings, confidence labels, sources, caveats, and the refuted/unverified-claims sections).",
            metadata: { question: QUESTION, stats },
          }
        },
      }),
    },
  }
}
