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
- **TRANSITION (until ~2026-07-10)**: the personal Claude Code subscription is
  still active and its login is IRREPLACEABLE — NEVER run
  `claude auth login`/`logout`, NEVER touch the macOS Keychain items
  `Claude Code-credentials*`, NEVER set `CLAUDE_CODE_OAUTH_TOKEN`. The
  account-recovery blob lives in the Passwords.app entry
  **"Claude Code old account credentials"** — keep it. When the subscription
  ends, finalize the migration with the `finalize-claude-migration` skill.
- **Reckit's Claude Code profile is permanent** (company team subscription):
  never delete `~/.claude-reckit/` or break its wiring
  (`~/.config/claude/{system.md,hooks/guard.sh,statusline.sh}`,
  `CLAUDE_CONFIG_DIR` in `~/work/reckit/mise.toml`).
- Never run catastrophic deletes (`rm -rf ~`, `rm -rf /`, removing `~/.claude*`
  or `~/.config/opencode`).
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
  **Exception — Claude Code CLI**: installed via Anthropic's native installer,
  self-managed under `~/.local/share/claude/versions/` (symlinked from
  `~/.local/bin/claude`). It stays for the reckit (company) profile; leave its
  self-update mechanism alone (do not `brew install claude-code`).
- **Configs**: under `~/.config` (XDG). `$HOME` stays clean.
- **Language runtimes**: only via **mise**, per-project. Never `brew install` a
  language for project use; never rely on system python/node.

## 2. Where things go

- `~/.config/<tool>/` — every tool config (git, nvim, ghostty, starship, mise,
  atuin, tmux, zsh, opencode, claude).
- `~/.config/zsh/.zshrc` + `.zprofile` — shell config (relocated via ZDOTDIR;
  `~/.zshenv` is the only home dotfile).
- `~/work/<context>/` — ALL projects, one folder per context:
  - `~/work/personal/` — personal projects (personal git identity, the default).
  - `~/work/reckit/`   — reckit/company projects (reckit identity override).
  - `~/work/noon/`     — noon/company projects (noon identity override).
  - future companies → `~/work/<company>/`.
- Temp/scratch goes in a tmp dir, never in `~` or `~/.config`.
- **Tools that ignore XDG by default** (npm, pub/Dart, Docker CLI, CocoaPods,
  Copilot CLI) are pinned to XDG dirs via env vars in `~/.config/zsh/.zshrc`
  (`npm_config_cache`, `NPM_CONFIG_USERCONFIG`, `PUB_CACHE`, `DOCKER_CONFIG`,
  `CP_HOME_DIR`, `COPILOT_HOME`, `COPILOT_CACHE_HOME`); macOS shell-session save
  is off via `SHELL_SESSIONS_DISABLE=1` in `.zprofile`. See those files' comments.
- **Documented exceptions that stay in `$HOME`** (hardcoded paths, do not delete):
  `~/.dartServer`, `~/.dart-tool`, `~/.flutter`, `~/.flutter-devtools` (Dart SDK),
  `~/.codex` (Codex CLI), `~/.expo` (Expo), `~/.swiftpm` (SwiftPM),
  `~/.claude` + `~/.claude-reckit` (Claude Code profile dirs; see §0),
  `~/.local/share/opencode` (OpenCode data: auth, db, logs).
- **Exception — Android toolchain** (added 2026-07-06): `~/Android/Sdk` is the
  full Android SDK (Android Studio's default `--sdk_root`, kept there after
  `avdmanager`/`sdkmanager` fought a custom path); referenced by `sdk.dir` in RN
  Android projects' `android/local.properties`. `~/.android` and
  `~/.config/.android` hold the AVD (`pixel8`) and adb keys (tool defaults).
  `~/.local/share/gradle` is the intended `GRADLE_USER_HOME`, but that env var
  is **not yet exported** in `~/.config/zsh/.zshrc` (pending Youssef's own
  edit) — until then Gradle falls back to `~/.gradle`.

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

- **Personal** (default): `Youssef` / `youssef.altai@icloud.com`, GitHub
  `youssefaltai`, SSH host `github.com`.
- **Reckit** (under `~/work/reckit/`): `youssef@goreckit.com`, GitHub
  `youssef-goreckit`, SSH host alias **`github-reckit`** (clone as
  `git@github-reckit:youssef-goreckit/<repo>.git`), gh via
  `GH_CONFIG_DIR=~/.config/gh-reckit`.
- **Noon** (under `~/work/noon/`): `yaltai@noon.com`, GitHub `youssefaltai-noon`,
  SSH host alias **`github-noon`** (clone as
  `git@github-noon:youssefaltai-noon/<repo>.git`), gh via
  `GH_CONFIG_DIR=~/.config/gh-noon`.
- Identity switches automatically via `includeIf gitdir:~/work/<company>/`. Commits
  are SSH-signed; default branch `main`.
- **Per-profile SSH key** (`id_ed25519_<company>`, used for both auth and signing):
  passphrases are served from the macOS login keychain (`AddKeysToAgent` +
  `UseKeychain` in `~/.ssh/config`, one-time `ssh-add --apple-use-keychain`).
- OpenCode uses **one model-provider account for all contexts** (DeepSeek direct;
  key in `auth.json`) — AI billing is not identity-split (only git/gh identities
  are).

## 6. Per-project environment (mise)

- Projects declare runtimes/env in a `mise.toml`: `mise use node@22`, etc.
- Per-project env via `[env]` (e.g. `GH_CONFIG_DIR`, `NVIM_APPNAME`,
  `CLAUDE_CONFIG_DIR` for reckit) needs a one-time `mise trust` in that dir.
- **Exception — Flutter SDK**: Flutter SDK versions are managed by `fvm` (installed
  via the `leoafarias/fvm` Homebrew tap), not mise. `fvm` works alongside mise in
  `~/work/reckit/` and stores SDKs under `~/.local/share/fvm` (redirected via
  `FVM_CACHE_PATH` in `.zshrc`).

## 7. Editor

- Neovim 0.12, plugins via built-in `vim.pack`. No plugin-manager framework.
- **Base config**: `~/.config/nvim/init.lua` (lockfile `nvim-pack-lock.json`). Used everywhere.
- **Flutter layer**: `~/.config/nvim-flutter/init.lua` — sources the base config then adds
  Dart LSP + flutter-tools. Activated via `NVIM_APPNAME=nvim-flutter` (set by mise in
  `~/work/reckit/`). Its plugins and state live under `~/.local/share/nvim-flutter`.

## 8. AI tooling on this machine

- **OpenCode (this tool)** — the primary agent everywhere, and the system
  maintainer. Provider: DeepSeek direct API (key in
  `~/.local/share/opencode/auth.json`; OpenCode Zen and OpenRouter keys also
  present as alternatives). Config: `~/.config/opencode/` (`opencode.jsonc`,
  this file, `plugins/guard.ts`, `agents/`, `commands/`, `skills/`, `prompts/`).
  Config changes require an OpenCode restart.
- **Claude Code** — reckit-only company tool (unavoidable requirement); never
  used outside `~/work/reckit/`. Profiles: `~/.claude` (personal, decommissions
  ~2026-07-10 via the `finalize-claude-migration` skill) and `~/.claude-reckit`
  (permanent, selected via `CLAUDE_CONFIG_DIR` set by mise under `~/work/reckit/`).
  Shared wiring in `~/.config/claude/`. Do not migrate, break, or "clean up" any
  of it outside an explicit finalization request.
- **Isolation**: OpenCode never reads or uses anything of Claude Code's —
  `OPENCODE_DISABLE_CLAUDE_CODE=1` is exported in `~/.config/zsh/.zshrc`, which
  disables OpenCode's built-in reading of `CLAUDE.md` files and `~/.claude/skills/`.
  Instructions come from `AGENTS.md` only; skills from `skills/` +
  `.opencode/skills/` only. The Claude paths in the edit-deny permission list are
  *protection* of reckit's tooling, not usage.

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

Each memory is one file holding one fact, with frontmatter:

```markdown
---
name: <short-kebab-case-slug>
description: <one-line summary — used to decide relevance from the index>
metadata:
  type: user | feedback | project | reference
---

<the fact; for feedback/project, follow with **Why:** and **How to apply:**
lines. Link related memories with [[their-name]].>
```

- **Types**: `user` — who Youssef is (role, expertise, preferences).
  `feedback` — guidance he has given on how to work, both corrections and
  confirmed approaches; include the why. `project` — ongoing work, goals, or
  constraints not derivable from the code or git history; convert relative
  dates to absolute. `reference` — pointers to external resources (URLs,
  dashboards, tickets).
- **When to save**: after user corrections, non-obvious hard-won findings
  (gotchas, verified workarounds), and decisions with lasting scope. Don't
  save what a repo already records (code structure, git history, its own
  AGENTS.md/docs) or what only matters to the current conversation.
- **The store is global** (one dir for all projects): project-scoped memories
  start their body with a `Scope: ~/work/...` line and get grouped under that
  project's heading in the index.
- **After writing a file**, add a one-line pointer in `MEMORY.md`
  (`- [Title](file.md) — hook`). The index stays one line per memory — never
  put memory content there.
- **Before saving**, check the index for an existing file that already covers
  it — update that file rather than creating a duplicate; delete memories
  that turn out to be wrong. Stale memories are worse than none: when a
  recalled memory contradicts observed reality, trust reality and fix the
  memory.
- `memory/` is deliberately **not tracked** in the dotfiles repo (runtime
  state, may contain company-work details) — don't commit it or "fix" its
  gitignore entry.

## 11. System specs (this machine)

- **MacBook Pro** (`Mac17,2`) — Apple **M5**, 10 cores (4 performance + 6 efficiency).
- **32 GB** unified memory, **arm64**.
- **926 GB** internal SSD.
- macOS **26.5.1** (build `25F80`).
- Static snapshot — edit by hand if hardware/OS changes meaningfully
  (`sysctl -n hw.model machdep.cpu.brand_string hw.memsize` + `sw_vers` to refresh).
