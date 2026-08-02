# This machine — operating manual for Claude Code

You operate **Youssef's macOS machine**. It is intentionally clean, contained,
and reproducible. Follow these conventions exactly — they are how the system is
meant to be run.

This file is the authoritative manual. It is shared by every Claude profile and
lives in the dotfiles repo (`~/.config`, a private git repo). `README.md` in
that repo covers only *reproducing the setup on a fresh Mac*; everything about
how the machine is *operated* lives here.

**Claude Code is the only AI agent on this machine.** OpenCode, aider, codex,
gemini-cli, copilot-cli, Cursor and the Claude/ChatGPT desktop apps were all
removed on 2026-08-02. If you find a reference to any of them in a config, doc,
or comment, it is stale — delete it.

---

## 0. Safety — never do these

Some of these are enforced by `claude/hooks/guard.sh` (a PreToolUse hook), which
blocks by exiting 2 and therefore holds even in bypass / auto-accept modes.
See §6 for the full list of what it blocks and why.

- **Never read secrets into output or commit them**: `~/.ssh/*` private keys,
  gh tokens (`~/.config/gh*`), any `.env`, `*.jks` / `*.keystore` / `*.p12`,
  `~/.local/share/machine/keys/*`. Reference the path; never print contents.
  (`.env.example` / `.sample` / `.template` are committed templates and are fine.)
- **Never run catastrophic deletes** (`rm -rf ~`, `rm -rf /`, removing `~/.claude*`).
- **Never force-push in an employer or client repo.** It can destroy a
  colleague's work and is not recoverable by them.
- **Confirm before outward-facing or irreversible actions**: pushing, publishing,
  production deploys, force-pushing, deleting repos or releases, renaming remotes.
- **Claude auth**: both accounts are normal and re-authenticatable. The old
  irreplaceable account is gone; that warning is history, and any doc still
  repeating it is wrong. `guard.sh` still blocks `claude auth login/logout` and
  the Keychain item — a guardrail against accident, not a statement that
  recovery is impossible.
- **The agent must not weaken its own guard.** `settings.json` and
  `claude/hooks/**` are deny-listed for editing. That is deliberate. Changing
  them is a human action.

---

## 1. Containment philosophy

- **Binaries**: only via Homebrew → `/opt/homebrew`. No random scripts or `.pkg`s.
  - *Exception — the Claude Code CLI*: installed by Anthropic's native installer,
    self-managed under `~/.local/share/claude/versions/`, symlinked from
    `~/.local/bin/claude`. It self-updates; leave that alone. Do **not**
    `brew install claude-code` — that creates a second, conflicting install.
- **Configs**: under `~/.config` (XDG). `$HOME` stays clean.
- **Language runtimes**: only via **mise**, per-project. Never `brew install` a
  language for project use; never rely on system python/node.
  - *Exception — Flutter*: SDK versions come from `fvm` (Homebrew tap
    `leoafarias/fvm`), not mise. Caches redirect to `~/.local/share/fvm`.

---

## 2. Where things go

- `~/.config/<tool>/` — every tool config (git, nvim, ghostty, starship, mise,
  atuin, tmux, claude, zsh).
- `~/.config/bin/` — this machine's own scripts, versioned with the dotfiles:
  `ctx` (§5) and `machine-check` (§8). On `PATH` ahead of `~/.local/bin`.
- `~/.config/zsh/env.zsh` — XDG paths and tool relocations, sourced from
  `~/.zshenv` so they apply to **every** zsh, not just interactive ones.
- `~/.config/zsh/.zshrc` + `.zprofile` — shell config (relocated via `ZDOTDIR`;
  `~/.zshenv` is the only home dotfile).
- `~/.local/share/machine/keys/` — API keys read by the shell (Context7, Exa).
- `~/.local/share/machine/keystores/` — app signing keystores (see below).
  Both are deliberately outside the dotfiles repo so they are never committed.
- `~/.local/state/machine-snapshots/` — rollback points (git bundles, config
  backups) taken before large changes.
- `~/work/<context>/` — ALL projects, one directory per context. See §5.
- Temp/scratch goes in a tmp dir, never in `~` or `~/.config`.

**Tools that ignore XDG** are pinned to XDG paths by env vars in
**`~/.config/zsh/env.zsh`**: npm (`npm_config_cache`, `NPM_CONFIG_USERCONFIG`),
Dart/pub (`PUB_CACHE`), Docker (`DOCKER_CONFIG`), CocoaPods (`CP_HOME_DIR`),
atuin (`ATUIN_LOG_DIR`), fvm (`FVM_CACHE_PATH`), Gradle (`GRADLE_USER_HOME`).
macOS shell-session save is off via `SHELL_SESSIONS_DISABLE=1` in `.zprofile`.

**These must stay in `env.zsh`, never `.zshrc`.** `.zshrc` is read only by
interactive shells. When these lived there the machine looked clean to you and
was invisible to everything else — measured 2026-08-02, `~/.npm` held 9,555
files modified in the previous month and `~/.pub-cache` 35,145, because scripts,
IDE build tasks and launchd jobs never saw the variables.

**Known limit**: GUI apps launched from Finder or the Dock (Xcode, Android
Studio) inherit their environment from launchd, not from any shell, so they
still ignore these. Xcode in particular writes `~/Library/Developer` regardless.
Fixing that needs `launchctl setenv` at login; not currently done.

**Unresolved duplication**: `~/.colima` (9.4 GB, live) and `~/.config/colima`
(7.9 GB, ignored) both exist. colima has native XDG support but only uses it
when `~/.colima` is absent, and warns about exactly this on every run. Do **not**
set `COLIMA_HOME` — that would create a third location. Resolve by removing one,
per colima's own message.

**Documented exceptions that stay in `$HOME`** (the tool hardcodes the path and
offers no override):

| Path | Why |
|---|---|
| `~/.dartServer`, `~/.dart-tool`, `~/.flutter`, `~/.flutter-devtools` | Dart SDK hardcodes these |
| `~/.expo` | Expo CLI has no relocation var (expo-cli#2274 open) |
| `~/.swiftpm` | Only per-invocation flags exist (swift-package-manager#6204) |
| `~/Android/Sdk` | Android Studio default; `sdkmanager` fights a custom `--sdk_root` |
| `~/.android`, `~/.config/.android` | AVDs (`pixel8`) + adb keys |

**`$HOME` is not as clean as this table implies.** As of 2026-08-02 it holds 38
hidden entries against ~11 documented here. The rest are small strays left by
tools that ran once (`.app-store`, `.appstoreconnect`, `.hawtjni`, `.storybook`,
`.supabase`, `.yarn`, `.maestro`, `.sentryclirc`, `.expo`, `.private-keys`) plus
caches whose relocation only took effect for interactive shells until `env.zsh`
existed. Treat the table as *intended* state and `ls -A ~` as actual; when they
disagree, one of them is a bug worth fixing rather than documenting.

**Publishing credentials**: `~/.private-keys/` (dir `0700`, files `0600`) holds
App Store Connect API keys (`AuthKey_*.p8`), the iOS distribution certificate
and provisioning profile, and the Google Play service account
(`play-publisher.json`). Together these can **publish to both stores**. Four
scripts in `~/work/dolab-marcom/women/scripts/` reference this exact path, so it
stays where it is rather than moving under `machine/`. It was found at `755`
with `644` files on 2026-08-02 — `machine-check` now asserts the permissions.
Also `~/.maestro/` is a real installed tool (on `PATH` from `.zshrc`), not a
stray — but it is installed outside Homebrew, against §1.

**Signing material**: `~/.local/share/machine/keystores/` (dir `0700`, files
`0600`) holds Android release keystores — currently `kolhagty-upload.jks`,
referenced by absolute path from `$GRADLE_USER_HOME/gradle.properties`. It is
**not** in any repo and **not** backed up off-machine: losing it means the
Kol Hagty app can never be updated on Play Store again. Back it up somewhere
durable.

---

## 3. Tools — prefer these (they are installed)

`rg` over grep, `fd` over find, `eza` over ls, `bat` over cat, plus `fzf`,
`zoxide` (`z`), `jq`, `delta` (git pager), `lazygit`, `gh`, `mise`, `atuin`,
`bottom`, `macmon`, `gitleaks`.

---

## 4. The dotfiles repo (`~/.config` is a private git repo)

- Tracked → private `github.com/youssefaltai/dotfiles`.
- It uses an **allowlist** `.gitignore`: everything is ignored except explicitly
  re-included configs. **To track a new config, add `!name/` and `!name/**`.**
  Forgetting this is how a load-bearing file silently stays untracked — check
  `git status` shows it before assuming it is saved.
- **After installing/removing a brew package**: `brew bundle dump
  --file=~/.config/Brewfile --force`, then commit.
- Commits use the personal identity and are SSH-signed. Review `git status`
  before committing; never stage secrets.

---

## 5. Contexts — identity switching by directory

A **context** is one hat: an employer, a client, or personal work. Each owns a
directory under `~/work`, a git identity, an SSH key, a GitHub account, a Neovim
config, and a Claude Code profile.

### `contexts.toml` is the single source of truth

`~/.config/contexts.toml` defines every context. `~/.config/bin/ctx` generates
all derived wiring from it:

| Generated | What |
|---|---|
| `~/.config/git/config` | `includeIf` blocks + `url.insteadOf` (managed block) |
| `~/.config/git/config-<name>` | the identity |
| `~/.ssh/config` | `Host` aliases (managed block) |
| `~/work/<dir>/mise.toml` | `GH_CONFIG_DIR` / `NVIM_APPNAME` / `CLAUDE_CONFIG_DIR` |

```sh
ctx list             # every context and where it lives
ctx which [path]     # which context owns a path (default: cwd)
ctx check            # drift + unfinished manual steps
ctx sync             # dry run — shows the diff, writes nothing
ctx sync --apply     # write
ctx new <name>       # append a starter block
```

**Never hand-edit inside a `ctx:managed` marker** — `ctx sync` overwrites it.
Everything outside those markers is preserved. Sync is idempotent: a second run
is a no-op. Editing wiring directly instead of the spec is how contexts drift.

**Adding a client**: `ctx new <name>` → fill `email` + `github` → `ctx sync
--apply` → `ctx check` names the two manual steps (upload the SSH key,
`gh auth login`). That is the whole procedure.

### Current contexts

| Context | Kind | Identity | Claude profile | Stack |
|---|---|---|---|---|
| `personal` | personal | `youssef.altai@icloud.com` / `youssefaltai` | personal (default) | TypeScript |
| `reckit` | employer | `youssef@goreckit.com` / `youssef-goreckit` | **reckit** (own login) | Flutter |
| `noon` | employer | `yaltai@noon.com` / `youssefaltai-noon` | personal | React Native |
| `dolab-marcom` | client | GitHub noreply / `DoLab-marcom` | personal | React Native |
| `freelance` | client | *incomplete* | personal | TypeScript |

### Accounts

There are **two** Claude subscriptions: the personal Max x20 (default profile,
`~/.claude`) and a Reckit-provided one (`~/.claude-reckit`, `youssef@goreckit.com`).
**noon, dolab-marcom and freelance all run on the personal subscription.** The
statusline shows `context·profile` precisely so this is never invisible — e.g.
`[noon·personal ⚠]` means noon work billing to the personal account.

Per-context SSH keys serve both auth and signing. Each `Host github-<ctx>` block
carries `AddKeysToAgent yes` + `UseKeychain yes`, so a passphrase is asked once
ever. `mise` `[env]` blocks need a one-time `mise trust` in that directory.

---

## 5b. Life context — `~/work/personal/life`

A private repo (`github.com/youssefaltai/life`) holding durable context about
work and life, so Claude operates as a driver rather than being re-briefed every
session:

| Path | What |
|---|---|
| `contexts/` | One file per job or client — stack, people, conventions, current focus |
| `people/` | Colleagues, clients, contacts |
| `finance/` | Income, rates, invoices, obligations |
| `goals/` | Targets and review cadence |
| `routines/` | Daily/weekly commitments, including `salah.md` |
| `journal/` | Decisions and retrospectives, `YYYY-MM-DD-slug.md` |

**Read the relevant file there before asking about something that ought to be
known already.** Update it when something durable changes. Absolute dates only;
unknowns marked `TODO:` so they stay greppable. It holds **no credentials** —
those live in the Keychain, `~/.ssh`, and `~/.local/share/machine/`.

---

## 6. Delegation — what makes it safe

The point of this setup is that work can be handed off end-to-end. That relies
on structure, not on good intentions:

- **`claude/hooks/guard.sh`** covers exactly one thing: the intersection of
  *what `settings.json` auto-approves* and *damage that cannot be undone*.
  It blocks, by exiting 2: `git reset --hard`, `clean -fd`, `checkout -- .`,
  `branch -D`, `filter-branch`, reflog expiry; force-push including the bare
  `+refspec` form; direct pushes to a shared trunk in employer/client trees;
  `git add` of secrets; `gh repo/release/secret delete`; `npm publish`;
  `find -delete`/`-exec rm`; and shell writes to the hooks, statusline or
  `settings.json`. Strictness follows the context.

  **What it deliberately does NOT cover, and why**: `rm`, `dd`, `mkfs`,
  production deploys and destructive DB commands are *not* in the allow-list, so
  Claude Code already prompts and a human sees them. Guarding them again bought
  nothing and cost false positives — the previous version blocked writing a test
  file because the file *contained* the string `git reset --hard`. Matching now
  ignores quoted spans for the same reason. A guard with false positives gets
  switched off, which is worse than no guard.

  **It is not a security boundary.** Regex over a command string cannot stop
  deliberate obfuscation, and `Bash(python3 *)`/`Bash(node *)`/`Bash(make *)`
  run arbitrary code anyway. It is an accident-catcher for a narrow
  auto-approved surface. The real backstop is git plus the permission prompts.
- **`claude/hooks/guard.test.sh`** is its test suite. **Run it after any change
  to the guard**: `bash ~/.config/claude/hooks/guard.test.sh ~/.config/claude/hooks/guard.sh`.
  It asserts both that dangerous commands are blocked *and* that ~25 ordinary
  ones are not — a guard with false positives gets disabled, which is worse
  than no guard.
- **`claude/session-start.sh`** runs at session start and prints the active
  context, identity, GitHub account, Claude profile and rails — and warns when
  the active profile does not match what the context expects. It lives beside
  `statusline.sh` rather than in `hooks/` because `hooks/**` is deny-listed for
  agent edits. It must never fail a session: every path exits 0.
- **`permissions.defaultMode` is `acceptEdits`.** Edits apply without
  prompting; Bash still prompts; the guard blocks destructive operations in
  every mode. Prompting on each edit bought friction rather than safety, and
  friction is what pushes people into bypass mode, which is strictly worse.
- **Blocked is not forbidden.** The guard constrains the agent, not the human.
  Anything it blocks, Youssef can run himself in a terminal.
- **Report honestly.** State what was verified and how, separately from what was
  assumed. `working-rules.md` governs this and is not optional.

---

### settings.json is generated, not hand-written

`~/.claude*/settings.json` is produced by `claude/bootstrap.sh` from:

    claude/settings.base.json        shared by every profile
    claude/settings.personal.json    deltas for ~/.claude
    claude/settings.reckit.json      deltas for ~/.claude-reckit

merged with `jq` (`.[0] * .[1]`), with `__HOME__` substituted. **Edit the
templates, never the generated file** — and the generated files are deny-listed
for agent edits anyway, so only a human running `bootstrap.sh` can refresh them.
It backs up any existing file whose content differs before overwriting.

This exists because settings.json used to be tracked nowhere, so the most
behaviour-defining file in the setup was not reproducible — and the two profiles
had silently drifted (different effort levels and themes, one carrying a model
pin the other lacked). The only differences now are the ones declared in
`settings.reckit.json`: `effortLevel: xhigh` and `model: opus[1m]`.

## 7. Editor

- Neovim 0.12, plugins via built-in `vim.pack`. No plugin-manager framework.
- **Base config**: `~/.config/nvim/init.lua` (lockfile `nvim-pack-lock.json`).
- **Layers** that `dofile` the base config and add to it:
  - `nvim-flutter` — Dart LSP + flutter-tools (reckit).
  - `nvim-webdev` — web/React Native (noon, dolab-marcom, freelance).
  Selected per-context by `NVIM_APPNAME`; state lives in
  `~/.local/share/nvim-<layer>`.
- Removing a plugin means removing it from `init.lua` **and** from every
  `nvim-pack-lock.json` — the lockfile alone will reinstall it on next launch.

---

## 8. Maintenance

**`machine-check`** runs the whole sweep in one command — context drift, the
guard's test suite, every work repo's uncommitted/unpushed/stashed state,
dotfiles status, keystore presence, outdated packages, disk. It exits non-zero
when anything needs attention. A launchd agent
(`launchd/com.youssef.machine-check.plist`, Mondays 09:00) runs it and appends
to `~/.local/state/machine-check.log`.

```sh
machine-check                                # the sweep
launchctl kickstart -p gui/$UID/com.youssef.machine-check   # run it now

brew update && brew upgrade && brew cleanup
brew bundle dump --file=~/.config/Brewfile --force

# nvim plugins, all three configs (force skips the interactive confirm buffer
# that would otherwise hang headlessly)
nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa
NVIM_APPNAME=nvim-flutter nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa
NVIM_APPNAME=nvim-webdev  nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa

ctx check                                    # context drift
bash ~/.config/claude/hooks/guard.test.sh ~/.config/claude/hooks/guard.sh
```

Keep `~/.config` committed and pushed after meaningful config changes.

---

## 9. System specs (this machine)

- **MacBook Pro** (`Mac17,2`) — Apple **M5**, 10 cores (4 performance + 6 efficiency).
- **32 GB** unified memory, **arm64**. **926 GB** SSD.
- macOS **26.5.1** (build `25F80`).

Static snapshot — refresh by hand with
`sysctl -n hw.model machdep.cpu.brand_string hw.memsize` + `sw_vers`.
