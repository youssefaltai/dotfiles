# This machine — operating manual for OpenCode

You operate **Youssef's macOS machine** (Apple Silicon). It is intentionally clean,
contained, and reproducible. Follow these conventions exactly — they are how the
system is meant to be run. OpenCode + OpenRouter is the primary agent on this
machine and is responsible for maintaining it. (This file lives in the dotfiles
repo at `~/.config/opencode/AGENTS.md` and is loaded into every session.)

## 0. Safety — never do these (also enforced by the guard plugin + permissions)

- **OpenRouter credentials**: never read, print, or commit
  `~/.local/share/opencode/auth.json`. Never delete it — it holds the API key
  auth for this tool.
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
- Config self-modification: you may edit `~/.config/opencode/opencode.jsonc` via
  the Edit tool when asked, but **propose permission/guard changes explicitly and
  get confirmation first**. The guard plugin (`~/.config/opencode/plugins/`) is
  edit-protected — the user changes it manually.

## 1. Containment philosophy

- **Binaries**: only via Homebrew → `/opt/homebrew`. No random scripts/`.pkg`s.
  OpenCode itself is brew-managed (`brew "opencode"` in the Brewfile).
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
- OpenCode uses **one OpenRouter key for all contexts** — AI billing is not
  identity-split (only git/gh identities are).

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
  maintainer. Provider: OpenRouter (`/connect`; key in
  `~/.local/share/opencode/auth.json`). Config: `~/.config/opencode/`
  (`opencode.jsonc`, this file, `plugins/guard.ts`, `agent/`, `skill/`).
  Config changes require an OpenCode restart.
- **Claude Code** — company tool for reckit work only, going forward. Profiles:
  `~/.claude` (personal, active until ~2026-07-10) and `~/.claude-reckit`
  (permanent, selected via `CLAUDE_CONFIG_DIR` set by mise under `~/work/reckit/`).
  Shared wiring in `~/.config/claude/`. Do not migrate, break, or "clean up" any
  of it outside an explicit finalization request (see the
  `finalize-claude-migration` skill).

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
