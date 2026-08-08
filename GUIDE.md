# Day-to-day guide

How to actually run a day on this machine.

There are three documents here and they do different jobs:

| File | For | About |
|---|---|---|
| `README.md` | you, once | rebuilding this setup on a fresh Mac |
| `claude/system.md` | Claude, every session | how the machine is *built* and what is forbidden |
| **`GUIDE.md`** (this) | **you, daily** | **how to drive it** |

---

## 0. The one rule that makes everything else work

**`cd` into the right directory before you do anything.**

Identity on this machine is a function of the current directory. Nothing else.
There is no "switch account" command and there is no profile to remember to
change. Landing in `~/work/noon/bappzaar` gets you — automatically, with no
action from you:

- the `yaltai@noon.com` git identity and the noon signing key
- `git push` going out over the `github-noon` SSH alias
- `gh` reading `~/.config/gh-noon`, so `gh pr list` shows noon's PRs
- `nvim` loading the `nvim-webdev` layer
- node 24, yarn and Temurin 17 on `PATH`
- Claude Code running the **personal** profile

Every mistake this setup is designed to prevent — committing as the wrong
person, pushing with the wrong key, opening a PR from the wrong account — comes
from working somewhere other than under `~/work/<context>/`.

Verify at any time:

```sh
ctx which          # which context owns the current directory
ctx which ~/some/path
```

If `ctx which` says the wrong thing, stop and fix that before you write code.

---

## 1. Starting the day

```sh
ctx check          # context drift + unfinished manual steps. Want: "✓ no outstanding work"
```

Then open Claude Code in whichever context you're starting in and run:

```
/ctx
```

That reconstructs the state of the context — what's in flight, what's blocked,
what's next. Re-entering a context after a day in a different one is the single
most expensive moment in this workflow; `/ctx` is what makes it cheap. Run it
every time you switch, not just in the morning.

`/ctx <name>` briefs a context you're not currently sitting in.

### Where the day's shape is written down

`~/work/personal/life/routines/daily.md` holds the real grid. The load-bearing
facts:

| | Mon | Tue | Wed | Thu | Fri |
|---|---|---|---|---|---|
| **10:00** | Reckit standup | Reckit | Reckit | Reckit | Reckit |
| **10:30** | **noon standup** ⚠ | — | — | — | — |
| **14:00** | — | — | **noon catch-up** | — | — |
| **15:00** | Reckit overlap | Reckit | Reckit | Reckit | Reckit |

- **~04:30–10:00 is the only uncontested block in the day.** Post-Fajr,
  meeting-free, nothing from either job competes for it. Put the work that
  needs concentration here. Everything after 10:00 is interleaved and reactive
  by force — both jobs are officially 10:00–18:00 and overlap completely.
- **Monday 10:00–11:00 and Wednesday 14:00–16:00 are hard blocks.** Don't plan
  focused work there.
- **noon's code freeze is Thursday 16:10 UTC (19:10 Cairo) → Monday 06:00 UTC.**
  Merges to `master` are blocked over the weekend. This is the hardest weekly
  deadline either job imposes; treat Thursday as the real due date.

---

## 2. The five contexts

```sh
ctx list           # every context and where it lives
```

| Context | Directory | Identity | nvim | gh config | Claude |
|---|---|---|---|---|---|
| `personal` | `~/work/personal/` | `youssef.altai@icloud.com` | `nvim` | `gh` | personal |
| `reckit` | `~/work/reckit/` | `youssef@goreckit.com` | `nvim-flutter` | `gh-reckit` | **reckit** |
| `noon` | `~/work/noon/` | `yaltai@noon.com` | `nvim-webdev` | `gh-noon` | personal |
| `dolab-marcom` | `~/work/dolab-marcom/` | GitHub noreply | `nvim-webdev` | `gh-dolab` | personal |
| `freelance` | `~/work/freelance/<client>/` | personal | `nvim-webdev` | `gh` | personal |

**Reckit is the only context with its own Claude subscription.** Everything else
bills the personal Max x20. The statusline shows `context·profile` precisely so
this is never invisible: `[noon·personal ⚠]` means noon work on the personal
account (which noon permits — read the ⚠ as a billing reminder, not a
compliance problem).

**Contexts are strictly isolated.** Never let information cross between them —
not in code, comments, commit messages, branch names, PR text, or anything
drafted on your behalf. The full rule and its reasoning live in
`~/work/personal/life/operating-constraints.md`.

### Adding a client

```sh
ctx new <name>              # appends a starter block to contexts.toml
$EDITOR ~/.config/contexts.toml     # fill in email + github
ctx sync                    # dry run — read the diff
ctx sync --apply            # write it
ctx check                   # names the two steps only a human can do
```

The two manual steps are always the same: upload the SSH key to that GitHub
account, and `gh auth login`. Nothing else.

**Never hand-edit inside a `ctx:managed` marker** — `ctx sync` overwrites it.
Everything outside those markers is preserved. Editing the generated wiring
instead of `contexts.toml` is how contexts drift.

A *freelance* client is cheaper still: it's one subdirectory of
`~/work/freelance/`, sharing the identity. No key, no account, no profile.

---

## 3. Claude Code, day-to-day

### Launching

Just run `claude` inside the context directory — `mise` sets
`CLAUDE_CONFIG_DIR` for you. Check the statusline reads the right
`context·profile`. If a Reckit directory shows `personal`, run `mise trust`
there once.

Two escape hatches when you need to override:

```sh
claude-personal    # force the personal profile
claude-reckit      # force the reckit profile
```

### The slash commands worth knowing

| Command | What it does |
|---|---|
| `/ctx [name]` | Brief me on a context — in flight, blocked, next. **Run on every switch.** |
| `/standup [since]` | Draft a status update for the current context. Defaults to since yesterday. |
| `/wrap` | End-of-day sweep across **every** context — nothing uncommitted, unpushed, or forgotten. |
| `/grill-me` | Relentless one-question-at-a-time interview to stress-test a plan before building. |

`/standup` matters because there are three standups a week with three different
shapes, and it reads them from the context files rather than making you
remember: Reckit FE daily is *Yesterday / Today / Blockers*; Reckit overlap has
no status at all; noon Monday is *On my plate / Planned next / Blockers*.

### Handing over whole tasks

Say **"handle this"**, **"take care of X"**, or **"do this while I…"** and the
`delegate` skill activates — the protocol for running something end-to-end
without supervision. That phrasing is the trigger, so use it deliberately when
you mean it.

Two agents are available for delegation:

- **`verifier`** — adversarially checks whether claimed-complete work actually
  works. Worth invoking before you mark a PR ready, given that the standing
  Reckit feedback is about definition-of-done.
- **`system-maintainer`** — brew/nvim updates, Brewfile regeneration, dotfiles
  commits, and fact-checking docs and comments against reality.

### What Claude can and cannot do here

`permissions.defaultMode` is **`acceptEdits`** — file edits apply without
prompting, Bash still prompts. 47 allow rules, 29 deny rules, zero ask rules.

The deny list is absolute and covers reading `~/.ssh/**`, every `gh` config,
`~/.local/share/machine/**`, `~/.private-keys/**`, every `.env` variant, and
`*.jks` / `*.keystore` / `*.p12` / `*.pem` / `*.p8` / `*.mobileprovision`. It
also blocks editing `hooks/**` and either generated `settings.json`.

On top of that, `claude/hooks/guard.sh` (a PreToolUse hook) hard-blocks by
exiting 2 — so it holds even in bypass mode: `git reset --hard`, `clean -fd`,
`checkout -- .`, `branch -D`, `filter-branch`, reflog expiry, force-push in any
form, direct pushes to a shared trunk in employer/client trees, `git add` of
secrets, `gh repo/release/secret delete`, `npm publish`, `find -delete`.

**Blocked is not forbidden.** The guard constrains the agent, not you. Anything
it blocks, you can run yourself in a terminal.

### Settings are generated, not edited

`~/.claude*/settings.json` is produced by `claude/bootstrap.sh` from
`settings.base.json` + `settings.personal.json` / `settings.reckit.json`.
**Edit the templates and re-run `bootstrap.sh`** — never the generated file.

---

## 4. tmux

Prefix is **`Ctrl-Space`**. Windows and panes are 1-indexed and renumber when
you close one. Mouse is on.

| Key | Does |
|---|---|
| `prefix` `\|` / `-` | split vertical / horizontal, in the current directory |
| `prefix` `c` | new window, in the current directory |
| `Ctrl-h/j/k/l` | move between panes — **and between nvim splits**, seamlessly |
| `prefix` `H/J/K/L` | resize, repeatable |
| `prefix` `g` | lazygit in a full-screen popup |
| `prefix` `m` / `M` | macmon / bottom in a popup |
| `prefix` `r` | reload tmux.conf |

The `-c "#{pane_current_path}"` on the split and new-window bindings is
load-bearing: a new pane inherits the current directory, which means it
inherits the **context**. Splitting inside `~/work/reckit/` gives you another
Reckit shell, correctly wired.

A practical layout is one tmux window per context, named for it, each already
`cd`'d in. Switching contexts becomes a window switch, and the wiring follows.

---

## 5. Per-context commands

### Reckit — Flutter, melos monorepo

Flutter SDK comes from **fvm**, not mise. Prefix Flutter/Dart commands with
`fvm` so you get the pinned version.

Branch flow is `dev` → `stage` → `master`; PRs target `dev`. Tickets are
`GOR-####` in Linear. **Ahmed merges everything** — you don't merge your own.

Keep PRs **≤ 25 files**; Cursor Bugbot flags anything larger.

### noon — React Native, bappzaar

```sh
yarn start
yarn test              # jest
yarn oxlint
yarn tsc               # non-strict project
yarn tsc:strict
yarn maestro:e2e:nownow
yarn lint:cycles
yarn lint:unused-styles
```

Base branch is always `master`. Branches are `nownow/<type>/NNV2-####`.
Conventional Commits with an mp scope: `fix(nownow): …`. **You merge your own
PRs** once approved — the inverse of Reckit.

The PR template is substantial and gates review: test build number, API
environment, PRD link, test plan, Figma link, API contract, affected screens,
before/after screenshots, and a checklist asserting you verified on iOS,
Android **and Huawei**, in English **and Arabic**. RTL and Huawei are
first-class here, not edge cases.

### Tools to reach for by default

`rg` over grep · `fd` over find · `eza` over ls (`ll`, `lt`) · `bat` over cat ·
`lg` for lazygit · `z` for zoxide · `fzf` · `jq` · `delta` (git pager) · `gh` ·
`gitleaks` · `bottom` · `macmon`

---

## 6. Ending the day

```
/wrap
```

Sweeps **every** context, not just the one you're sitting in — uncommitted,
unpushed, stashed, forgotten. Working across two full-time jobs plus client
work means work you left this morning in a context you haven't touched since is
genuinely easy to lose.

The failure mode this catches is real and has happened: a branch with thousands
of lines existing on one disk only, with no upstream, because the day ended in
a different context.

---

## 7. Weekly maintenance

`machine-check` runs the whole sweep in one command — context drift, the
guard's test suite, every work repo's uncommitted/unpushed/stashed state,
dotfiles status, keystore presence, outdated packages, disk. It exits non-zero
when anything needs attention.

A launchd agent runs it **Mondays 09:00** and appends to
`~/.local/state/machine-check.log`.

```sh
machine-check
launchctl kickstart -p gui/$UID/com.youssef.machine-check   # run it now

brew update && brew upgrade && brew cleanup
brew bundle dump --file=~/.config/Brewfile --force           # then commit

nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa
NVIM_APPNAME=nvim-flutter nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa
NVIM_APPNAME=nvim-webdev  nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa
```

Or hand the whole thing to the `system-maintainer` agent.

**After installing or removing a brew package**, regenerate the Brewfile and
commit — otherwise the next fresh-Mac rebuild silently loses it.

**To track a new config in the dotfiles repo**, add `!name/` and `!name/**` to
`.gitignore`. The repo uses an *allowlist*, so a new file is ignored by
default. Check `git status` shows it before assuming it's saved — forgetting
this is how a load-bearing file stays untracked.

---

## 8. When something is wrong

| Symptom | Check |
|---|---|
| Commits attributed to the wrong identity | `ctx which` — you're in the wrong directory |
| `gh` shows the wrong account's PRs | same; `GH_CONFIG_DIR` follows the directory |
| Statusline shows the wrong profile | `mise trust` in that directory, once |
| `git push` asks for a passphrase repeatedly | the `Host` block should have `AddKeysToAgent` + `UseKeychain`; `ctx sync --apply` |
| nvim missing the Dart/web layer | `NVIM_APPNAME` comes from the context's `mise.toml`; `ctx check` |
| Wiring looks hand-edited and keeps reverting | you edited inside a `ctx:managed` marker. Edit `contexts.toml` instead |
| Removed an nvim plugin and it came back | remove it from `init.lua` **and** every `nvim-pack-lock.json` |

### Where durable context lives

`~/work/personal/life` — a private repo holding what would otherwise have to be
re-explained every session:

| Path | What |
|---|---|
| `operating-constraints.md` | Hard rules that override convenience. **Read first.** |
| `contexts/` | One file per job or client — stack, people, conventions, current focus |
| `people/` · `finance/` · `goals/` · `routines/` | Who, money, targets, commitments |
| `journal/` | Decisions and retrospectives, `YYYY-MM-DD-slug.md` |

**Read the relevant file there before asking about something that should
already be known.** Update it when something durable changes. Absolute dates
only; unknowns marked `TODO:` so they stay greppable. No credentials — those
live in the Keychain, `~/.ssh`, and `~/.local/share/machine/`.

---

## 9. Things that will bite you eventually

- **`kolhagty-upload.jks` is not backed up off-machine.** It lives only in
  `~/.local/share/machine/keystores/`. Losing it means the Kol Hagty app can
  never be updated on Play Store again. This is the single highest-consequence
  unmitigated risk on the machine.
- **GUI apps launched from Finder or the Dock** (Xcode, Android Studio) inherit
  their environment from launchd, not from a shell — so they ignore every XDG
  relocation in `zsh/env.zsh`. Xcode writes `~/Library/Developer` regardless.
- **`~/.colima` and `~/.config/colima` both exist** (~9.4 GB and ~7.9 GB).
  colima uses XDG only when `~/.colima` is absent, and warns about this on every
  run. Do **not** set `COLIMA_HOME` — that makes a third location. Remove one.
- **Environment variables must go in `zsh/env.zsh`, never `.zshrc`.** `.zshrc`
  is read only by interactive shells; scripts, IDE build tasks and launchd jobs
  never see it. That's how `~/.npm` accumulated 9,555 files while the machine
  looked clean.
