---
name: finalize-claude-migration
description: >-
  Finalize the migration from personal Claude Code to OpenCode+OpenRouter. Use
  ONLY when Youssef explicitly asks to finalize/complete the Claude migration,
  after the personal Claude subscription has ended (expected ~2026-07-10).
  Confines Claude Code to reckit-only, decommissions the personal profile, and
  rewires OpenCode to be fully self-sufficient. Do not use for routine
  maintenance or partial cleanups.
---

# Finalize the Claude Code → OpenCode migration

This runbook completes the migration that started on 2026-07-04. End state:

- **OpenCode + OpenRouter**: the only personal/system agent. No dependency on
  anything under `~/.claude`.
- **Claude Code**: reckit-only work tool. Runs only under `~/work/reckit/`,
  knows nothing about the rest of the machine, hook-blocked from touching
  paths outside the reckit tree.
- **Personal Claude profile**: decommissioned (archived, not destroyed).

## 0. Preconditions — verify before touching anything

1. Ask the user to confirm the personal Claude subscription has actually ended.
2. Today's date is on/after 2026-07-10.
3. `~/.config` dotfiles repo is clean (`git status`) — commit/stash drift first.
4. NEVER at any step: touch macOS Keychain items (`Claude Code-credentials*`),
   run `claude auth login/logout`, or delete the Passwords.app entry
   **"Claude Code old account credentials"**. These stay as harmless relics —
   the account may still be recoverable and the reckit login must keep working.

## 1. Confirm OpenCode's skills are self-contained (no ~/.claude dependency)

Since 2026-07-05 OpenCode has no skill dependency on `~/.claude`: its skills
are real files under `~/.config/opencode/skills/` (user-triggered wrappers live
as commands in `~/.config/opencode/commands/`), `~/.claude/skills/` no longer
exists, and `OPENCODE_DISABLE_CLAUDE_CODE=1` (exported in
`~/.config/zsh/.zshrc`) stops OpenCode scanning Claude fallback locations
anyway. Nothing to rewire — just confirm with `opencode debug skill` that
every skill resolves from `~/.config/opencode/skills/`.

(The reckit Claude profile keeps its own Claude-idiom copies of
grill-me/grilling under `~/.config/claude/skills/` — intentionally separate;
archiving `~/.claude` does not affect them.)

## 2. Confine Claude Code to reckit

### 2a. Shell: reckit-only launcher

In `~/.config/zsh/.zshrc`, delete the `claude-personal` and `claude-reckit`
aliases and replace the block with:

```zsh
# --- Claude Code (reckit-only) ----------------------------------------------
# Company tool for reckit work. CLAUDE_CONFIG_DIR=~/.claude-reckit is set by
# mise (~/work/reckit/mise.toml). The wrapper refuses to launch elsewhere so
# no session can start outside the company tree.
claude() {
  [[ "$PWD/" == "$HOME/work/reckit/"* ]] \
    || { echo "claude is reckit-only; cd into ~/work/reckit" >&2; return 1 }
  command claude "$@"
}
# ----------------------------------------------------------------------------
```

### 2b. Context: standalone reckit CLAUDE.md (no machine manual)

Overwrite `~/.claude-reckit/CLAUDE.md` with a self-contained, reckit-only
manual — it must NOT import `~/.config/claude/system.md`:

```markdown
# Reckit work profile — Claude Code

You do reckit (company) work ONLY, inside `~/work/reckit/`. You have no role
outside this directory tree — refuse tasks about the rest of this machine.

- Account: **youssef-goreckit** (`youssef@goreckit.com`), config dir `~/.claude-reckit`.
- Git identity switches automatically here; SSH host alias `github-reckit`
  (clone as `git@github-reckit:youssef-goreckit/<repo>.git`); `gh` uses
  `GH_CONFIG_DIR=~/.config/gh-reckit` (set by mise).
- Runtimes via mise (`mise.toml` per project). Flutter SDKs via `fvm`.
  Editor: nvim (Flutter layer via `NVIM_APPNAME=nvim-flutter`, set by mise).
- Prefer: `rg`, `fd`, `eza`, `bat`, `jq`, `delta`, `lazygit`.
- Never read/commit secrets (`~/.ssh`, gh configs, `.env`). Never run
  `claude auth login/logout`. Confirm before pushing or anything irreversible.
```

### 2c. Enforcement: path-confinement in the reckit guard hook

`~/.config/claude/hooks/guard.sh` is edit-protected for agents — **ask the
user to apply this manually** (or have them temporarily lift the permission).
Extend it so that, in addition to the existing rules, when
`CLAUDE_CONFIG_DIR` ends in `.claude-reckit`:

- `Edit`/`Write` tool calls with `tool_input.file_path` resolving outside
  `~/work/reckit/` (allow `/tmp`, `$TMPDIR`) → deny (exit 2).
- `Bash` commands referencing `~/.config/`, `~/.ssh/`, `~/work/personal/`,
  `~/work/noon/`, or `~/.local/share/opencode/` → deny.

Note honestly: this is a guardrail against drift/accidents, not a sandbox.

### 2d. Trim the reckit profile

- Remove the system-maintainer agent from the reckit profile:
  `rm ~/.claude-reckit/agents/system-maintainer.md` (it's a symlink).
- Keep `~/.claude-reckit/skills/` symlinks (grill-me/grilling are work tools).
- Keep `statusline.sh` (harmless; shows profile/model/dir).

## 3. Decommission the personal Claude profile

1. Archive, don't delete (old session history lives there):
   `mv ~/.claude ~/work/personal/archive/claude-personal-$(date +%Y%m%d)`
   Also archive `~/.claude.json` alongside it. (The guard plugin blocks `rm`
   of `~/.claude*` — moving is the intended path.)
2. In `~/.config/zsh/.zshrc`: confirm no remaining references to the personal
   profile (the 2a wrapper already replaced the aliases; drop stale comments
   about Keychain/profiles pointing at the personal account).
3. Leave `~/.local/share/claude/` + `~/.local/bin/claude` alone — the CLI
   binary itself stays (reckit uses it; it self-updates).
4. Confirm `export OPENCODE_DISABLE_CLAUDE_CODE=1` is still set in
   `~/.config/zsh/.zshrc` (OpenCode section; added 2026-07-05) so OpenCode
   does not scan Claude fallback locations.

## 4. Simplify the shared Claude wiring in dotfiles

1. `~/.config/claude/bootstrap.sh`: rewrite to bootstrap ONLY the reckit
   profile (CLAUDE.md from 2b, settings.json, guard hook, statusline, skills
   symlinks). Remove all personal-profile generation.
2. `~/.config/claude/system.md`: delete it (superseded by
   `~/.config/opencode/AGENTS.md` for OpenCode and by the standalone reckit
   CLAUDE.md for Claude; git history preserves it). Fix any references to it.
3. `~/.claude-reckit/settings.json` is edit-protected — if it needs changes
   (e.g. hook path), ask the user to apply them manually.

## 5. Update OpenCode's own files

1. `~/.config/opencode/AGENTS.md`: remove the §0 TRANSITION bullet; reword §8
   so Claude Code is described as reckit-only (no personal profile); keep the
   reckit-protection rules.
2. `~/.config/opencode/plugins/guard.ts` is edit-protected — ask the user to
   manually trim personal-profile rules if desired (keeping them is harmless).

## 6. Docs + commit

1. Update `~/.config/README.md` + `install.sh`: reproduction flow no longer
   sets up a personal Claude profile; OpenCode setup = brew (Brewfile) +
   `/connect` OpenRouter key; Claude Code section becomes reckit-only.
2. `system-maintainer` doc-accuracy pass over the dotfiles repo to catch any
   remaining stale claims about the old setup.
3. Commit everything in `~/.config` (SSH-signed, personal identity); push
   after user confirmation.

## 7. Verify

- `claude` outside `~/work/reckit` → refused by the wrapper.
- `claude` (via wrapper) inside a reckit repo → reckit profile loads, its
  CLAUDE.md contains no machine-wide context.
- OpenCode restart: skills still load; no references to `~/.claude` remain
  (`rg -i '\.claude\b' ~/.config --glob '!claude/**'` should only show
  intentional reckit/finalization references).
- `git -C ~/.config status` clean after commit.

Report each step's outcome; anything skipped or requiring manual action must
be listed explicitly at the end.
