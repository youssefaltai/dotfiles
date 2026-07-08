# Coming from Claude Code — OpenCode cheat sheet

Practical muscle-memory map for someone who used to run `claude` and now runs
`opencode` exclusively. Doubles as the **acceptance checklist** for
`docs/claude-code-parity-plan.md` — if a row here is wrong or missing, the
parity project isn't done. Verified against opencode **v1.17.14** (`--help`,
`opencode debug config`, and binary keybind defaults) — not guessed.

**Out of scope by owner decision (2026-07-08):** theme, keybind remapping,
statusline, vim input mode. Stock OpenCode defaults stay.

## 1. Mental model

| Claude Code | OpenCode |
|---|---|
| `~/.claude/settings.json` | `opencode.jsonc` (engine) + `tui.json` (UI/attention) |
| `CLAUDE.md` hierarchy | `AGENTS.md` (auto-loaded manual) — **not** the same file; isolation below |
| `.claude/agents/*.md` | `agents/*.md` (subagents) + primary agents inline in `opencode.jsonc` |
| `.claude/commands/*.md` | `commands/*.md` (same `$ARGUMENTS`, `` !`cmd` ``, `@file` syntax) |
| `.claude/skills/` | `skills/*/SKILL.md` |
| Hooks (PreToolUse etc.) | `plugins/guard.ts` (native plugin, `tool.execute.before`) |
| Auto memory (`~/.claude/projects/.../memory/`) | `memory/MEMORY.md` index + topic files, loaded via `instructions` |

**Isolation**: `OPENCODE_DISABLE_CLAUDE_CODE=1` is exported in
`~/.config/zsh/.zshrc` — confirmed set. OpenCode never reads `CLAUDE.md` or
`~/.claude/skills/`; every row above is a **re-implementation**, not a shared
file. Claude Code stays installed for the reckit profile only.

## 2. Permission modes (Tab / Shift+Tab cycle)

Claude's `Shift+Tab` mode cycle → OpenCode's `agent_cycle` (`tab`) /
`agent_cycle_reverse` (`shift+tab`), cycling the three primary agents defined
in `opencode.jsonc`:

| Agent (Tab stop) | Mirrors | Actual behavior (opencode.jsonc) |
|---|---|---|
| `default` | Manual mode | Edits: ask. Bash: allowlist (`git`, `gh`, `brew`, `ls`, `cat`, `rg`, `mkdir`, `cp`, `npm`, ...) allowed, everything else asks. Secrets (`~/.ssh`, auth.json, guard.ts) hard-denied. |
| `accept-edits` | acceptEdits | Edits auto-approved. Adds `mv *`/`rm *`/`rmdir *` to the allow list on top of the global bash allowlist (guard.ts still hard-blocks catastrophic/guardrail-targeting `rm`). |
| `auto` | Auto mode | Everything local auto-approved (`bash *: allow`, edits allowed); outward/irreversible ops ask (`git push`, `git reset --hard`, `git clean`, `gh pr merge`, `gh release`, `gh repo`, `npm/pnpm publish`, `docker push`); `security *`/`claude auth *` re-asserted as deny after the broad allow. Rule-based approximation of Claude's classifier — guard.ts still hard-blocks the catastrophic class. |
| `plan` | Plan mode | `edit: deny` outright. Bash restricted to a true read-only allowlist (`git status/log/diff/show/branch`, `ls`, `cat`, `rg`, `find`, ...); everything else asks. |

`default_agent` is `default`. Built-in `build` agent is `disable: true` (these
four replace it). No `bypassPermissions`/`dontAsk` agent — the closest CLI
analog is `opencode run --auto` (see §5), used sparingly.

## 3. Slash commands

| Claude Code | OpenCode | Notes |
|---|---|---|
| `/clear` | `/new` | fresh session; old one still resumable |
| `/resume` | `/sessions` | session picker |
| `/model` | `/models` | switch mid-session, no clear needed |
| `/compact [instructions]` | `/compact` | native (`session.compact`) |
| `/export` | `/export` | native; CLI has `--sanitize` to redact |
| `/init` | `/init` | native, generates `AGENTS.md` |
| `/theme` | `/themes` | native — stock theme kept (out of scope to customize) |
| `/editor` | `/editor` | native, opens `$EDITOR` (`<leader>e` / `ctrl+x e`) |
| `/help` | `/help` | native |
| `/rename` | `ctrl+r` (session context) | verified default keybind `session.rename` — no slash command, keybind-only |
| `Esc Esc` rewind menu | `/undo`, `/redo` | verified keybinds `<leader>u` / `<leader>r` (`session.undo`/`session.redo`); no combined visual rewind menu, no session-timeline restore of both code+chat in one dialog — apply undo/redo separately |
| `/cost` | `/cost` (custom) | wraps `opencode stats`, one small table |
| `/usage` | `/usage` (custom) | fuller breakdown by model/period |
| `/context` | `/context` (custom) | explains what's consuming the context window |
| `/recap` | `/recap` (custom) | one-paragraph session summary |
| `/memory` | `/memory` (custom) | list/read/edit `memory/` files |
| `/doctor` | `/doctor` (custom) | config validity, MCP health, guard presence, isolation check, dotfiles state |
| `/security-review`, `/verify`, `/simplify` | same names (custom) | ported as prompt templates in `commands/` |
| — (this machine's own suite) | `/code-review`, `/deep-research`, `/fact-check`, `/best-practice`, `/grill-me`, `/caveman` | custom, predate this parity project, kept as-is |
| `/effort` + `Option+T` | `ctrl+t` variant cycle | verified default keybind `variant_cycle` = `ctrl+t`; variants map to reasoning-effort levels on the primary model |
| `/plan` | `Tab` to the `plan` agent | no dedicated slash command; mode switch does the same job |
| `/mcp` | `opencode mcp` (CLI) + `mcp` block in `opencode.jsonc` | no in-TUI `/mcp` config dialog equivalent found; edit config + restart, or use CLI subcommands (`add`/`list`/`auth`/`logout`) |
| `/permissions` | edit `opencode.jsonc` `permission` block | no interactive permission-review UI; static config instead |
| `/hooks` | `plugins/` directory | `plugins/guard.ts` is the sole hook; no in-TUI hook list/disable UI |
| `/agents` | `agents/` dir + `opencode agent list` | subagent fleet: `claim-verifier`, `code-reviewer`, `finding-verifier`, `research-analyst`, `source-extractor`, `system-maintainer`, `web-searcher` |
| `/login`, `/logout` | `opencode auth login` / `opencode auth logout` (CLI only, aliased from `opencode providers`) | no in-TUI `/login`; use `/connect` for MCP OAuth, CLI for model providers |
| `/share` / no direct unshare command | `/share` / `/unshare` | native (`session.share`/`session.unshare`) |
| `/branch [name]` | `opencode run --fork` / `-s <id> --fork` | no in-TUI fork-from-message command found in this build; use CLI fork or `session.fork` (message-level, `<leader>` menu, no default keybind) |
| `/tasks` | background subagents + child-session nav | `session.background` command lists background subagents; no dedicated `/tasks` monitor view |
| `/statusline` | out of scope | owner declined |
| `/config` | edit `opencode.jsonc` / `tui.json` directly | no interactive settings menu; restart required after edits |

## 4. Keyboard & interaction

| Thing | Behavior |
|---|---|
| `!` prefix | shell mode — same as Claude Code, runs directly, output added to context |
| `@` in prompt | file path autocomplete — same |
| `Esc` | interrupt response — same (no rewind-menu attached, see §3) |
| `Ctrl+X` | **leader key** (verified default) — chords like `<leader>a` (agent list), `<leader>e` (editor), `<leader>g` (session timeline), `<leader>m` (model list), `<leader>t` (theme list), `<leader>u`/`<leader>r` (undo/redo), `<leader>b` (sidebar toggle) |
| `Tab` / `Shift+Tab` | `agent_cycle` / `agent_cycle_reverse` — permission-mode cycling (§2) |
| `Ctrl+T` | `variant_cycle` — effort-level cycling (§3) |
| `Ctrl+R` | `session_rename` — rename current session |
| `Ctrl+D` | `session_delete` (in session-list context) |
| `F2` / `Shift+F2` | `model_cycle_recent` / reverse — cycle recently-used models |
| Ctrl+O transcript viewer | no exact equivalent; closest is the `steps.toggle` / `display_thinking` command-palette actions (toggle tool-call/thinking detail) plus `/export` for full text and `<leader>g` session timeline |

Vim input mode and custom keybind remapping are deliberately **not**
configured (owner decision) — `tui.json` only sets the `attention`
(notification/sound) block.

## 5. CLI flags

| Claude Code | OpenCode | Notes |
|---|---|---|
| `claude -p "q"` | `opencode run "q"` | one-shot, prints and exits |
| `--continue` | `-c` | continue most recent session |
| `--resume <id>` | `-s <id>` | resume by session ID |
| `--fork-session` | `--fork` (with `-c` or `-s`) | fork instead of continuing in place |
| `--output-format json` | `--format json` | choices are only `default`/`json` — **no `stream-json` parity**, no partial-message events |
| `--model <name>` | `-m provider/model` | e.g. `-m opencode/claude-sonnet-5` (see §6) |
| `--permission-mode <mode>` | `--agent <default\|accept-edits\|plan>` | approximation: picks a whole primary-agent persona+permission-map, not just a mode enum |
| `--allowedTools "Read,Edit,Bash"` | `--auto` | blunt approximation — auto-approves everything not explicitly denied; no per-tool allowlist flag |
| `claude mcp add` | `opencode mcp add` / edit `mcp` block in `opencode.jsonc` | current servers: `context7`, `sequential-thinking`, `playwright` |
| `claude agents` (background agent view) | `opencode agent list` | lists configured agents (primaries + subagents), not running background sessions |
| `claude doctor` | `/doctor` (custom command, not CLI) | no CLI-level doctor; run it inside a session |
| session export | `opencode export [sessionID]` (`--sanitize` to redact) | JSON, not plain text |
| `/cost` / `/usage` data source | `opencode stats` (`--days`, `--tools`, `--models`, `--project`) | `/cost` and `/usage` commands wrap this |

## 6. Models

Current default (`opencode.jsonc`): `model: deepseek/deepseek-v4-pro`,
`small_model: deepseek/deepseek-v4-flash` (titles/summaries, ≈ Claude's
internal Haiku usage) — DeepSeek direct API, cheapest option, biggest
behavioral gap from real Claude.

**Effort variants** (cycled with `ctrl+t`, ≈ Claude Code's `/effort` +
thinking toggle): built-in — OpenCode synthesizes them from the models.dev
`reasoning_options` metadata (thinking toggle + effort `high`/`max`; DeepSeek
v4 accepts only those two effort levels, lower values coerce to `high`
server-side). Deliberately NOT hand-defined in `opencode.jsonc`: custom
variants would override the working built-ins.
Historical upstream issue (verified 2026-07-08): the OpenAI-compatible
DeepSeek path used to 400 on unreturned `reasoning_content` in multi-turn
thinking (anomalyco/opencode #24114 — now **closed**, so likely fixed by
v1.17.14). If thinking variants ever regress mid-conversation, the documented
workaround (#24122, closed as not-planned) is routing the provider through
DeepSeek's Anthropic-compatible endpoint (`@ai-sdk/anthropic`,
`baseURL: https://api.deepseek.com/anthropic`).

**Real Claude is already one `/models` switch away** — no extra config. The
OpenCode Zen auth on this machine exposes (`opencode models | grep claude`,
verified live):

```
opencode/claude-fable-5        opencode/claude-haiku-4-5
opencode/claude-opus-4-1        opencode/claude-opus-4-5
opencode/claude-opus-4-6        opencode/claude-opus-4-7
opencode/claude-opus-4-8        opencode/claude-sonnet-4
opencode/claude-sonnet-4-5      opencode/claude-sonnet-4-6
opencode/claude-sonnet-5
```

(OpenRouter also carries the same lineup under `openrouter/anthropic/*` and
`openrouter/~anthropic/*claude-*-latest` aliases — same models, one bill,
slight markup — as a secondary path if the OpenCode Zen route ever breaks.)

Pick one per session with `/models` — this is the "give me actual Claude
Fable/Opus behavior" escape hatch when DeepSeek's behavior gap matters for a
task.

**To add direct Anthropic API billing instead** (only if ever wanted): either
run `opencode auth login` and pick Anthropic, or add a provider block to
`opencode.jsonc`:
```jsonc
"provider": {
  "anthropic": {
    "npm": "@ai-sdk/anthropic",
    "options": { "apiKey": "{env:ANTHROPIC_API_KEY}" }
  }
}
```
Using Anthropic as a *model provider* is a billing choice, not a Claude Code
isolation violation — the isolation rule is about the tool (`claude` CLI/its
files), not the model vendor.

## 7. Known gaps (accepted, not planned)

| Claude Code feature | Status |
|---|---|
| Custom statusline, vim input mode, keybind remapping, theme | **out of scope** — owner explicitly doesn't want these |
| `Esc Esc` rewind menu (unified code+chat restore) | none — `/undo`/`/redo` + `<leader>g` session timeline cover it piecemeal |
| `Ctrl+O` transcript viewer (fullscreen, `{`/`}` prompt-jump, `[` scrollback dump) | none — `/export` + steps/thinking toggle approximate it |
| Sandboxed bash, auto-mode classifier, advisor (server-side approval gate) | none — permission maps + `guard.ts` carry the whole safety load |
| Remote Control, voice dictation, prompt suggestions, `/btw`, `/schedule`, `/goal`, `/loop` (Claude Code's versions) | none in OpenCode itself — `opencode serve`/`web`/`attach` cover remote access differently; this machine's own `/loop`-style automation, if any, lives outside OpenCode |
| `--bare` mode (skip all discovery for CI reproducibility) | no exact match — `--pure` skips external plugins only, not MCP/skills/instructions |
| `stream-json` output parity (token-level SSE events) | partial — `--format json` gives one final JSON blob, not a token stream |
| In-TUI `/mcp`, `/permissions`, `/hooks`, `/config` interactive editors | none — all three are static-file edits + restart |
