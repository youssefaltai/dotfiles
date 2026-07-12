---
description: >-
  Diagnose this machine's OpenCode installation: config validity, models/auth,
  MCP servers, guard plugin, memory integrity, update status, dotfiles state.
  Usage: /doctor
---

Run a diagnostic pass over this OpenCode installation and report a checklist
with pass/warn/fail per item. Run the checks below yourself; keep each finding
to one line, with a fix suggestion on failures.

!`opencode --version && echo --- && brew info anomalyco/tap/opencode 2>/dev/null | head -1`

## Checks
1. **Version & updates** — from the injected output: installed version vs the
   brew formula's current version. If behind, recommend the §9 AGENTS.md brew
   update routine (never a self-update — the binary is Homebrew-managed).
2. **Config validity** — run `opencode models` and confirm it exits 0 (it
   refuses to start on invalid opencode.jsonc/tui.json). Confirm the expected
   model IDs from opencode.jsonc resolve in its output.
3. **Primary agents** — `opencode agent list` (or read opencode.jsonc):
   confirm `default`, `accept-edits`, and `plan` exist and `default_agent` is
   `default`; confirm built-in `build` is disabled.
4. **MCP servers** — `opencode mcp list`: context7, sequential-thinking, and
   playwright present and enabled; flag any that error.
5. **Guard plugin** — `~/.config/opencode/plugins/guard.ts` exists, and the
   edit-deny rule for it is present in opencode.jsonc. Do NOT test-fire guard
   rules by running forbidden commands.
6. **Isolation** — `echo $OPENCODE_DISABLE_CLAUDE_CODE` prints `1` (prevents
   OpenCode from scanning non-OpenCode skill/config locations).
7. **Memory integrity** — every line in `memory/MEMORY.md` points at an
   existing file, and every `memory/*.md` (except the index) appears in the
   index. Report orphans/dead links; offer to fix only if asked.
8. **Dotfiles repo** — `git -C ~/.config status --short` clean or listing
   only intentional work-in-progress; branch not behind origin
   (`git -C ~/.config status -sb` first line).
9. **Env prerequisites** — `CONTEXT7_API_KEY` non-empty and
   `OPENCODE_ENABLE_EXA` set to 1 (websearch for the research pipelines).
   Report presence only — NEVER print key values.

## Output
- A single pass/warn/fail checklist (one line per check), failures first.
- End with either "all clear" or a numbered fix list, most urgent first.
- Read-only: this command diagnoses. Apply fixes only on explicit request.
