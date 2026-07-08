// OpenCode guard plugin — port of the Claude Code PreToolUse guard
// (~/.config/claude/hooks/guard.sh) for the OpenCode era.
//
// Inspects every `bash` tool call and BLOCKS (by throwing) a small, tight set
// of irreversible/dangerous operations. File-path protection (secrets, config,
// auth.json) is handled declaratively by `permission` rules in opencode.jsonc;
// this plugin only inspects Bash command strings, closing the shell path
// around those rules.
//
// Loaded automatically from ~/.config/opencode/plugins/ at startup (no config
// entry needed). This file is edit-protected via permission rules — the user
// maintains it manually. Other plugins in this directory and the rest of the
// OpenCode config are agent-editable (policy change 2026-07-05).

import type { Plugin } from "@opencode-ai/plugin"

const RULES: Array<{ pattern: RegExp; reason: string }> = [
  // 1. Claude auth — personal login is irreplaceable (active until ~2026-07-10),
  //    and the reckit (company) profile must keep working indefinitely.
  {
    pattern: /claude\s+auth\s+(login|logout)/i,
    reason: "claude auth login/logout is forbidden (irreplaceable/company accounts).",
  },
  // 2. OAuth-token env that can wipe a Claude Keychain login on exit.
  {
    pattern: /CLAUDE_CODE_OAUTH_TOKEN/,
    reason: "Setting CLAUDE_CODE_OAUTH_TOKEN can destroy a Claude Keychain login.",
  },
  // 3. Keychain operations on Claude credentials (any profile).
  {
    pattern: /security\s+.*(delete-generic-password|claude code-credentials)/i,
    reason: "Keychain operations on Claude credentials are forbidden.",
  },
  // 4. Removing a Claude profile dir or OpenCode's config/data dirs.
  {
    pattern: /rm\s+.*(~|\$HOME)\/\.claude(-reckit)?\/?(\s|$|["'])/i,
    reason: "Removing a Claude profile directory is forbidden.",
  },
  {
    pattern: /rm\s+.*(~|\$HOME)\/(\.config\/opencode|\.local\/share\/opencode)\/?(\s|$|["'])/i,
    reason: "Removing OpenCode's config/data directories is forbidden (auth, db, guard).",
  },
  // 5. Catastrophic recursive deletes of home/root.
  {
    pattern: /rm\s+(-[A-Za-z]+\s+)*(\/|~|~\/|\$HOME|\$HOME\/|\/\*)(\s|$)/,
    reason: "Catastrophic rm targeting home/root is forbidden.",
  },
  // 6. Protect the guardrail core from shell rewrites: this file, OpenCode's
  //    auth.json, and Claude's settings/hooks (the Edit tool is blocked for
  //    these by permission rules; this closes the Bash path). Other plugins
  //    and opencode.jsonc are deliberately NOT listed — agents may edit them.
  //    The redirect/verb must lead directly to the guarded path within the
  //    same shell segment, so unrelated redirects (e.g. `2>/dev/null`) in a
  //    command that merely mentions a guarded path don't false-positive.
  {
    pattern:
      /(>>?\s*|(^|\s)(tee|cp|mv|ln)\s[^;&|\n]*)\S*(\.config\/opencode\/plugins\/guard\.ts|\.local\/share\/opencode\/auth\.json|\.claude(-reckit)?\/settings\.json|\.config\/claude\/(hooks\/|statusline\.sh))/i,
    reason:
      "Modifying OpenCode/Claude guardrail core files via the shell is blocked (edit manually if you must).",
  },
]

export const GuardPlugin: Plugin = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") return
      const command = output?.args?.command
      if (typeof command !== "string" || command.length === 0) return
      for (const { pattern, reason } of RULES) {
        if (pattern.test(command)) {
          throw new Error(`BLOCKED by guard plugin: ${reason}`)
        }
      }
    },
  }
}
