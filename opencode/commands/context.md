---
description: >-
  Explain what is consuming this session's context window, with rough size
  estimates.
  Usage: /context
---

Reference file sizes:

!`wc -c ~/.config/opencode/AGENTS.md ~/.config/opencode/memory/MEMORY.md ~/.config/opencode/prompts/claude-code-norms.md 2>/dev/null`

Explain what's loaded into THIS session's context, using the byte counts above
(bytes / 4 ≈ tokens, note it as an estimate):
- `AGENTS.md` — the operating manual, auto-loaded every session.
- `memory/MEMORY.md` — the memory index, auto-loaded via the `instructions`
  array in `opencode.jsonc`; individual memory files are NOT loaded unless
  something in this conversation Read one — list any that were.
- `prompts/claude-code-norms.md` — working norms, auto-loaded via the same
  `instructions` array.
- The system prompt and enabled tool/MCP schemas — not measurable from here,
  but they exist and are a real share of the fixed overhead; say so.
- Conversation history so far — describe roughly (number of turns / tool
  calls), no fake token count.
- Tool outputs pulled in during this session (file reads, command output,
  search results) — name the biggest contributors if any stand out.

Be honest that OpenCode exposes no exact per-session context-window API — all
figures here are estimates from what's observable, not a real usage meter.

If conversation history feels heavy (long session, many large tool outputs),
recommend `/compact`. Keep the whole answer to one screen.
