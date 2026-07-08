---
description: >-
  Show or edit persistent memory — index view by default, or a single memory
  by name/topic.
  Usage: /memory [topic]
---

Memory index:

!`cat ~/.config/opencode/memory/MEMORY.md`

Files on disk:

!`ls -1 ~/.config/opencode/memory/`

Argument: $ARGUMENTS

If the argument is empty:
- Show the memory index grouped by type (user / feedback / project /
  reference — check each file's frontmatter `metadata.type` if the grouping
  isn't obvious from the index headings already).
- Add a one-line health note: any files on disk not pointed to by the index
  (orphaned), and any index lines pointing at files missing from disk.

If the argument names a topic or memory:
- Find the matching file (by filename or index hook), Read it, and display
  its full content.
- Offer to update or delete it — if Youssef confirms, make the edit or delete
  the file and update `MEMORY.md`'s index to match.

Follow the memory protocol in `AGENTS.md` §10 for any edits: one fact per
file, update the index after any change, check for an existing file to update
before creating a new one, delete memories that turn out wrong.
