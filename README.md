# dotfiles — `~/.config`

Private, XDG-based configuration for Youssef's macOS machine. This repo **is**
`~/.config`: it is cloned directly into that path, and `$HOME` stays clean.

The operating philosophy — containment, where things go, git identities, the
`mise` per-project model, and the safety rules — lives in
[`opencode/AGENTS.md`](opencode/AGENTS.md), the manual for OpenCode (the
primary agent and system maintainer on this machine). Read that first; this
README only covers **reproducing the setup on a fresh Mac**.

---

## Reproduce on a new Mac

`install.sh` automates the mechanical, idempotent parts. A few steps are
**manual by design** — SSH private keys are secrets that are (correctly) not
in this repo.

### 0. Prerequisites (manual, once)

```sh
# Xcode Command Line Tools — provides git, needed before anything else
xcode-select --install
```



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

| remote | Switch `origin` from HTTPS to `git@github.com:youssefaltai/dotfiles.git` |

Then **restart your shell** (`exec zsh`) so `ZDOTDIR`, Homebrew, and mise activate.

### 3. Manual steps the installer intentionally does NOT do

These involve secrets — do them by hand.

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

#### d. Flutter SDKs (only if doing reckit mobile work)

Managed by `fvm` (installed via the Brewfile's `leoafarias/fvm` tap), not mise:

```sh
fvm install <version>   # per project, as needed
```

#### e. OpenCode auth (OpenRouter)

The binary comes from the Brewfile; its config (`opencode/`) is this repo. Only
the API key is manual: run `opencode`, then `/connect` → **OpenRouter** → paste
a key from [openrouter.ai/settings/keys](https://openrouter.ai/settings/keys).
Stored in `~/.local/share/opencode/auth.json` (never tracked here).

### 4. Directory layout to recreate

```sh
mkdir -p ~/work/personal ~/work/reckit ~/work/noon
```

Git identity switches automatically by directory via the `includeIf` blocks in
[`git/config`](git/config).

---

## Day-to-day maintenance

- **After installing/removing a brew package:**
  `brew bundle dump --file=~/.config/Brewfile --force`, then commit.
- **Update everything:** `brew update && brew upgrade && brew cleanup`, regenerate
  the Brewfile, commit.
- **Track a new config:** add `!name/` and `!name/**` to
  [`.gitignore`](.gitignore) (allowlist model), then commit.
- Keep `~/.config` committed and pushed after meaningful changes. Commits use the
  personal identity and are SSH-signed. Review `git status` before committing;
  **never stage secrets.**
