# dotfiles — `~/.config`

Private, XDG-based configuration for Youssef's macOS machine. This repo **is**
`~/.config`: it is cloned directly into that path, and `$HOME` stays clean.

The operating philosophy — containment, where things go, contexts and identity
switching, delegation safety, and the maintenance routines — lives in
[`claude/system.md`](claude/system.md), the single authoritative manual. This
README covers only **reproducing the setup on a fresh Mac**.

For **driving the machine day to day** — starting a day, switching contexts,
the slash commands, tmux, ending a day — see [`GUIDE.md`](GUIDE.md).

Claude Code is the only AI agent on this machine (since 2026-08-02).

---

## Reproduce on a new Mac

`install.sh` automates the mechanical, idempotent parts. A few steps are
**manual by design** — SSH private keys and account logins are secrets, and are
(correctly) not in this repo.

### 0. Prerequisites (manual, once)

```sh
# Xcode Command Line Tools — provides git, needed before anything else
xcode-select --install
```

Claude Code itself is **not** installed by `install.sh` (it isn't Homebrew-managed
on this machine — see the exception in `system.md` §1). If you're not already
running Claude Code to do this reproduction, install it per Anthropic's current
docs (docs.claude.com) before continuing; it self-updates afterward.

### 1. Clone this repo into `~/.config`

`~/.config` must not already exist (a fresh Mac won't have it). Clone over HTTPS
first — SSH keys don't exist yet; `install.sh` flips the remote to SSH for you.

```sh
git clone https://github.com/youssefaltai/dotfiles.git "$HOME/.config"
```

### 2. Run the installer

```sh
~/.config/install.sh
```

It is idempotent — safe to re-run. It will:

| Step | Action |
|------|--------|
| `~/.zshenv` | Write the one home dotfile that points `ZDOTDIR` at `~/.config/zsh` |
| Homebrew | Install to `/opt/homebrew` if missing |
| `brew bundle` | Install every package/cask from the `Brewfile` |
| `mise` | Trust + install the runtimes declared in `mise/config.toml` |
| Claude wiring | Run `claude/bootstrap.sh` (writes `settings.json`, per-profile `CLAUDE.md`, symlinks agents/skills, makes hooks executable) |
| remote | Switch `origin` from HTTPS to `git@github.com:youssefaltai/dotfiles.git` |

Then **restart your shell** (`exec zsh`) so `ZDOTDIR`, Homebrew, and mise activate.

### 3. Manual steps the installer intentionally does NOT do

These involve secrets or interactive logins — do them by hand.

#### a. SSH keys (auth + commit signing)

Three ed25519 keys, one per identity. Restore from backup **or** regenerate:

```sh
ssh-keygen -t ed25519 -C youssef.altai@icloud.com -f ~/.ssh/id_ed25519_personal
ssh-keygen -t ed25519 -C youssef@goreckit.com     -f ~/.ssh/id_ed25519_reckit
ssh-keygen -t ed25519 -C yaltai@noon.com          -f ~/.ssh/id_ed25519_noon
```

The **public** keys are already committed for signature verification in
[`git/allowed_signers`](git/allowed_signers). If you regenerate keys, update that
file with the new public keys and re-upload each to its GitHub account (as both an
**auth** key and a **signing** key).

#### b. `~/.ssh/config` — per-company host aliases

Not tracked (lives outside `~/.config`). Recreate the blocks (see `system.md` §5):

```sshconfig
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
    AddKeysToAgent yes
    UseKeychain yes

Host github-reckit
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_reckit
    AddKeysToAgent yes
    UseKeychain yes

Host github-noon
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_noon
    AddKeysToAgent yes
    UseKeychain yes
```

Then load each key into the login keychain once so the passphrase is never
re-prompted:

```sh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_personal
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_reckit
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_noon
```

#### c. `gh` auth (per profile)

```sh
gh auth login                                   # personal → ~/.config/gh
GH_CONFIG_DIR=~/.config/gh-reckit gh auth login # reckit
GH_CONFIG_DIR=~/.config/gh-noon   gh auth login # noon
```

#### d. Claude Code login

Two Claude subscriptions, two profiles: the personal Max x20 (default,
`~/.claude`) and the Reckit-provided one (`~/.claude-reckit`). Both are normal,
re-authenticatable accounts — sign in normally on a new machine.

`guard.sh` still blocks `claude auth login`/`logout` and the Keychain item, so
those commands fail until you run them outside Claude Code. That is a guardrail
against an agent doing it by accident, not a sign that recovery is impossible.
(Historical note: an earlier, genuinely irreplaceable account is gone; any doc
still warning about it is stale.)

#### e. Flutter SDKs (only if doing reckit mobile work)

Managed by `fvm` (installed via the Brewfile's `leoafarias/fvm` tap), not mise:

```sh
fvm install <version>   # per project, as needed
```

#### f. API keys (Context7 docs, Exa search)

Read by `.zshrc` from `~/.local/share/machine/keys/{context7_key,exa_key}` —
deliberately outside this repo so they are never committed. Recreate the files
with keys from [context7.com](https://context7.com) and
[exa.ai](https://exa.ai); the shell tolerates their absence.

### 4. Contexts

Do **not** create work directories or identity wiring by hand — it is generated:

```sh
ctx check          # what is missing
ctx sync --apply   # create it
```

[`contexts.toml`](contexts.toml) is the single definition of every context;
[`bin/ctx`](bin/ctx) generates the git identities, `includeIf` blocks, SSH host
aliases and per-context `mise.toml` from it. See `system.md` §5.

Two steps per context stay manual because they need a human: uploading the SSH
key to GitHub, and `GH_CONFIG_DIR=~/.config/gh-<ctx> gh auth login`. `ctx check`
lists exactly which are outstanding.

---

## Day-to-day maintenance

- **One sweep of everything:** `machine-check` — context drift, the guard's test
  suite, unsaved work across every repo, dotfiles status, keystores, outdated
  packages, disk. Exits non-zero when something needs attention. Runs weekly via
  a launchd agent, logging to `~/.local/state/machine-check.log`.
- **Durable context** about jobs, clients, people and finances lives in
  `~/work/personal/life` (private repo), not in this one.

- **After installing/removing a brew package:**
  `brew bundle dump --file=~/.config/Brewfile --force`, then commit.
- **Update everything:** `brew update && brew upgrade && brew cleanup`, regenerate
  the Brewfile, commit.
- **Track a new config:** add `!name/` and `!name/**` to
  [`.gitignore`](.gitignore) (allowlist model), then commit.
- Keep `~/.config` committed and pushed after meaningful changes. Commits use the
  personal identity and are SSH-signed. Review `git status` before committing;
  **never stage secrets.**
