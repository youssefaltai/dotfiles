# Machine manual — reference detail (read on demand)

Reference companion to `AGENTS.md` (which is auto-loaded into every session
and links here). This file is NOT auto-loaded — Read the relevant section when
a task actually needs it. Keep it truthful; the system-maintainer agent
fact-checks it like any other doc.

## XDG exceptions — what stays in $HOME and why

- **Tools pinned to XDG via env vars** in `~/.config/zsh/.zshrc`: npm
  (`npm_config_cache`, `NPM_CONFIG_USERCONFIG`), pub/Dart (`PUB_CACHE`),
  Docker CLI (`DOCKER_CONFIG`), CocoaPods (`CP_HOME_DIR`), Copilot CLI
  (`COPILOT_HOME`, `COPILOT_CACHE_HOME`). macOS shell-session save is off via
  `SHELL_SESSIONS_DISABLE=1` in `.zprofile`. See those files' comments.
- **Hardcoded `$HOME` paths (do not delete):** `~/.dartServer`, `~/.dart-tool`,
  `~/.flutter`, `~/.flutter-devtools` (Dart SDK), `~/.codex` (Codex CLI),
  `~/.expo` (Expo), `~/.swiftpm` (SwiftPM), `~/.local/share/opencode`
  (OpenCode data: auth, db, logs).
- **Android toolchain** (added 2026-07-06): `~/Android/Sdk` is the full
  Android SDK (Android Studio's default `--sdk_root`, kept after
  `avdmanager`/`sdkmanager` fought a custom path); referenced by `sdk.dir` in
  RN Android projects' `android/local.properties`. `~/.android` and
  `~/.config/.android` hold the AVD (`pixel8`) and adb keys (tool defaults).
  `~/.local/share/gradle` is the intended `GRADLE_USER_HOME`, but that env var
  is **not yet exported** in `~/.config/zsh/.zshrc` (pending Youssef's own
  edit) — until then Gradle falls back to `~/.gradle`.

## Git identities — full mechanics

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
- Identity switches automatically via `includeIf gitdir:~/work/<company>/`.
  Commits are SSH-signed; default branch `main`.
- **Per-profile SSH key** (`id_ed25519_<company>`, auth + signing):
  passphrases served from the macOS login keychain (`AddKeysToAgent` +
  `UseKeychain` in `~/.ssh/config`, one-time `ssh-add --apple-use-keychain`).

## Per-project environment (mise)

- Projects declare runtimes/env in a `mise.toml`: `mise use node@22`, etc.
- Per-project env via `[env]` (e.g. `GH_CONFIG_DIR`, `NVIM_APPNAME`) needs a
  one-time `mise trust` in that dir.
- **Exception — Flutter SDK**: versions managed by `fvm` (Homebrew tap
  `leoafarias/fvm`), not mise. Works alongside mise in `~/work/reckit/`;
  SDKs under `~/.local/share/fvm` (via `FVM_CACHE_PATH` in `.zshrc`).

## Editor

- Neovim 0.12, plugins via built-in `vim.pack`. No plugin-manager framework.
- **Base config**: `~/.config/nvim/init.lua` (lockfile `nvim-pack-lock.json`).
- **Flutter layer**: `~/.config/nvim-flutter/init.lua` — sources the base then
  adds Dart LSP + flutter-tools. Activated via `NVIM_APPNAME=nvim-flutter`
  (set by mise in `~/work/reckit/`). Its plugins/state live under
  `~/.local/share/nvim-flutter`.

## Memory — write protocol (read this before SAVING a memory)

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
  `feedback` — guidance he has given on how to work, corrections and
  confirmed approaches; include the why. `project` — ongoing work, goals, or
  constraints not derivable from code or git history; convert relative dates
  to absolute. `reference` — pointers to external resources.
- **The store is global** (one dir for all projects): project-scoped memories
  start their body with a `Scope: ~/work/...` line and get grouped under that
  project's heading in the index.
- **After writing a file**, add a one-line pointer in `MEMORY.md`
  (`- [Title](file.md) — hook`). One line per memory; index stays under
  ~200 lines — consolidate into topic files if it grows past that.
- **Before saving**, check the index for an existing file that covers it —
  update rather than duplicate; delete memories that turn out wrong. When a
  recalled memory contradicts observed reality, trust reality and fix the
  memory.
- **Per-project memory** (optional): a repo needing a private store gets
  `.opencode/memory/` plus a project `opencode.json` with
  `"instructions": [".opencode/memory/MEMORY.md"]` — same protocol,
  project-scoped.

## System specs (this machine)

- **MacBook Pro** (`Mac17,2`) — Apple **M5**, 10 cores (4 performance + 6 efficiency).
- **32 GB** unified memory, **arm64**.
- **926 GB** internal SSD.
- macOS **26.5.1** (build `25F80`).
- Static snapshot — edit by hand if hardware/OS changes meaningfully
  (`sysctl -n hw.model machdep.cpu.brand_string hw.memsize` + `sw_vers` to refresh).
