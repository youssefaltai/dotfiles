# Claude Code Parity Plan — transforming OpenCode into Claude Code

**Goal:** using `opencode` should feel indistinguishable from using `claude` in every
aspect OpenCode's architecture allows — interaction surface, config conventions,
extension model, behavior, and safety — with an honest register of what cannot be
replicated without forking the TUI.

**Status: EXECUTED 2026-07-08** (all phases complete; theme/keybinds/statusline/vim
dropped by owner decision during execution). Verified live: mode agents run,
guard blocks all 24 test cases, isolation proven (CLAUDE.md marker invisible,
AGENTS.md control visible). See `docs/claude-code-mapping.md` for the resulting
day-to-day mapping. The safety invariants from the system manual (irreplaceable
Claude login, secrets, catastrophic deletes) carried over unchanged.

**Companion reference:** `docs/claude-code-feature-inventory.md` — the exhaustive
Claude Code feature spec this plan maps against.

**Deadline pressure:** the personal Claude Code profile is decommissioned ~2026-07-10
(`finalize-claude-migration` skill). This plan should land before or alongside that
cutover so OpenCode is a full replacement on day one.

---

## 0. Strategy — transformation with full isolation

**Owner decisions (2026-07-08):**
- Claude Code is **reckit-only** (unavoidable company requirement); personal is 100%
  OpenCode. OpenCode must **never see or use Claude Code in any way** — no reading
  `~/.claude/*`, no `CLAUDE.md` fallback, no shared scripts. Claude Code's behavior
  gets *re-implemented natively* in OpenCode, never bridged to.
- Keybindings, statusline, and vim mode are **out of scope** — explicitly not wanted.

Two levers:

1. **Emulate through config.** Primary agents that mirror Claude's permission modes
   (Tab = Shift+Tab cycling), variants as effort levels, custom commands replicating
   the slash-command surface, Claude-style memory, and ported system prompts.
   (Theme: out of scope — owner keeps the stock OpenCode theme, decision 2026-07-08.)
2. **Re-implement the rest as native plugins.** OpenCode's plugin API
   (tool.execute.before/after, session events, custom tools) hosts an OpenCode-owned
   guard and, optionally, a general hooks engine modeled on Claude Code's hook
   contract — content ported once, no runtime dependency on anything Claude.

**Isolation tasks (part of Phase 1):**
- Export `OPENCODE_DISABLE_CLAUDE_CODE=1` in `~/.config/zsh/.zshrc` — kills all
  Claude Code compat reading (`CLAUDE.md` prompt fallback + `~/.claude/skills/`).
- Audit config for any `~/.claude` / `~/.config/claude` *reads*; remove them.
  Protective **edit-denies** on Claude paths stay (that's guarding reckit's tooling
  from damage, not using it).

## Architecture map (what maps to what)

| Claude Code | OpenCode equivalent | Parity |
|---|---|---|
| `~/.claude/settings.json` | `~/.config/opencode/opencode.jsonc` + `tui.json` | native |
| `settings.json` hierarchy (user→project→local) | global config → project `opencode.json` → `.opencode/` | native |
| CLAUDE.md hierarchy | `AGENTS.md` discovery (walks up) + global AGENTS.md + `instructions` array (CLAUDE.md compat **disabled** per isolation) | native |
| `@import` in CLAUDE.md | `instructions: []` array (globs, files, URLs) | approximation |
| `.claude/rules/` path-scoped rules | no equivalent; `instructions` globs load unconditionally | gap (partial) |
| Auto memory (MEMORY.md + topic files) | file-based memory + `instructions: ["memory/MEMORY.md"]` (already built) | buildable |
| Permission modes (Shift+Tab cycle) | primary agents cycled with Tab/Shift+Tab | strong approximation |
| Plan mode + ExitPlanMode approval | built-in `plan` agent (read-only) + manual Tab switch | approximation |
| `permissions.allow/deny/ask` (`Bash(git *)`) | `permission` maps with glob patterns (**last-match-wins**, not deny-precedence — order rules deny-last) | native |
| Hooks (PreToolUse etc., JSON stdin, exit 2) | native plugin events (`tool.execute.before/after`, session events) — guard.ts + optional hooks engine | buildable |
| Subagents `.claude/agents/*.md` | `agents/*.md` (frontmatter: description, mode, model, tools, permission) | native |
| Skills `SKILL.md` | native skills in `~/.config/opencode/skills/` + project `.opencode/skills/` (Claude-dir reading disabled) | native |
| Custom commands `.claude/commands/*.md` | `commands/*.md` — same `$ARGUMENTS`, `!`cmd``, `@file` | native |
| MCP (`.mcp.json`, OAuth) | `mcp` block in opencode.jsonc, OAuth incl. DCR | native (different file) |
| Statusline / vim mode / custom keybinds | out of scope (owner: not wanted) | — |
| Ctrl+O transcript viewer | `/details` toggle + `/export` + session timeline | approximation |
| Esc Esc rewind menu | `/undo`, `/redo`, session timeline (`<leader>g`), snapshots (v1.17.11) | approximation |
| `/effort` + Option+T thinking | model **variants** (low…max) cycled with `variant_cycle` (ctrl+t) | strong approximation |
| `/model`, Option+P | `/models`, `model_list` keybind, `model_cycle_recent` (F2) | native |
| Background subagents, `/tasks` | background subagents (v1.16.2), child-session nav keybinds | native |
| `claude -p` / `--output-format json` | `opencode run --format json` | native (no stream-json parity) |
| `claude --continue/--resume/--fork-session` | `opencode -c / -s <id> / --fork`, `/sessions` | native |
| Checkpointing | `snapshot: true` (git-backed undo/redo) | native |
| `/cost`, `/usage` | `opencode stats` (wrap as custom command) | buildable |
| Notifications (`preferredNotifChannel`) | `tui.json` `attention` block (sound/notification per event) | native |
| Output styles | alternate primary agents with different prompts | approximation |
| Sandboxed bash, auto-mode classifier, advisor | none | GAP (accept) |
| Remote Control / web | `opencode serve` / `opencode web` / `opencode attach` | different but present |
| GitHub `@claude` app | `opencode github` (`/oc` in issues/PRs) | native |

---

## Phase 0 — Snapshot & baseline (½ h)

The revamp starts from a recoverable point.

1. Commit the current working tree as-is (5 modified files incl. guard.ts/guard.sh
   regex fixes, plus the 8 untracked agent/command files) — message: pre-revamp
   checkpoint. Push the 3 unpushed commits on `main`.
2. Commit `docs/claude-code-feature-inventory.md` + this plan.
3. Note versions: opencode 1.17.14 (Homebrew `anomalyco/tap/opencode`), autoupdate
   stays `"notify"` (Homebrew owns the binary).

## Phase 1 — Repo restructure to Claude-idiomatic layout (1 h)

New layout (matches current OpenCode docs naming — plural dirs — and mirrors
`~/.claude` structure):

```
~/.config/opencode/
├── opencode.jsonc          # engine config (≈ settings.json)
├── tui.json                # theme, keybinds, attention (≈ keybindings.json + UI settings)
├── AGENTS.md               # operating manual (≈ ~/.claude/CLAUDE.md + system.md)
├── agents/                 # subagents + permission-mode primaries (≈ ~/.claude/agents)
├── commands/               # slash commands (≈ ~/.claude/commands)
├── skills/                 # SKILL.md skills (≈ ~/.claude/skills)
├── plugins/                # guard + bridges (≈ hooks engine)
│   └── hooks.json          # Claude-style hooks config consumed by claude-hooks.ts
├── prompts/                # system prompts for primary agents
├── themes/claude-dark.json
├── memory/                 # auto-memory (global store, stays gitignored)
└── docs/                   # this plan, feature inventory, mapping cheat sheet
```

Tasks: rename `agent/`→`agents/`, `command/`→`commands/`, `skill/`→`skills/`; update
the allowlist in `~/.config/.gitignore` (`!opencode/agents/**` etc.); fix all
cross-references (AGENTS.md, guard rules, memory files). One-time content port: copy
the §9 system specs from `~/.config/claude/system.md` into AGENTS.md (migration copy,
not a runtime reference), and fix the OpenRouter→DeepSeek doc drift while touching it.
Then apply the isolation tasks from §0 (env exports + config audit).

## Phase 2 — Permission-mode primary agents + TUI parity (2 h)

**Primary agents = Claude's permission modes.** Tab/Shift+Tab (`agent_cycle` /
`agent_cycle_reverse`) then behaves exactly like Claude Code's Shift+Tab mode cycling:

| Agent | Mirrors | Permission profile |
|---|---|---|
| `default` | default mode | global maps: bash allowlist + `*: ask`, edit allow (or ask — decide), read deny-list |
| `accept-edits` | acceptEdits | edit/write allow; filesystem bash (`mkdir/touch/mv/cp/rm` narrow forms) allow; rest ask |
| `plan` | plan mode | edit/write/patch deny; bash read-only allowlist only; prompt: research → propose a plan, never modify |

`default_agent: "default"`. The built-in build/plan agents get `disable: true` (ours
replace them). Bypass/dontAsk get no agent — `--auto` flag covers the CI case.

**tui.json:**
- `attention` block ≈ notification parity: enable `notifications` + `sound` for
  `permission`, `question`, `error`, `done`, `subagent_done`.
- Theme, keybinds, statusline, vim: **out of scope** — stock OpenCode defaults stay.

## Phase 3 — Native guard + hooks engine (2–3 h)

Claude Code's hooks *capability* is re-implemented natively; no Claude files are read
or shared. `~/.config/claude/hooks/guard.sh` remains reckit-Claude's guard and is
never referenced by OpenCode.

- **`plugins/guard.ts` stays the sole OpenCode guard.** Port any remaining rule-content
  deltas from guard.sh **once** (a content copy during migration, then the two evolve
  independently — reckit's guard is reckit's problem). Current rule set (Claude-auth
  protection, keychain, catastrophic rm, guardrail self-protection) already matches.
- **Optional: general hooks engine** (`plugins/hooks.ts` + `hooks.json`), modeled on
  Claude Code's hook contract but OpenCode-owned end to end — lets future hook logic
  be plain shell scripts (JSON on stdin, exit 2 = block) instead of TypeScript:
  | Hook concept (from Claude Code) | OpenCode plugin event | Block? |
  |---|---|---|
  | PreToolUse | `tool.execute.before` (throw to block; mutate args for input rewrite) | yes |
  | PostToolUse | `tool.execute.after` | no |
  | SessionStart | `session.created` | no |
  | Stop | `session.idle` | no |
  | PreCompact | `experimental.session.compacting` | partial |
  | Notification | `permission.asked` → toast/attention | no |
  Build only if/when guard.ts rules outgrow TypeScript; otherwise skip — guard.ts
  alone is simpler.
- Edit-permission deny list keeps `plugins/guard.ts` (and `plugins/hooks.ts` +
  `hooks.json` if built).

## Phase 4 — Slash-command surface (2 h)

Custom commands (in `commands/`) fill every gap where a Claude built-in has no
OpenCode built-in. Native already: `/compact /export /editor /models /themes /init
/new /sessions /share /unshare /undo /redo /help /details /thinking /connect`.

Add:
- `/cost`, `/usage` → template injecting `!`opencode stats`` and formatting it.
- `/context` → stats + explanation of what's consuming context.
- `/recap` → summarize session progress in one paragraph.
- `/memory` → list + read `memory/` files, offer edits.
- `/doctor` → checks: config validates, MCP servers reachable, auth providers present,
  brew formula current, guard active, LSP status.
- `/security-review`, `/verify`, `/simplify` → port Claude Code's bundled-skill
  behavior as prompt templates.
- Keep + migrate the existing suites (they already mirror Claude Code patterns):
  `/code-review`, `/deep-research`, `/fact-check`, `/best-practice`, `/grill-me`,
  `/caveman`; subagent fleet (`code-reviewer`, `finding-verifier`, `web-searcher`,
  `source-extractor`, `claim-verifier`, `research-analyst`, `system-maintainer`)
  moves to `agents/` unchanged.
- `docs/claude-code-mapping.md` — the "coming from Claude Code" cheat sheet: every
  Claude command/shortcut → its OpenCode equivalent or gap note. This doc is also the
  acceptance checklist for Phase 8.

## Phase 5 — Memory parity (1 h)

Align the existing memory system with Claude Code's auto-memory conventions:
- `memory/MEMORY.md` = index, ≤200 lines, one line per memory; topic files loaded
  on demand (already true). Frontmatter schema stays.
- AGENTS.md §10 rewritten to match Claude's auto-memory behavioral contract: check
  index at session start, save non-obvious durable facts, update-don't-duplicate,
  delete wrong memories, never store what the repo already records.
- Per-project memory pattern documented: project `.opencode/memory/` + project-level
  `opencode.json` with `instructions: [".opencode/memory/MEMORY.md"]`.
- `memory/` stays out of the dotfiles repo (may contain company details).

## Phase 6 — Behavioral parity: system prompts (2 h)

The Claude Code *feel* is mostly the harness prompt. Port its norms into
`prompts/default.md` (wired via agent `prompt: {file:./prompts/default.md}`):
- Concise, outcome-first replies; prose over fragment-speak; match response length to
  question weight.
- Reference code as `file:line`; prefer dedicated tools over shell cat/grep.
- Todo usage for multi-step work; brief status updates while working.
- Confirm before irreversible/outward actions; report failures plainly.
- Commit style: imperative subject, explain-why body, attribution trailer
  (decide: keep a `Co-Authored-By: OpenCode <...>` analog or none).
- `prompts/plan.md`: research-only, produce a stepwise plan, explicit "switch to
  default/accept-edits to execute" handoff (replicates the ExitPlanMode ritual as
  convention rather than dialog).
Optional later: `explanatory` / `learning` primary agents ≈ output styles.

## Phase 7 — Models, variants, effort (1 h + a decision)

- **Variants as effort levels** on the primary model: define `low`, `medium`, `high`,
  `xhigh`, `max` variants (mapped to `reasoningEffort` / thinking budget as the
  provider supports); `ctrl+t` cycles them ≈ `/effort` + Option+T.
- `small_model` stays for titles/summaries (≈ Claude's internal Haiku usage).
- **Open decision — the model itself.** "Exactly like Claude Code" is bounded by the
  model. Options:
  a) Keep DeepSeek direct (current) — cheapest, biggest behavioral gap.
  b) Anthropic API key in OpenCode (Claude Sonnet/Opus) — true Claude behavior,
     pay-per-token; the natural post-July-10 path if behavior parity matters most.
  c) OpenRouter Claude — same models, one bill, slight markup.
  Recommendation: (a) as default + (b) configured as a selectable provider, so
  `/models` can switch to real Claude for tasks where the Claude feel matters.
- Fix doc drift everywhere: config uses DeepSeek direct; AGENTS.md/memory still say
  OpenRouter.

## Phase 8 — Verification & close-out (1 h)

- Walk `docs/claude-code-mapping.md` end-to-end; demo each mapped feature live
  (permission-mode cycling, guard blocking a forbidden command, variants cycling,
  notifications, /cost, memory recall, plan→execute handoff).
- Test the guard: run the forbidden-command test cases (claude auth, keychain,
  catastrophic rm, guardrail tampering) through guard.ts; all must block.
- **Isolation check:** with `OPENCODE_DISABLE_CLAUDE_CODE=1` exported, verify a
  session in a repo containing only `CLAUDE.md` loads no instructions from it, and
  `~/.claude/skills/` never appears in skill discovery.
- Update AGENTS.md (§structure, §guard, §modes), commit, push dotfiles.

---

## Gap register — cannot replicate without forking (accept + closest approximation)

| Claude Code feature | Status | Closest approximation |
|---|---|---|
| Custom statusline / vim mode / keybind remapping | out of scope | owner explicitly doesn't want these — no work planned |
| Plan-approval dialog (ExitPlanMode) | none | plan agent + prompt convention + Tab switch |
| Esc-Esc rewind menu | none | `/undo` `/redo`, session timeline, snapshots |
| Ctrl+O transcript viewer | none | `/details` toggle, `/export`, `<leader>g` timeline |
| Prompt suggestions, `/btw`, voice, fast-mode toggle | none | — |
| Auto-mode classifier, advisor, sandboxed bash | none | permission maps + guard bridge carry the safety load |
| Remote Control / cloud sessions / scheduled agents | different | `opencode serve`/`web`/`attach`; cron via launchd + `opencode run` if ever needed |
| PostToolUse `additionalContext` injection | plugin API limit | hook runs, context injection unsupported — document |
| UserPromptSubmit blocking | no pre-prompt block hook | approximate with guard at tool layer |
| `stream-json` output parity | partial | `--format json`; SDK/SSE for streaming consumers |

## Effort summary

| Phase | What | Est. |
|---|---|---|
| 0 | snapshot, commit, push | 0.5 h |
| 1 | restructure + isolation + doc sync | 1.5 h |
| 2 | mode agents, attention | 1 h |
| 3 | native guard rule port (+ optional hooks engine) | 1–3 h |
| 4 | command surface + mapping doc | 2 h |
| 5 | memory alignment | 1 h |
| 6 | system prompts | 2 h |
| 7 | variants + model decision | 1 h |
| 8 | verification incl. isolation check, docs, push | 1 h |
| **Total** | | **~11–13 h** (2 focused days) |

## Open decisions (owner)

1. **Model**: DeepSeek-only, add Anthropic API as switchable provider (recommended), or full Claude via API? (Using Anthropic's *API* as a model provider is a billing/behavior choice — it does not violate the Claude Code isolation rule, which is about the tool, not the models.)
2. **`default` agent edit permission**: `ask` (true Claude default-mode feel, more prompts) or `allow` (current behavior)?
3. **Commit attribution trailer**: none, or an OpenCode analog of Co-Authored-By?
