#!/usr/bin/env bash
# Test harness for guard.sh. Feeds it PreToolUse JSON and asserts allow/deny.
# A guard is only trustworthy if it blocks the dangerous cases AND lets the
# ordinary ones through — a guard that blocks everything is as useless as one
# that blocks nothing.

GUARD="${1:?usage: test-guard.sh /path/to/guard.sh}"
STRICT="$HOME/work/noon/bappzaar"      # employer tree
RELAX="$HOME/work/personal/joe"        # personal tree

pass=0; fail=0

check() { # check <expect: DENY|ALLOW> <cwd> <command>
  local expect="$1" cwd="$2" cmd="$3" out rc verdict
  out=$(jq -nc --arg c "$cmd" --arg d "$cwd" \
        '{tool_name:"Bash", tool_input:{command:$c}, cwd:$d}' | bash "$GUARD" 2>&1)
  rc=$?
  [ $rc -eq 2 ] && verdict="DENY" || verdict="ALLOW"
  if [ "$verdict" = "$expect" ]; then
    pass=$((pass+1))
    printf '  \033[32m✓\033[0m %-5s %s\n' "$expect" "$cmd"
  else
    fail=$((fail+1))
    printf '  \033[31m✗\033[0m expected %-5s got %-5s : %s\n' "$expect" "$verdict" "$cmd"
    [ -n "$out" ] && printf '      %s\n' "$out"
  fi
}

echo "=== MUST BLOCK (destructive) ==="
check DENY  "$RELAX"  'git reset --hard HEAD~1'
check DENY  "$RELAX"  'git clean -fd'
check DENY  "$RELAX"  'git checkout -- .'
check DENY  "$RELAX"  'git branch -D feature/old'
check DENY  "$RELAX"  'git filter-branch --tree-filter "rm -f x" HEAD'
check DENY  "$RELAX"  'rm -rf ~'
check DENY  "$RELAX"  'rm -rf /'
check DENY  "$RELAX"  'rm -rf src/'
check DENY  "$RELAX"  'npm publish'
check DENY  "$RELAX"  'gh repo delete youssefaltai/foo'
check DENY  "$RELAX"  'claude auth logout'
check DENY  "$RELAX"  'cat .env'
check DENY  "$RELAX"  'cat ~/.ssh/id_ed25519_personal'
check DENY  "$RELAX"  'cat ~/.ssh/id_ed25519_dolab'
check DENY  "$RELAX"  'cp ~/.ssh/id_ed25519_reckit /tmp/x'
check ALLOW "$RELAX"  'cat ~/.ssh/id_ed25519_reckit.pub'
check ALLOW "$RELAX"  'cat .env.example'
check DENY  "$RELAX"  'git add .env.production'
check DENY  "$RELAX"  'supabase db reset'
check DENY  "$RELAX"  'git push --force origin main'

echo
echo "=== STRICT context (employer/client) blocks more ==="
check DENY  "$STRICT" 'git push --force-with-lease origin feature/x'
check DENY  "$STRICT" 'git push origin main'
check DENY  "$STRICT" 'git push origin develop'
check DENY  "$STRICT" 'git push upstream HEAD:main'
check ALLOW "$STRICT" 'git push origin feature/my-branch'
check ALLOW "$STRICT" 'git push origin fix/mainline-typo'
check ALLOW "$STRICT" 'git push'
check ALLOW "$RELAX"  'git push origin main'

echo
echo "=== RELAXED context (personal) allows lease-guarded force ==="
check ALLOW "$RELAX"  'git push --force-with-lease origin feature/x'

echo
echo "=== MUST ALLOW (ordinary work — false positives are the real risk) ==="
check ALLOW "$RELAX"  'git status'
check ALLOW "$RELAX"  'git log --oneline -20'
check ALLOW "$RELAX"  'git commit -m "fix: handle empty state"'
check ALLOW "$RELAX"  'git add -A'
check ALLOW "$RELAX"  'git stash -u'
check ALLOW "$RELAX"  'git diff HEAD'
check ALLOW "$RELAX"  'git rebase main'
check ALLOW "$RELAX"  'npm install'
check ALLOW "$RELAX"  'pnpm build'
check ALLOW "$RELAX"  'rm -rf node_modules'
check ALLOW "$RELAX"  'rm -rf .next dist'
check ALLOW "$RELAX"  'rm -rf /tmp/scratch-build'
check ALLOW "$RELAX"  'rm src/old-file.ts'
check ALLOW "$RELAX"  'cat README.md'
check ALLOW "$RELAX"  'bat src/index.ts'
check ALLOW "$RELAX"  'ls -la'
check ALLOW "$RELAX"  'rg "TODO" src/'
check ALLOW "$RELAX"  'flutter test'
check ALLOW "$RELAX"  'yarn test --watchAll=false'
check ALLOW "$RELAX"  'gh pr create --title "x" --body "y"'
check ALLOW "$RELAX"  'gh pr list'
check ALLOW "$RELAX"  'vercel deploy'
check ALLOW "$RELAX"  'docker compose up -d'
check ALLOW "$RELAX"  'echo "check .env.example is committed"'

echo
printf '\n  %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
