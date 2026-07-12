import type { Plugin } from "@opencode-ai/plugin"

const RULES: Array<{ pattern: RegExp; reason: string }> = [
  // 1. Catastrophic recursive deletes of home/root.
  {
    pattern: /rm\s+(-[A-Za-z]+\s+)*(\/|~|~\/|\$HOME|\$HOME\/|\/\*)(\s|$)/,
    reason: "Catastrophic rm targeting home/root is forbidden.",
  },
  // 2. Protect guardrail core files from shell rewrites (Edit tool is blocked
  //    by permission rules; this closes the Bash path).
  {
    pattern:
      /(>>?\s*|(^|\s)(tee|cp|mv|ln)\s[^;&|\n]*)\S*(\.config\/opencode\/plugins\/guard\.ts|\.local\/share\/opencode\/auth\.json)/i,
    reason:
      "Modifying guardrail core files via shell is blocked (edit manually if you must).",
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
