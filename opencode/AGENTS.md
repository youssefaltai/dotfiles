# This machine — operating manual for OpenCode

You operate **Youssef's macOS machine** (Apple Silicon). It is intentionally clean,
contained, and reproducible. Follow these conventions exactly — they are how the
system is meant to be run. OpenCode is the primary agent on this machine and is
responsible for maintaining it. (This file lives in the dotfiles repo at
`~/.config/opencode/AGENTS.md` and is loaded into every session.)

## 0. Safety — never do these (also enforced by the guard plugin + permissions)

- **Provider credentials**: never read, print, or commit
  `~/.local/share/opencode/auth.json`. Never delete it — it holds the API key
  auth for this tool (DeepSeek direct, plus OpenCode Zen and OpenRouter).
- Never run catastrophic deletes (`rm -rf ~`, `rm -rf /`, removing
  `~/.config/opencode`).
- Never read secrets into output or commit them: `~/.ssh/*`, gh configs
  (`~/.config/gh*`), any `.env`.
- **Confirm before outward-facing or irreversible actions**: pushing, publishing,
  force-pushing, deleting repos/files you didn't create, renaming remote repos.
- Config self-modification: you may edit the OpenCode config (`opencode.jsonc`,
  `agents/`, `commands/`, `skills/`, `prompts/`, and plugins under `plugins/`)
  via the Edit tool when asked, but **propose permission/guard changes explicitly
  and get confirmation first**. The one exception is the guard plugin itself
  (`~/.config/opencode/plugins/guard.ts`): it is edit-protected and only the
  user changes it, so no single agent action can defang the guardrails.

## 1. Containment philosophy

- **Binaries**: only via Homebrew → `/opt/homebrew`. No random scripts/`.pkg`s.
  OpenCode itself is brew-managed (`brew "anomalyco/tap/opencode"` in the Brewfile).
- **Configs**: under `~/.config` (XDG). `$HOME` stays clean.
- **Language runtimes**: only via **mise**, per-project. Never `brew install` a
  language for project use; never rely on system python/node.

## 2. Where things go

- `~/.config/<tool>/` — every tool config (git, nvim, ghostty, starship, mise,
  atuin, tmux, zsh, opencode).
- `~/.config/zsh/.zshrc` + `.zprofile` — shell config (relocated via ZDOTDIR;
  `~/.zshenv` is the only home dotfile).
- `~/work/<context>/` — ALL projects, one folder per context:
  - `~/work/personal/` — personal projects (personal git identity, the default).
  - `~/work/reckit/`   — reckit/company projects (reckit identity override).
  - `~/work/noon/`     — noon/company projects (noon identity override).
  - future companies → `~/work/<company>/`.
- Temp/scratch goes in a tmp dir, never in `~` or `~/.config`.
- **XDG exceptions** (tools pinned via env vars, hardcoded `$HOME` paths like
  `~/.dartServer`/`~/.codex`/`~/.expo`/`~/.swiftpm`, the Android toolchain at
  `~/Android/Sdk`): full list + rationale in
  `~/.config/opencode/docs/machine-manual.md` — Read it before touching
  anything unusual in `$HOME`; those paths are intentional, do not delete.

## 3. Tools — prefer these (they are installed)

`rg` over grep, `fd` over find, `eza` over ls, `bat` over cat, plus `fzf`, `zoxide`
(`z`), `jq`, `delta` (git pager), `lazygit`, `gh`, `mise`, `atuin`.

## 4. The dotfiles repo (`~/.config` is a private git repo)

- `~/.config` is git-tracked → private `github.com/youssefaltai/dotfiles`.
- It uses an **allowlist** `.gitignore`: everything ignored except explicitly
  re-included configs. **To track a new config, add `!name/` and `!name/**`** to
  `~/.config/.gitignore`.
- **After installing/removing a brew package**: `brew bundle dump
  --file=~/.config/Brewfile --force`, then commit.
- Commits from `~/.config` use the personal identity and are SSH-signed. Review
  `git status` before committing; never stage secrets.

## 5. Git identity & accounts (auto-switch by directory)

- Three identities, switched automatically by `includeIf gitdir:~/work/<company>/`:
  **personal** (default, GitHub `youssefaltai`), **reckit** (`~/work/reckit/`,
  SSH host alias `github-reckit`, `GH_CONFIG_DIR=~/.config/gh-reckit`), and
  **noon** (`~/work/noon/`, alias `github-noon`, `GH_CONFIG_DIR=~/.config/gh-noon`).
  Commits SSH-signed; default branch `main`. Full mechanics (emails, clone
  URLs, keychain SSH setup): `docs/machine-manual.md` — Read it before any
  clone/remote/identity work in a company context.
- OpenCode uses **one model-provider account for all contexts** (DeepSeek direct;
  key in `auth.json`) — AI billing is not identity-split (only git/gh identities
  are).

## 6. Per-project environment (mise) & editor

- Runtimes/env per project via `mise.toml` (`mise use node@22`; `[env]` needs a
  one-time `mise trust`). Flutter SDKs via `fvm`, not mise. Editor: Neovim 0.12
  (base config + `nvim-flutter` layer for reckit). Detail:
  `docs/machine-manual.md`.

## 8. AI tooling on this machine

- **OpenCode (this tool)** — the primary agent everywhere, and the system
  maintainer. Provider: DeepSeek direct API (key in
  `~/.local/share/opencode/auth.json`; OpenCode Zen and OpenRouter keys also
  present as alternatives). Config: `~/.config/opencode/` (`opencode.jsonc`,
  this file, `plugins/guard.ts`, `agents/`, `commands/`, `skills/`, `prompts/`).
  Config changes require an OpenCode restart. Permission modes — Tab cycles
  `default` (edits ask) → `accept-edits` → `auto` (local free, outward asks) →
  `plan` (read-only).

## 9. Maintenance routines

- Update: `brew update && brew upgrade && brew cleanup`, then regenerate the
  Brewfile (`brew bundle dump --file=~/.config/Brewfile --force`) and commit.
  This also keeps OpenCode itself updated (brew formula).
- Update nvim plugins (run for both configs; `force = true` skips the interactive
  confirm buffer that would otherwise hang headlessly):
  ```
  nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa
  NVIM_APPNAME=nvim-flutter nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa
  ```
- Keep the dotfiles repo committed and pushed after meaningful config changes
  (confirm before pushing).
- Keep documentation truthful: README, this file, config comments — fact-check
  claims against the real system state and fix drift (the `system-maintainer`
  agent does this on request).

## 10. Memory — persist what you learn across sessions

You have a persistent file-based memory at `~/.config/opencode/memory/`. The
index (`memory/MEMORY.md`) is auto-loaded into every session via the
`instructions` field in `opencode.jsonc`; the memories themselves are read on
demand — when an index line looks relevant to the task at hand, Read that file
before acting.

- **When to save**: after user corrections, non-obvious hard-won findings
  (gotchas, verified workarounds), and decisions with lasting scope. Don't
  save what a repo already records (code structure, git history, its own
  AGENTS.md/docs) or what only matters to the current conversation.
- **Before SAVING a memory**, Read the "Memory — write protocol" section of
  `docs/machine-manual.md` for the frontmatter schema and full rules (one
  fact per file, update-don't-duplicate, add an index one-liner after every
  write, delete memories that turn out wrong — when a recalled memory
  contradicts observed reality, trust reality and fix the memory).
- `memory/` is deliberately **not tracked** in the dotfiles repo (runtime
  state, may contain company-work details) — don't commit it or "fix" its
  gitignore entry.

(System specs and all other reference detail live in
`docs/machine-manual.md` — Read on demand, never loaded by default.)
