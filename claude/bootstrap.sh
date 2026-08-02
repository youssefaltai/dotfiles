#!/usr/bin/env bash
# Bootstrap the per-profile Claude Code wiring on a fresh machine.
# Prereq: the dotfiles repo is cloned so ~/.config/claude/{system.md,
# hooks/guard.sh, statusline.sh, agents/, skills/} exist.
# Run ONCE before relying on the guard (it writes settings.json, which the live
# guard's rule 6 would otherwise block).
set -e
H="$HOME"
P="$H/.claude"; R="$H/.claude-reckit"

mkdir -p "$P/agents" "$R/agents" "$P/skills" "$R/skills"
chmod +x "$H/.config/claude/hooks/guard.sh" "$H/.config/claude/statusline.sh"

# working-rules.md governs how to reason and report; it lives in the dotfiles so
# it is reproducible, and is symlinked into each profile because CLAUDE.md's @
# includes resolve per-profile.
ln -sf "$H/.config/claude/working-rules.md" "$P/working-rules.md"
ln -sf "$H/.config/claude/working-rules.md" "$R/working-rules.md"

cat > "$P/CLAUDE.md" <<'EOF'
@~/.config/claude/system.md
@~/.claude/working-rules.md

# Profile: PERSONAL
- Active account: **youssefaltai** (`youssef.altai@icloud.com`), Max x20. This is
  the default profile (`~/.claude`). Personal projects live under `~/work/personal/`.
- This subscription also carries noon, dolab-marcom and freelance work — the
  statusline shows `context·profile` so that is never invisible.

# Life context
Durable context about work, clients, people, finances, goals and routines lives
in `~/work/personal/life` (private repo). Read the relevant file there before
asking about something that ought to be already known — contexts are in
`contexts/<name>.md`. Keep it updated when something durable changes.
EOF
cat > "$R/CLAUDE.md" <<'EOF'
@~/.config/claude/system.md
@~/.claude-reckit/working-rules.md

# Profile: RECKIT (work)
- Active account: **youssef-goreckit** (`youssef@goreckit.com`), config dir
  `~/.claude-reckit`. Work lives under `~/work/reckit/`.
- Use the reckit git identity (automatic there), SSH alias `github-reckit`, and
  `GH_CONFIG_DIR=~/.config/gh-reckit` for `gh`.
EOF

gen_settings() {  # \$1 = extra top-level keys (e.g. ',"tui":"fullscreen"')
cat <<EOF
{
  "theme": "dark"${1},
  "permissions": {
    "allow": ["Read","Glob","Grep","WebFetch","WebSearch","Bash(git *)","Bash(gh *)","Bash(brew *)","Bash(mise *)","Bash(ctx *)","Bash(ls *)","Bash(eza *)","Bash(cat *)","Bash(bat *)","Bash(rg *)","Bash(fd *)","Bash(fzf *)","Bash(jq *)","Bash(zoxide *)","Bash(delta *)","Bash(lazygit *)","Bash(echo *)","Bash(pwd)","Bash(which *)","Bash(head *)","Bash(tail *)","Bash(wc *)","Bash(grep *)","Bash(find *)","Bash(mkdir *)","Bash(touch *)","Bash(cp *)","Bash(node *)","Bash(npm *)","Bash(npx *)","Bash(pnpm *)","Bash(yarn *)","Bash(python3 *)","Bash(uv *)","Bash(make *)","Bash(flutter *)","Bash(dart *)","Bash(fvm *)","Bash(gitleaks *)","Edit","Write"],
    "deny": ["Read(~/.ssh/**)","Read(~/.claude/.credentials*)","Read(~/.claude-reckit/.credentials*)","Read(~/.config/gh/**)","Read(~/.config/gh-reckit/**)","Read(~/.config/gh-noon/**)","Read(~/.config/gh-dolab/**)","Read(~/.local/share/machine/**)","Read(**/.env)","Read(**/.env.*)","Read(**/*.jks)","Read(**/*.keystore)","Read(**/*.p12)","Read(**/*.pem)","Read(**/*.mobileprovision)","Edit(~/.ssh/**)","Edit(~/.config/claude/hooks/**)","Edit(~/.claude/settings.json)","Edit(~/.claude-reckit/settings.json)","Bash(claude auth:*)","Bash(security:*)"]
  },
  "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "$H/.config/claude/hooks/guard.sh", "timeout": 5 } ] } ] },
  "statusLine": { "type": "command", "command": "$H/.config/claude/statusline.sh", "padding": 0 }
}
EOF
}
# Only written on a fresh bootstrap — settings.json is deny-listed for agent
# edits on purpose, and an existing one may carry hand-tuned keys (effortLevel,
# autoUpdatesChannel, theme). Delete the file first if you want it regenerated.
[ -f "$P/settings.json" ] || gen_settings ',"editorMode":"vim","tui":"fullscreen","effortLevel":"high"' > "$P/settings.json"
[ -f "$R/settings.json" ] || gen_settings ',"editorMode":"vim","tui":"fullscreen","effortLevel":"high"' > "$R/settings.json"

# Agents, skills and commands live once in the dotfiles and are symlinked into
# every profile. Looping over whatever exists (rather than naming each one)
# means adding a new agent or command needs no edit here — drop the file in
# ~/.config/claude/{agents,commands}/ or a dir in skills/ and re-run.
SRC="$H/.config/claude"
for prof in "$P" "$R"; do
  mkdir -p "$prof/agents" "$prof/skills" "$prof/commands"
  for f in "$SRC"/agents/*.md;   do [ -e "$f" ] && ln -sf  "$f" "$prof/agents/$(basename "$f")"; done
  for f in "$SRC"/commands/*.md; do [ -e "$f" ] && ln -sf  "$f" "$prof/commands/$(basename "$f")"; done
  for d in "$SRC"/skills/*/;     do [ -d "$d" ] && ln -sfn "${d%/}" "$prof/skills/$(basename "$d")"; done
done

echo "Bootstrapped Claude wiring for personal + reckit profiles."
echo "  agents:   $(ls -1 "$SRC"/agents/*.md 2>/dev/null | wc -l | tr -d ' ')"
echo "  commands: $(ls -1 "$SRC"/commands/*.md 2>/dev/null | wc -l | tr -d ' ')"
echo "  skills:   $(ls -1d "$SRC"/skills/*/ 2>/dev/null | wc -l | tr -d ' ')"
