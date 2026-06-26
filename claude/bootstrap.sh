#!/usr/bin/env bash
# Bootstrap the per-profile Claude Code wiring on a fresh machine.
# Prereq: the dotfiles repo is cloned so ~/.config/claude/{system.md,
# hooks/guard.sh, statusline.sh, agents/} exist.
# Run ONCE before relying on the guard (it writes settings.json, which the live
# guard's rule 7 would otherwise block).
set -e
H="$HOME"
P="$H/.claude"; R="$H/.claude-reckit"

mkdir -p "$P/agents" "$R/agents"
chmod +x "$H/.config/claude/hooks/guard.sh" "$H/.config/claude/statusline.sh"

cat > "$P/CLAUDE.md" <<'EOF'
@~/.config/claude/system.md

# Profile: PERSONAL
- Active account: **youssefaltai** (`youssef.altai@icloud.com`). This is the default
  profile (`~/.claude`). Personal projects live under `~/work/personal/`.
- The "irreplaceable account" rules in system.md §0 apply to THIS profile above all.
EOF
cat > "$R/CLAUDE.md" <<'EOF'
@~/.config/claude/system.md

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
    "allow": ["Read","Glob","Grep","WebFetch","WebSearch","Bash(git *)","Bash(gh *)","Bash(brew *)","Bash(mise *)","Bash(ls *)","Bash(eza *)","Bash(cat *)","Bash(bat *)","Bash(rg *)","Bash(fd *)","Bash(fzf *)","Bash(jq *)","Bash(zoxide *)","Bash(delta *)","Bash(lazygit *)","Bash(echo *)","Bash(pwd)","Bash(which *)","Bash(head *)","Bash(tail *)","Bash(wc *)","Bash(grep *)","Bash(find *)","Bash(mkdir *)","Bash(touch *)","Bash(cp *)","Bash(node *)","Bash(npm *)","Bash(npx *)","Bash(pnpm *)","Bash(python3 *)","Bash(uv *)","Bash(make *)","Edit","Write"],
    "deny": ["Read(~/.ssh/**)","Read(~/.claude/.credentials*)","Read(~/.claude-reckit/.credentials*)","Read(~/.config/gh/**)","Read(~/.config/gh-reckit/**)","Read(**/.env)","Read(**/.env.*)","Edit(~/.ssh/**)","Write(~/.ssh/**)","Edit(~/.config/claude/hooks/**)","Write(~/.config/claude/hooks/**)","Edit(~/.claude/settings.json)","Write(~/.claude/settings.json)","Edit(~/.claude-reckit/settings.json)","Write(~/.claude-reckit/settings.json)","Bash(claude auth:*)","Bash(security:*)"]
  },
  "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "$H/.config/claude/hooks/guard.sh", "timeout": 5 } ] } ] },
  "statusLine": { "type": "command", "command": "$H/.config/claude/statusline.sh", "padding": 0 }
}
EOF
}
gen_settings ',"editorMode":"vim"'                    > "$P/settings.json"
gen_settings ',"tui":"fullscreen","editorMode":"vim"' > "$R/settings.json"

ln -sf "$H/.config/claude/agents/system-maintainer.md" "$P/agents/system-maintainer.md"
ln -sf "$H/.config/claude/agents/system-maintainer.md" "$R/agents/system-maintainer.md"

echo "Bootstrapped Claude wiring for personal + reckit profiles."
