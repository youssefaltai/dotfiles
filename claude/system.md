# This machine — operating manual for Claude Code

You operate **Youssef's macOS machine**. It is intentionally clean, contained, and
reproducible. Follow these conventions exactly — they are how the system is meant
to be run. (This file is shared by both Claude profiles and lives in the dotfiles repo.)

## 0. Safety — never do these (also enforced by a PreToolUse hook)
- The **personal Claude login is IRREPLACEABLE** — account access was lost and it
  cannot be recreated. NEVER run `claude auth login`/`logout`, NEVER touch the macOS
  Keychain item `Claude Code-credentials`, NEVER set `CLAUDE_CODE_OAUTH_TOKEN`.
- The account-recovery blob (credential + refresh token) lives in the Passwords.app
  entry **"Claude Code old account credentials"** (full JSON in its notes field) —
  keep it; it's the only no-login restore path. The former plaintext
  `~/claude-personal-credentials-BACKUP.json` was removed 2026-06-26.
- Never run catastrophic deletes (`rm -rf ~`, `rm -rf /`, removing `~/.claude*`).
- Never read secrets into output or commit them: `~/.ssh/*`, gh tokens
  (`~/.config/gh*`), any `.env`.
- **Confirm before outward-facing or irreversible actions**: pushing, publishing,
  force-pushing, deleting repos/files you didn't create, renaming remote repos.

## 1. Containment philosophy
- **Binaries**: only via Homebrew → `/opt/homebrew`. No random scripts/`.pkg`s.
- **Configs**: under `~/.config` (XDG). `$HOME` stays clean.
- **Language runtimes**: only via **mise**, per-project. Never `brew install` a
  language for project use; never rely on system python/node.

## 2. Where things go
- `~/.config/<tool>/` — every tool config (git, nvim, ghostty, starship, mise,
  atuin, claude, zsh).
- `~/.config/zsh/.zshrc` + `.zprofile` — shell config (relocated via ZDOTDIR;
  `~/.zshenv` is the only home dotfile).
- `~/work/<context>/` — ALL projects, one folder per context:
  - `~/work/personal/` — personal projects (uses the personal git identity, the default).
  - `~/work/reckit/`   — reckit/company projects (uses the reckit identity override).
  - future companies → `~/work/<company>/`.
- Temp/scratch goes in a tmp dir, never in `~` or `~/.config`.
- **Tools that ignore XDG by default** (npm, pub/Dart, Docker CLI) are pinned to
  XDG dirs via env vars in `~/.config/zsh/.zshrc` (`npm_config_cache`,
  `NPM_CONFIG_USERCONFIG`, `PUB_CACHE`, `DOCKER_CONFIG`); macOS shell-session save
  is off via `SHELL_SESSIONS_DISABLE=1` in `.zprofile`. See those files' comments.
- **Exception — Dart SDK**: `~/.dartServer`, `~/.dart-tool`, `~/.flutter`, and
  `~/.flutter-devtools` remain in `$HOME`; the Dart SDK hardcodes these paths and
  ignores any env override. Do not delete them.

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
- Identity switches automatically via `includeIf gitdir:~/work/reckit/`. Commits are
  SSH-signed; default branch `main`.

## 6. Per-project environment (mise)
- Projects declare runtimes/env in a `mise.toml`: `mise use node@22`, etc.
- Per-project env via `[env]` (e.g. `CLAUDE_CONFIG_DIR`, `NVIM_APPNAME`,
  `GH_CONFIG_DIR`) needs a one-time `mise trust` in that dir.

## 7. Editor
- Neovim 0.12, plugins via built-in `vim.pack`. No plugin-manager framework.
- **Base config**: `~/.config/nvim/init.lua` (lockfile `nvim-pack-lock.json`). Used everywhere.
- **Flutter layer**: `~/.config/nvim-flutter/init.lua` — sources the base config then adds
  Dart LSP + flutter-tools. Activated via `NVIM_APPNAME=nvim-flutter` (set by mise in
  `~/work/reckit/`). Its plugins and state live under `~/.local/share/nvim-flutter`.

## 8. Maintenance routines
- Update: `brew update && brew upgrade && brew cleanup`, then regenerate the
  Brewfile and commit.
- Update nvim plugins (run for both configs; `force = true` skips the interactive
  confirm buffer that would otherwise hang headlessly):
  ```
  nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa
  NVIM_APPNAME=nvim-flutter nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa
  ```
- Keep `~/.config` committed and pushed after meaningful config changes.

## 9. System specs (this machine)
- **MacBook Pro** (`Mac17,2`) — Apple **M5**, 10 cores (4 performance + 6 efficiency).
- **32 GB** unified memory, **arm64**.
- **926 GB** internal SSD.
- macOS **26.5.1** (build `25F80`).
- Static snapshot — edit by hand if hardware/OS changes meaningfully
  (`sysctl -n hw.model machdep.cpu.brand_string hw.memsize` + `sw_vers` to refresh).
