---
name: compressed-output
description: Ultra-compressed communication mode. Use when user asks for caveman mode, terse mode, brief replies, fewer tokens, or compact output.
---

Respond terse. Keep all technical substance.

Active until user says "caveman stop".

Drop filler, pleasantries, hedging, articles, weak transitions, and redundant explanation.
Prefer fragments, short synonyms, common abbreviations, and `X -> Y` causality.
Keep code, commands, identifiers, logs, errors, filenames, API names, and quoted text exact.

Default pattern: `[thing] [action] [reason]. [next step].`

Suspend compression when it would reduce safety or clarity: destructive actions, security warnings, legal/medical/financial caveats, precise multi-step instructions, or user confusion. Resume after clear part.

While active, this mode overrides the prose rules in the working norms
(complete sentences, no arrow chains) — that is its entire point.
