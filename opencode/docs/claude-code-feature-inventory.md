# Claude Code Feature Inventory — Mid-2026 Edition

**Purpose:** Exhaustive checklist of Claude Code (CLI) features as of mid-2026, grouped by category. Each entry includes the feature name and a 1–2 sentence behavioral description sufficient for replication.

---

## 1. INTERACTION MODEL

### Slash Commands (Built-In)
- **`/help`**: Display help menu showing available commands and skills.
- **`/compact [instructions]`**: Summarize conversation history to free context window, optionally focused on specified instructions.
- **`/clear`**: Start fresh conversation with empty context; previous conversation remains resumable.
- **`/context`**: Show breakdown of what is consuming context window space.
- **`/memory`**: Browse and edit CLAUDE.md files, auto memory, and toggle auto memory on/off.
- **`/init`**: Generate starter CLAUDE.md with discovered project conventions and build commands.
- **`/model`**: Switch Claude model mid-session without clearing prompt.
- **`/effort`**: Adjust reasoning effort level (low/medium/high/xhigh/max) mid-session.
- **`/plan`**: Enter plan mode to research and propose changes without making edits.
- **`/rename`**: Set or change session name for display and resumption by name.
- **`/resume [name]`**: Switch to different session from inside active session; open session picker if no name given.
- **`/cd [path]`**: Change working directory mid-session and reload CLAUDE.md.
- **`/add-dir [paths]`**: Grant Claude access to additional directories outside working directory.
- **`/permissions`**: View, approve, or deny recent tool uses and configure permission rules interactively.
- **`/config`**: Interactive settings menu to toggle features (vim mode, statusline, auto-memory, etc.) and change output style.
- **`/branch [name]`**: Fork current conversation to try alternative approach; original remains intact.
- **`/export [filename]`**: Save conversation as plain-text file or copy to clipboard; supports filtering by message type.
- **`/tasks`**: Monitor running background Bash commands and subagents.
- **`/recap`**: Generate one-line summary of session progress on demand.
- **`/btw [question]`**: Ask side question without adding to conversation history; runs in overlay and reuses parent cache.
- **`/mcp`**: Configure Model Context Protocol servers (add/list/remove/authenticate).
- **`/mcp login <name>`**: Run OAuth flow for MCP server that requires authentication.
- **`/mcp logout <name>`**: Clear stored OAuth credentials for MCP server.
- **`/hooks`**: View configured hooks and their matchers; disable/remove individual hooks.
- **`/theme`**: Switch between light/dark themes mid-session.
- **`/editor`**: Toggle Vim keybindings for input mode.
- **`/terminal-setup`**: Install Shift+Enter multiline input binding for supported terminal emulators.
- **`/feedback`**: Report bugs, request features, or send general feedback to Anthropic.
- **`/doctor`**: Run diagnostic checks on Claude Code installation and configuration.
- **`/terminal-config`**: Configure terminal behavior (theme, notifications, tmux, etc.).
- **`/statusline`**: Set up custom status line display via command or JSON configuration.
- **`/plugin`**: Manage plugins (install/uninstall/list/enable/disable/update).
- **`/plugin marketplace`**: Add, remove, or list plugin marketplaces.
- **`/advisor`**: Enable/disable advisor tool (server-side model for approval gates).
- **`/cost`**: Display token usage and cost breakdown for current session.
- **`/usage`**: Show detailed usage metrics by model and by tool.
- **`/voice [tap|hold]`**: Enable voice dictation and toggle between tap-to-send and hold-to-record modes.
- **`/web-setup`**: Configure Claude Code on the web (cloud sessions) from CLI.
- **`/schedule`**: Create/manage/list scheduled cloud agent tasks with cron triggers.
- **`/goal [condition]`**: Set goal to keep session running until condition is met (e.g., "all tests pass").
- **`/loop [interval]`**: Run prompt or command on recurring interval; omit interval for auto-pacing.
- **`/ultraplan`**: Launch plan in browser for visual review and revision before execution.

### Keyboard Shortcuts & Interactions

#### General Controls
- **`Ctrl+C`**: Interrupt Claude's response mid-turn, or clear input twice to exit.
- **`Ctrl+D`**: Exit Claude Code session (EOF signal).
- **`Ctrl+G` or `Ctrl+X Ctrl+E`**: Open current prompt or last response in external `$EDITOR`; toggle "Show last response in external editor" in `/config` to prepend previous reply as context.
- **`Ctrl+L`**: Redraw terminal screen if display is corrupted.
- **`Ctrl+O`**: Toggle transcript viewer showing full tool invocations and expanded MCP calls.
- **`Ctrl+R`**: Reverse-search command history interactively; press `Ctrl+R` again to cycle matches; `Ctrl+S` to change scope (session/project/all projects).
- **`Ctrl+V` / `Cmd+V` / `Alt+V`**: Paste image from clipboard as `[Image #N]` chip.
- **`Ctrl+B`**: Background running Bash commands and agents (press twice in tmux).
- **`Ctrl+T`**: Toggle Claude's task checklist view.
- **`Ctrl+X Ctrl+K`**: Stop all background subagents; press twice within 3 seconds to confirm.
- **`Shift+Tab` or `Alt+M`**: Cycle permission modes (default → acceptEdits → plan; auto/bypassPermissions if enabled).
- **`Option+P` (macOS) / `Alt+P` (Windows/Linux)**: Switch model without clearing prompt.
- **`Option+T` (macOS) / `Alt+T` (Windows/Linux)**: Toggle extended thinking on/off.
- **`Option+O` (macOS) / `Alt+O` (Windows/Linux)**: Toggle fast mode on/off.
- **`Esc`**: Interrupt Claude or close open dialog; does not rewind.
- **`Esc Esc`**: Clear prompt draft (saving to history) or open rewind menu if input is empty.

#### Text Editing
- **`Ctrl+A` / `Ctrl+E`**: Move cursor to start/end of current line.
- **`Ctrl+K`**: Delete to end of line (stored for pasting).
- **`Ctrl+U`**: Delete from cursor to line start (stored for pasting; repeat across lines in multiline).
- **`Ctrl+W`**: Delete previous word (stored for pasting).
- **`Ctrl+Y`**: Paste deleted text; `Alt+Y` after `Ctrl+Y` cycles paste history.
- **`Alt+B` / `Alt+F`**: Move cursor back/forward one word (requires Option as Meta on macOS).

#### Multiline Input
- **`\` + `Enter`**: Escape sequence for newline (works all terminals).
- **`Option+Enter` (macOS) / `Alt+Enter` (Windows/Linux)**: Native multiline with Option as Meta.
- **`Shift+Enter`**: Native multiline in iTerm2, WezTerm, Ghostty, Kitty, Warp, Apple Terminal, Windows Terminal.
- **`Ctrl+J`**: Control sequence newline (works without configuration).
- **Paste directly**: Large code blocks auto-enable multiline mode.

#### Transcript Viewer (Ctrl+O toggle; fullscreen mode adds more)
- **`Ctrl+E`**: Toggle "show all" to expand collapsed tool invocations.
- **`[`**: Write full conversation to terminal scrollback (for native search with Cmd+F, tmux copy mode).
- **`v`**: Write conversation to temp file and open in `$EDITOR`.
- **`{` / `}`**: Jump to previous/next user prompt (vim paragraph motion).
- **`?`**: Show keyboard shortcut panel (fullscreen only).
- **`q` / `Ctrl+C` / `Esc`**: Exit transcript viewer.

#### Dialog Navigation
- **`Left/Right arrows`**: Cycle through tabs in permission dialogs and menus.
- **`Up/Down arrows` / `Ctrl+P` / `Ctrl+N`**: Move cursor or navigate command history (cursor moves within multiline first, then steps history).
- **`Space` or `Enter`**: Accept highlighted option in dialogs.

#### Vim Mode (Enable via `/config`)
- **Mode switching**: `Esc` (NORMAL), `i`/`I`/`a`/`A` (INSERT), `o`/`O` (open line), `v`/`V` (VISUAL).
- **Navigation (NORMAL)**: `h/j/k/l` (move), `w/e/b` (word), `0/$` (line), `^` (first non-blank), `gg/G` (top/bottom), `f{char}/F{char}/t{char}/T{char}` (jump to char).
- **Editing (NORMAL)**: `x/dd/D` (delete), `dw/de/db` (delete word), `cc/C/cw` (change), `yy/Y/yw` (yank), `p/P` (paste), `>>/<<` (indent), `J` (join), `u` (undo), `.` (repeat).
- **Text objects**: `iw/aw` (word), `i"/a"` (quotes), `i(/a(` (parens), `i[/a[` (brackets), `i{/a{` (braces).
- **Visual mode**: `v` (char-wise), `V` (line-wise); operators act on selection; `o` swaps cursor/anchor.
- **Search**: `/` opens reverse history search (same as `Ctrl+R`).

### Quick Input Modes
- **`/` at start**: Show command/skill menu; type letters to filter.
- **`!` at start (shell mode)**: Run shell command directly without Claude interpretation; output added to context; Claude responds automatically; supports history autocomplete and live file path autocomplete (Shift+Enter or Tab to accept file).
- **`@` in prompt**: File path autocomplete; trigger by typing path with `/` or `~/`.
- **`#`**: Shortcut to reference memory (CLAUDE.md or auto memory content).

### Permission Modes
- **`default` (Manual mode)**: Read-only without prompts; all writes/commands require approval.
- **`acceptEdits`**: Auto-approve file edits and common filesystem commands (`mkdir`, `touch`, `mv`, `cp`, `rm`, `rmdir`); other Bash and network still prompt.
- **`plan`**: Read-only research mode; propose changes in plan, then approve to switch to another mode for execution.
- **`auto` (if enabled)**: Classifier reviews actions; blocks deployments, mass deletion, force-push, `git reset --hard`, hostile content; allows local edits and trusted remotes; falls back to manual on repeated blocks (3 consecutive or 20 total).
- **`dontAsk`**: Only pre-approved tools execute (from `permissions.allow` rules); everything else denied; non-interactive for CI.
- **`bypassPermissions`**: All actions run immediately without prompts (except explicit `ask` rules and root safety check); only for isolated containers/VMs.

Cycle with `Shift+Tab` in CLI, or switch at startup with `--permission-mode <mode>`, or set `defaultMode` in settings.

### Planning & Approval Flow
- **Plan mode entry**: Press `Shift+Tab` from manual, or prefix prompt with `/plan`, or start with `--permission-mode plan`.
- **Plan review**: Claude presents plan and asks how to proceed: approve + auto mode, approve + acceptEdits, approve + manual, keep planning, or refine with Ultraplan.
- **Plan editing**: Press `Ctrl+G` to open plan in external editor and modify before approval.
- **Context cleanup**: Enable `showClearContextOnPlanAccept` to offer clearing planning context before each approve option.

### Extended Thinking & Reasoning
- **Toggle thinking**: Press `Option+T` (macOS) / `Alt+T` (Windows/Linux) to enable/disable (no effect on Fable 5 which always thinks).
- **Thinking trigger keywords**: Certain prompts like "debug," "complex," "design" auto-enable thinking on compatible models.
- **Thinking budget**: Effort level controls thinking budget (low → xhigh increases budget); `max` effort maximizes.
- **Ultrathink keywords**: Certain keywords ("deep", "analysis", "investigation") trigger maximum thinking budget automatically.

### Interrupt & Rewind
- **Single Esc**: Stop Claude's response mid-turn; work done so far is kept and rewindable.
- **Double Esc (Esc Esc)**: Open rewind menu when input is empty; select checkpoint to restore code and/or conversation to earlier point.
- **Checkpoint tracking**: Automatic snapshots after each turn; Manual and undo via keybinding available (requires file checkpointing enabled).

### Message Queueing & Async Features
- **Background subagents**: Run subagents in background; continue main session; `/tasks` shows running tasks.
- **Background Bash**: Press `Ctrl+B` to background long-running commands; they continue and output logged; retrieve output with Read tool.
- **Foreground/background toggle**: Claude can spawn subagents in foreground (wait for result before continuing) or background (continue immediately).

### Tab Completion & Autocomplete
- **File paths**: Type `@` and partial path to see matching files/directories; `Tab` accepts.
- **Shell commands**: `!` mode supports history-based autocomplete of previous `!` commands.
- **Prompt suggestions**: Grayed suggestions appear after first turn based on git history and conversation; `Tab`/`Right` to accept, type to dismiss.

---

## 2. CONFIG SURFACE

### Settings Hierarchy & Scopes
Configuration is layered with precedence (high to low):
1. **Managed settings** (server/MDM): organization policy, enforced.
2. **CLI flags**: one-off overrides.
3. **Local settings** (`.claude/settings.local.json`): project-specific, not committed.
4. **Project settings** (`.claude/settings.json`): team-shared, in version control.
5. **User settings** (`~/.claude/settings.json`): personal defaults.

When edits take effect: Most immediately; system prompt changes need `/clear` or new session.

### Core Settings Keys

| Key | Purpose | Example |
|-----|---------|---------|
| `model` | Override default model | `"claude-sonnet-5"` |
| `advisorModel` | Server-side model for approval gates | `"opus"` |
| `effortLevel` | Persist effort (low/medium/high/xhigh/max) | `"xhigh"` |
| `language` | Response language preference | `"japanese"` |
| `outputStyle` | System prompt style | `"Explanatory"` |
| `availableModels` | Restrict model choices | `["sonnet", "haiku"]` |
| `enforceAvailableModels` | Extend allowlist to Default model | `true` |
| `fallbackModel` | Fallback if primary unavailable | `["sonnet-5", "haiku"]` |
| `modelOverrides` | Map Anthropic IDs to provider IDs (Bedrock/Foundry) | `{"claude-opus-4-6": "arn:aws:bedrock:..."}` |
| `alwaysThinkingEnabled` | Enable extended thinking by default | `true` |

### Permission Settings
| Key | Purpose |
|-----|---------|
| `permissions.allow` | Pre-approve tools (array of tool names and rules) |
| `permissions.deny` | Block tools (array of tool names and rules) |
| `permissions.ask` | Force prompt (array of tool names) |
| `permissions.defaultMode` | Starting permission mode | `"plan"`, `"acceptEdits"`, `"auto"` |
| `permissions.disableAutoMode` | Disable auto mode | `"disable"` |
| `permissions.disableBypassPermissionsMode` | Disable bypass permissions | `"disable"` |

Permission rule syntax: `"ToolName"` (all uses), `"ToolName(pattern)"` (parametric), `"Bash(git *)"` (prefix match), `"Read(**/*.json)"` (glob).

### Memory & Context
| Key | Purpose |
|-----|---------|
| `autoMemoryEnabled` | Enable auto memory | `true` |
| `autoMemoryDirectory` | Custom memory storage | `"~/my-memory-dir"` |
| `claudeMd` | Managed CLAUDE.md inline | `"Always run make lint"` |
| `claudeMdExcludes` | Skip CLAUDE.md files | `["**/vendor/**/CLAUDE.md"]` |
| `autoCompactEnabled` | Auto-compact at context limit | `true` |
| `fileCheckpointingEnabled` | Enable file snapshots for rewind | `true` |
| `cleanupPeriodDays` | Delete old session files | `30` |

### UI & Display
| Key | Purpose |
|-----|---------|
| `editorMode` | Key binding mode | `"vim"` or `"normal"` |
| `theme` | Color theme | `"light"` or `"dark"` |
| `autoScrollEnabled` | Auto-scroll in fullscreen | `true` |
| `prefersReducedMotion` | Reduce animations | `true` |
| `axScreenReader` | Screen-reader friendly output | `true` |
| `tui` | Terminal UI renderer | `"classic"` or `"tui"` |
| `spinnerTipsEnabled` | Show tips in loading spinners | `true` |

### Notifications & Interaction
| Key | Purpose |
|-----|---------|
| `preferredNotifChannel` | Notification delivery | `"auto"`, `"terminal_bell"` |
| `agentPushNotifEnabled` | Push when background task finishes | `true` |
| `inputNeededNotifEnabled` | Push when input required | `true` |
| `awaySummaryEnabled` | Auto recap when returning | `true` |
| `askUserQuestionTimeout` | Auto-continue timeout for questions | `"5m"` |

### Git & Attribution
| Key | Purpose |
|-----|---------|
| `attribution` | Commit/PR attribution customize | `{"commit": "🤖 Generated"}` |
| `includeCoAuthoredBy` | Add `Co-Authored-By` to commits | `true` |
| `includeGitInstructions` | Include git in system prompt | `true` |
| `prUrlTemplate` | Custom PR URL template | `"https://reviews.example.com/{owner}/{repo}/pull/{number}"` |

### Integrations & Tools
| Key | Purpose |
|-----|---------|
| `allowedMcpServers` | MCP server allowlist |  |
| `deniedMcpServers` | MCP server denylist |  |
| `disableClaudeAiConnectors` | Disable claude.ai connectors | `true` |
| `enableAllProjectMcpServers` | Auto-approve project MCP servers | `true` |

### Hooks, Features & Capabilities
| Key | Purpose |
|-----|---------|
| `hooks` | Lifecycle event configurations (command, HTTP, agent, prompt) |  |
| `disableArtifact` | Disable Artifact tool | `true` |
| `disableBundledSkills` | Disable bundled skills | `true` |
| `disableWorkflows` | Disable dynamic workflows | `true` |
| `disableAgentView` | Disable background agents | `true` |
| `disableRemoteControl` | Disable Remote Control | `true` |
| `respondToBashCommands` | Auto-respond to `!` shell output | `true` |

### Authentication & Credentials
| Key | Purpose |
|-----|---------|
| `apiKeyHelper` | Script to generate/rotate API key | `"/bin/gen_key.sh"` |
| `forceLoginMethod` | Restrict login type | `"claudeai"` or `"console"` |
| `forceLoginOrgUUID` | Require specific org UUID | `"xxxxxxxx-xxxx-..."` |

### Environment & Development
| Key | Purpose |
|-----|---------|
| `env` | Session environment variables | `{"FOO": "bar"}` |
| `defaultShell` | Default shell for `!` | `"bash"` or `"powershell"` |

### Updates & Versioning
| Key | Purpose |
|-----|---------|
| `autoUpdatesChannel` | Update channel | `"stable"` or `"latest"` |
| `minimumVersion` | Minimum version floor | `"2.1.100"` |
| `requiredMinimumVersion` | Required minimum (hard block) | `"2.1.100"` |

### Statusline & UI Elements
| Key | Purpose |
|-----|---------|
| `statusLine` | Custom status line config | `{"type": "command", "command": "..."}` |
| `footerLinksRegexes` | Clickable badges in footer | Array of regex patterns |

### Sandbox Settings
| Key | Purpose |
|-----|---------|
| `sandbox.enabled` | Enable bash sandboxing | `true` |
| `sandbox.type` | Sandbox type | `"runtime"`, `"devcontainer"`, `"vm"` |
| `sandbox.networkEnabled` | Allow network in sandbox | `true` |
| `sandbox.denyNetworkTo` | Block specific hosts | `["production.example.com"]` |

### Keybindings Configuration File

**Location**: `~/.claude/keybindings.json`

**Structure**: JSON mapping context × keystroke to action. Contexts: `global`, `chat`, `input`, `autocomplete`, `confirmation`, `permissions`, `transcript`, `history-search`, `tasks`, `theme`, `help`, `tabs`, `attachments`, `footer`, `message-selector`, `diff`, `model-picker`, `select`, `plugin`, `settings`, `doctor`, `voice`, `scroll`.

**Keystroke syntax**: modifiers (`Ctrl`, `Alt`, `Shift`, `Cmd`), letters, special keys (`Enter`, `Tab`, `Escape`, `Space`, `ArrowUp`, etc.), chords (`Ctrl+X Ctrl+K`).

**Available actions**: `app:*`, `history:*`, `chat:*`, `autocomplete:*`, `confirmation:*`, `permissions:*`, `transcript:*`, `history-search:*`, `task:*`, `theme:*`, `help:*`, `tab:*`, `attachment:*`, `footer:*`, `message-selector:*`, `diff:*`, `model-picker:*`, `select:*`, `plugin:*`, `settings:*`, `doctor:*`, `voice:*`, `scroll:*`.

Example:
```json
{
  "global": {
    "Ctrl+Shift+D": "app:toggleDarkMode"
  },
  "input": {
    "Shift+Enter": "input:newline"
  }
}
```

**Reserved shortcuts**: Cannot be rebound (`Ctrl+C`, `Ctrl+D` in most contexts).

---

## 3. HOOKS SYSTEM

### Hook Events & Lifecycle

#### Session-Level Events
| Event | Fires | Can Block | Input | Output |
|-------|-------|-----------|-------|--------|
| **SessionStart** | Session begins/resumes | No | `source`, `model`, `agent_type`, `session_title` | `additionalContext`, `initialUserMessage`, `sessionTitle`, `watchPaths`, `reloadSkills` |
| **Setup** | `--init-only`, `--init`, `--maintenance` | No | matcher: `init` or `maintenance` | Plain text stdout |
| **SessionEnd** | Session terminates | No | matcher: `clear`, `resume`, `logout`, etc. | N/A |

#### Per-Turn Events
| Event | Fires | Can Block | Input | Output |
|-------|-------|-----------|-------|--------|
| **UserPromptSubmit** | Before Claude processes | Yes | User prompt data | `decision: "block"`, `additionalContext` |
| **UserPromptExpansion** | Slash command expands | Yes | matcher: command name | `decision: "block"` |
| **Stop** | Claude finishes turn | Yes | Last assistant message | `decision: "block"`, `additionalContext` |
| **StopFailure** | API error ends turn | No | matcher: error type | N/A |

#### Tool-Use Events
| Event | Fires | Can Block | Input | Output |
|-------|-------|-----------|-------|--------|
| **PreToolUse** | Before tool executes | Yes | `tool_name`, `tool_input` | `permissionDecision`, `updatedInput` |
| **PostToolUse** | Tool succeeds | No | `tool_name`, `tool_input`, `tool_output` | `updatedToolOutput`, `additionalContext` |
| **PostToolUseFailure** | Tool fails | No | `tool_name`, `tool_input`, `error` | `additionalContext` |
| **PostToolBatch** | Parallel batch completes | Yes | Batch metadata | `decision: "block"` |
| **PermissionRequest** | Permission dialog appears | Yes | `tool_name`, `tool_input`, `permission_mode` | `decision.behavior`, `updatedInput` |
| **PermissionDenied** | Auto-mode classifier denies | No | `tool_name`, `tool_input` | `retry: true` |

#### Agent Events
| Event | Fires | Can Block | Input | Output |
|-------|-------|-----------|-------|--------|
| **SubagentStart** | Subagent spawned | No | matcher: agent type | `additionalContext` |
| **SubagentStop** | Subagent finishes | Yes | `agent_type`, result | `decision: "block"`, `additionalContext` |
| **TaskCreated** | Task created | Yes | Task data | `decision: "block"` |
| **TaskCompleted** | Task marked complete | Yes | Task data | `decision: "block"` |
| **TeammateIdle** | Agent teammate idle | Yes | N/A | `decision: "block"` / `continue: false` |

#### File & Configuration Events
| Event | Fires | Can Block | Input | Output |
|-------|-------|-----------|-------|--------|
| **FileChanged** | Watched file changes | No | matcher: filename patterns | N/A |
| **ConfigChange** | Config changes during session | Yes (except policy) | matcher: source | `decision: "block"` |
| **CwdChanged** | Working directory changes | No | `cwd` | N/A |
| **InstructionsLoaded** | CLAUDE.md loaded | No | matcher: load reason | N/A |

#### Worktree & Context Events
| Event | Fires | Can Block | Input | Output |
|-------|-------|-----------|-------|--------|
| **WorktreeCreate** | Worktree created | Yes | Path, isolation type | Stdout path or `worktreePath` in JSON |
| **WorktreeRemove** | Worktree removed | No | Worktree path | N/A |
| **PreCompact** | Before compaction | Yes | matcher: `manual` or `auto` | `decision: "block"` |
| **PostCompact** | After compaction | No | matcher: `manual` or `auto` | N/A |

#### MCP & Notification Events
| Event | Fires | Can Block | Input | Output |
|-------|-------|-----------|-------|--------|
| **Elicitation** | MCP requests user input | Yes | matcher: MCP server name | `action`, `content` |
| **ElicitationResult** | User responds to elicitation | Yes | matcher: MCP server name | `action`, `content` override |
| **Notification** | Claude sends notification | No | matcher: notification type | N/A |
| **MessageDisplay** | Assistant message streams | No | N/A | `displayContent` (display-only replacement) |

### Hook Configuration & Execution

#### Hook Locations
- **User**: `~/.claude/hooks/`
- **Project**: `.claude/hooks/`
- **Skill/plugin**: Inside skill or plugin directory

#### Hook Types & Formats
1. **Command hook** (shell script): Receives JSON on stdin, returns JSON/exit code on stdout.
   ```json
   {
     "type": "command",
     "command": "/path/to/script.sh",
     "timeout": 5000
   }
   ```

2. **HTTP hook** (webhook): POST JSON to remote URL; response is JSON.
   ```json
   {
     "type": "http",
     "url": "https://example.com/webhook",
     "timeout": 5000,
     "includeHeaders": ["Authorization"]
   }
   ```

3. **Prompt-based hook**: Claude evaluates a prompt-based condition.
   ```json
   {
     "type": "prompt",
     "prompt": "Should Claude allow this edit? Answer yes or no."
   }
   ```

4. **Agent-based hook**: Spawn a subagent to evaluate.
   ```json
   {
     "type": "agent",
     "agent": "security-reviewer"
   }
   ```

#### Matchers
Filter which invocations a hook applies to:
- **Tool name**: `"matcher": "Bash"`
- **Tool + parameters**: `"matcher": "Bash(git *)"`
- **Field match**: `"if": "tool_input.command matches 'rm -rf'"`
- **Multiple matchers**: `"matchers": ["Bash", "Edit"]`

#### Exit Code Semantics
- **0**: Success; process JSON from stdout.
- **2**: Blocking error; show stderr to Claude/user; block action (for applicable events).
- **Other**: Non-blocking error; show stderr in transcript; continue execution.

#### JSON Input/Output Contract

**Common input fields** (all events):
```json
{
  "session_id": "abc123",
  "prompt_id": "550e8400...",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/directory",
  "permission_mode": "default|plan|acceptEdits|auto|dontAsk|bypassPermissions",
  "effort": { "level": "low|medium|high|xhigh|max" },
  "hook_event_name": "EventName"
}
```

**Common output fields** (all hooks):
```json
{
  "continue": true,
  "stopReason": "Message if continue=false",
  "suppressOutput": false,
  "systemMessage": "Warning to user",
  "additionalContext": "Context for Claude",
  "terminalSequence": "OSC escape"
}
```

**Event-specific input/output**: documented per event (PreToolUse, PostToolUse, PermissionRequest, etc.).

#### Async Hooks
Hooks can run in background: set `"async": true` to not block the session. Runs after the tool or action completes; no feedback to Claude.

#### Hook Invocation Priority
1. **Matchers filter** which hooks apply.
2. **Hooks fire in order** (command, then HTTP, then prompt/agent).
3. **First blocking result** (exit 2 or `decision: "block"`) stops the chain.
4. **Outputs merge**: multiple hooks' `additionalContext` concatenated.

---

## 4. MEMORY & CONTEXT

### CLAUDE.md Hierarchy & Loading

#### Scopes & Locations
| Scope | Location | Purpose | Load Time | Shared With |
|-------|----------|---------|-----------|-------------|
| **Managed policy** | Org-managed path (see settings) | Organization-wide rules | Every session | All users |
| **User** | `~/.claude/CLAUDE.md` | Personal defaults | Every session | All projects |
| **Project** | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team-shared | Every session | Via version control |
| **Local** | `./CLAUDE.local.md` | Personal project prefs (gitignored) | Every session | Just you |
| **Directory-scoped** | `sub/CLAUDE.md` in subdirectories | Lazy-loaded when Claude works in `sub/` | On-demand | Not auto-loaded at startup |

**Load order**: Managed → User → Project (top-down hierarchy) → Local → Subdirectories (lazy).

**Behavior**: All discovered files concatenated into context, not overriding. Project CLAUDE.md loaded after user so project instructions take precedence. Within a directory, `CLAUDE.local.md` appended after `CLAUDE.md`.

#### CLAUDE.md Writing Best Practices
- **Size target**: Under 200 lines per file; tokens add up at every session start.
- **Structure**: Use Markdown headers and bullets for scanning.
- **Specificity**: Concrete instructions beat vague guidance ("2-space indentation" vs. "format nicely").
- **Imports**: `@path/to/file` syntax includes external files at load time (max 4 hops deep); wrap in backticks to suppress import.
- **Comments**: HTML block comments `<!-- note -->` stripped before injection (not in code blocks).

#### Auto-Discovery & Lazy Loading
- **Root CLAUDE.md**: Walk up from cwd to find all root-level CLAUDE.md and CLAUDE.local.md files; load all at startup.
- **Subdirectory CLAUDE.md**: Discovered when Claude reads files in that directory; loaded on-demand (lazy).
- **`.claude/rules/`**: Markdown files in `.claude/rules/` discovered automatically; non-path-scoped rules load at startup; path-scoped rules (with `paths:` frontmatter) load when Claude works with matching files.

#### Path-Scoped Rules
Use YAML frontmatter with `paths:` field to conditionally load instructions:
```markdown
---
paths:
  - "src/api/**/*.ts"
  - "tests/**/*.test.ts"
---
# API Development Rules
- Input validation on all endpoints
```

Glob patterns match files when Claude reads them (including symlinked paths). Multiple patterns and brace expansion supported (`src/**/*.{ts,tsx}`).

#### Organization-Wide CLAUDE.md
Deployed via managed policy (cannot be excluded by individual settings). Can be a separate file or inline in `managed-settings.json` via `"claudeMd": "..."` key.

#### Excluding CLAUDE.md Files
Set `claudeMdExcludes` in `.claude/settings.local.json` or managed settings to skip specific CLAUDE.md files by glob pattern (matched against absolute paths). Managed policy CLAUDE.md cannot be excluded.

### Auto Memory

**Default**: ON. Disable via `/memory` toggle or `autoMemoryEnabled: false` in settings.

**Storage**: Per-repository at `~/.claude/projects/<project>/memory/`; shared across worktrees of same repo. Customizable via `autoMemoryDirectory` in settings (absolute path or `~/`).

**Structure**:
- `MEMORY.md`: Index (first 200 lines or 25KB loaded at startup).
- Topic files: `debugging.md`, `api-conventions.md`, etc. (loaded on-demand via Read tool).

**How it works**: Claude reads first 200 lines of MEMORY.md at session start, decides what's worth noting during session, and writes updates to topic files. Claude keeps MEMORY.md concise by archiving details to topic files.

**Machine-local**: Auto memory does not sync across machines or to cloud sessions.

### Memory Commands & Management
- **`/memory`**: List and edit all CLAUDE.md, rules, and auto memory files.
- **`/init`**: Generate starter CLAUDE.md with discovered conventions (or improve existing).
- **`/compact [instructions]`**: Summarize history; project-root CLAUDE.md re-injected afterward (lazy CLAUDE.md in subdirs do not auto-reload).

### Context Window Management
**Capacity**: 32K tokens (Haiku) up to 1M tokens (Sonnet 5 extended context) depending on model.

**What fills context**:
- System prompt (including CLAUDE.md and rules).
- Conversation messages and tool outputs.
- State (working directory, git status, etc.).

**What survives compaction**:
- Project-root CLAUDE.md (re-read from disk post-compact).
- Rules (path-scoped reload on next file match).
- Subdirectory CLAUDE.md (reload on next file read in that directory).
- Conversation structure (summaries replace detailed history).

**What does NOT survive**:
- Conversation-only instructions (add to CLAUDE.md to persist).
- Nested CLAUDE.md from subdirectories (not re-injected; reload on next file match).

**Auto-compaction**: Triggered when context reaches limit; manual `/compact` also available.

**Microcompact**: Automatically remove old messages while keeping recent context and all CLAUDE.md.

---

## 5. SUBAGENTS

### Subagent Definition Format

Subagents are markdown files at:
- **User**: `~/.claude/agents/`
- **Project**: `.claude/agents/`
- **Built-in**: Bundled with Claude Code (Research, Code Review, Debugging, Data Science, etc.)

### Subagent Frontmatter Fields

```yaml
---
name: Agent display name
description: Description for Claude to decide when to delegate
tools: "Read,Edit,Bash"  # Restrict which tools are available
model: "claude-haiku-4-5"  # Override model for this subagent
effort: "low"  # Effort level override
permissionMode: "auto"  # Permission mode for subagent
autoMemory: true  # Enable persistent memory for this subagent
maxTurns: 10  # Maximum turns before auto-return
icon: "🔍"  # Optional display icon
---
```

### Subagent Invocation
1. **Automatic**: Claude delegates when a prompt matches subagent description.
2. **Explicit**: Use `/agent-name` command or `Agent(agent-name)` tool.
3. **Foreground**: Wait for result before continuing.
4. **Background**: Continue immediately; `/tasks` shows progress.

### Tool Restrictions in Subagents
Subagents inherit parent session's permissions but can be further restricted via `tools:` field. Common patterns:
- Research agent: `"WebSearch,WebFetch,Read"` (no file edits).
- Code reviewer: `"Read,Bash(git *)"` (read-only review).
- Debugger: `"Read,Edit,Bash,Monitor"` (interactive debugging).

### Subagent Context & Memory
- **Context**: Inherits parent session's CLAUDE.md, rules, MCP servers (unless scoped).
- **Persistent memory**: Subagent can maintain own auto memory if `autoMemory: true`.
- **Resumption**: `/resume` within a subagent returns to it by ID.

### Nested Subagents
Subagents can spawn other subagents; nesting is allowed.

---

## 6. SKILLS & COMMANDS

### Skill File Format

Skills are markdown files at:
- **User**: `~/.claude/skills/`
- **Project**: `.claude/skills/`
- **Plugin**: Inside plugin directory

File structure:
```
.claude/skills/
├── deploy/
│   ├── SKILL.md
│   ├── helpers.js
│   └── config.yaml
└── lint/
    └── SKILL.md
```

Filename becomes command name (e.g., `SKILL.md` in `deploy/` creates `/deploy` command).

### Skill Frontmatter

```yaml
---
description: What the skill does (shown in /help)
argument-hint: <optional args to accept>
allowed-tools: "Read,Bash,Edit"  # Pre-approve these tools
model: "claude-haiku-4-5"  # Override model
effort: "medium"  # Override effort
invoke-manually: true  # User only (default); false = Claude can invoke
context: "fork"  # Skill runs in isolated context
agent: "subagent-name"  # Run in subagent instead of main session
---
# Skill content here
Instructions for Claude to follow when invoked.
```

### Skill Features
- **`$ARGUMENTS`** or **`$1`**: Access arguments passed to skill.
- **`!`command` preprocessing**: Commands in backticks evaluated and substituted.
- **Dynamic context injection**: Skills can load external files at runtime.
- **Arguments**: Pass arguments: `/skill arg1 arg2` or chain skills: `/skill-a /skill-b "trailing args"`.
- **Skill discovery**: Type `/` and search; Claude auto-invokes relevant skills.
- **Tool pre-approval**: `allowed-tools:` auto-approves listed tools when skill runs.

### Built-In Skills & Commands
Available via `/` menu:
- `/debug`: Bundled debugging skill.
- `/code-review`: Bundled code review skill.
- `/deep-research`: Bundled research skill (custom in this config).
- `/run`: Run and verify the app (project-specific if available).
- `/verify`: Verify a code change works end-to-end.
- `/simplify`: Review and simplify changed code.
- `/code-review`: Detailed code review (also available as `ultrareview` on web).
- `/batch`: Parallel multi-agent change across 5–30 worktrees.
- Custom skills from project `.claude/skills/`.

---

## 7. OUTPUT & UX

### Output Styles
Change system prompt to alter response tone, role, and format without changing knowledge.

**Built-in styles**:
- **Default**: Standard software engineering assist.
- **Proactive**: Assume intent, act immediately; stronger than auto mode but still shows permission prompts.
- **Explanatory**: Educational "Insights" explaining implementation choices.
- **Learning**: Collaborative; asks user to implement marked `TODO(human)` sections.

**Custom output styles**: Markdown files at `~/.claude/output-styles/`, `.claude/output-styles/`, or managed path.

**Frontmatter**:
```yaml
---
name: Style name (if not filename)
description: Shown in /config picker
keep-coding-instructions: true  # Keep Claude's default coding behavior
---
# Custom instructions here
```

**Precedence**: Most specific (local) → project → user. When multiple styles share same name, use closest to working directory.

### Statusline (Status Bar)

**Configuration**:
1. Run `/statusline` for interactive setup.
2. Manual: Add `statusLine` entry to settings.json:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "/path/to/script.sh",
       "padding": 0
     }
   }
   ```

**Input (JSON on stdin)**:
```json
{
  "context_window": {
    "used": 15000,
    "total": 32000,
    "percentage": 47
  },
  "session_id": "...",
  "cwd": "/path"
}
```

**Output**: Plain text or terminal escape sequences (OSC 9 notifications, etc.).

**Examples**:
- Context meter: `Context: 47% (15K/32K)`
- Git status with colors: Branch, changes, staged count.
- Cost tracker: Running total with model.
- Multiple lines: Use `\n` or output multiple status calls.
- Clickable links: Use terminal hyperlink escapes.

### Notifications

**Channel types**:
- **Terminal bell**: Audible system beep.
- **Terminal title**: OSC escape sequences.
- **Push notification** (if mobile/Remote Control enabled): Message to device.

**Triggers**:
- Input needed (permission prompt, question).
- Background agent finished.
- Hook error.

**Configuration**: Set `preferredNotifChannel` in settings.

### Todo List
Claude creates a to-do checklist (separate from background-task view). Toggle with `Ctrl+T`. Tasks persist across compaction. Set `CLAUDE_CODE_TASK_LIST_ID=my-project` to share across sessions.

### Session Recap
Auto-generated one-line summary after 3+ minutes idle and 3+ turns. Toggle in `/config` or run `/recap` manually. Skipped in non-interactive mode.

### PR Review Status Badge
When on a branch with open PR, footer shows PR link with colored underline (green=approved, yellow=pending, red=changes-requested, gray=draft). Status refreshes every 60 seconds or after `gh pr` / `git push` command. Click with `Cmd+click` (macOS) / `Ctrl+click` (Windows/Linux) to open PR in browser.

### Cost Tracking
- **`/usage`**: Show detailed token and cost breakdown by model and tool.
- **`/cost`**: Quick cost estimate for current session.
- **`--max-budget-usd`**: CLI flag to abort if spend exceeds amount.
- **Output format JSON**: Includes `total_cost_usd` and per-model breakdown.

---

## 8. BUILT-IN TOOLS

### Read
- **Input**: `path` (file path), `line_start` (optional), `line_end` (optional).
- **Output**: File contents (up to 2000 lines default; configurable).
- **Behavior**: Read any file in working directory or `additionalDirectories`; images are displayed visually (PNG, JPG); PDFs supported (fetch specific page ranges).
- **Permission**: Read-only; auto-approved in all modes except denies.

### Edit
- **Input**: `path`, `old_text`, `new_text`.
- **Output**: Confirmation and line numbers of change.
- **Behavior**: Replace exact text; shows diff context before applying; supports multiple edits per invocation.
- **Permission**: Auto-approved in `acceptEdits` and `plan`; prompts in `default`; blocks in `dontAsk`.

### Write
- **Input**: `path`, `content`.
- **Output**: Confirmation of file creation/overwrite.
- **Behavior**: Create new file or overwrite existing; fail if file exists (use Edit to modify).
- **Permission**: Same as Edit.

### Bash (Shell Execution)
- **Input**: `command`, `cwd` (optional).
- **Output**: Stdout, stderr, exit code.
- **Behavior**: Run arbitrary shell commands in session's working directory; output max 10K lines; timeouts configurable.
- **Sandboxing**: Optional (`sandbox.enabled: true`); routes through Linux sandbox if enabled.
- **Background**: Press `Ctrl+B` to background; output logged, retrievable with Read.
- **Shell mode** (`!` prefix): Run directly without Claude interpretation; output auto-added to context.
- **Permission**: Auto-approved for read-only commands (`ls`, `git log`, `cat`, etc.); others prompt.

### Edit (Bash)
- **BashOutput**: Structured response with `stdout`, `stderr`, `exit_code`.
- **KillBash**: Signal to stop a running background command (SIGTERM or SIGKILL).

### Glob
- **Input**: `pattern` (glob or regex), optional `exclude_pattern`.
- **Output**: Array of matching file paths.
- **Behavior**: Find files matching glob (e.g., `**/*.ts`); excludes `.git`, `node_modules`, etc. by default.
- **Permission**: Read-only; auto-approved.

### Grep
- **Input**: `pattern` (regex), `paths` (glob pattern).
- **Output**: Line numbers, matched lines, file paths.
- **Behavior**: Search for text pattern in files matching glob.
- **Permission**: Read-only; auto-approved.

### WebFetch
- **Input**: `url`.
- **Output**: HTML converted to Markdown, or structured content extraction.
- **Behavior**: Fetch web content; auto-convert HTML to Markdown; optional cached results (15-min TTL).
- **Permission**: Prompts in `default`; auto-approved in `acceptEdits` / `auto`; blocks in `dontAsk`.

### WebSearch
- **Input**: `query`.
- **Output**: Array of search results with title, URL, snippet.
- **Behavior**: Perform web search; includes links as Markdown; only available in US.
- **Permission**: Prompts in `default`; auto-approved in other modes.

### Agent (Subagent Spawning)
- **Input**: `agent` (name), `prompt` (task), `foreground` (optional, default false).
- **Output**: Subagent result (text or structured).
- **Behavior**: Spawn subagent; run foreground (wait for result) or background (continue immediately).
- **Permission**: Blocked in `dontAsk` unless explicit allow rule.

### AskUserQuestion
- **Input**: `question`, `options` (optional array of choices), `allow_free_text` (optional).
- **Output**: User's response.
- **Behavior**: Pause and ask user for input; supports multiple choice or free text; can set `askUserQuestionTimeout` for auto-continue.
- **Permission**: Always prompts; intentional gate.

### NotebookEdit
- **Input**: `path`, `cells` (array of cell operations).
- **Output**: Confirmation of notebook edits.
- **Behavior**: Edit Jupyter notebooks (.ipynb); add/remove/modify cells.
- **Permission**: Same as Edit (prompts in default).

### Monitor
- **Input**: URL (WebSocket or custom stream).
- **Output**: Real-time events from stream (logs, metrics, etc.).
- **Behavior**: Subscribe to live event stream; e.g., tail logs, watch build output, subscribe to external event channels.
- **Permission**: Prompts for network access in `default`.

### TodoWrite
- **Input**: `todos` (array of task objects with `id`, `text`, `status`).
- **Output**: Confirmation.
- **Behavior**: Create/update/complete Claude's to-do checklist items.
- **Permission**: Auto-approved.

### Task (Agent SDK only, not in CLI)
- **Input**: Task specification with title, description, effort.
- **Output**: Task ID, status, results.
- **Behavior**: Spawn persistent background task; track via `/tasks` and Task tools.

### ExitPlanMode
- **Input**: None.
- **Output**: Confirmation.
- **Behavior**: Exit plan mode and return to previous permission mode.
- **Permission**: Always allowed.

### ListMcpResources / ReadMcpResource
- **Input**: MCP server name, resource URI/path.
- **Output**: List of resources or resource content.
- **Behavior**: Interact with MCP server's resource protocol.
- **Permission**: Prompts for MCP tool use.

### EnterWorktree
- **Input**: `branch` (optional), `isolation` (optional).
- **Output**: New worktree path.
- **Behavior**: Create isolated git worktree on specified branch (or current); CLAUDE.md re-loaded in worktree context.
- **Permission**: Prompts.

---

## 9. MCP (MODEL CONTEXT PROTOCOL)

### MCP Server Installation
- **Command**: `claude mcp add`, list, remove, login (CLI).
- **Config file**: `.mcp.json` (project) or `~/.claude/.mcp.json` (user).
- **Scopes**: Local (`.claude/.mcp.json`), Project (`.claude/.mcp.json`), User (`~/.claude/.mcp.json`); precedence same as settings.

### MCP Server Types (Installation Options)
1. **HTTP/SSE server**: Remote URL-based MCP server.
   ```json
   {
     "servers": {
       "my-server": {
         "type": "http",
         "url": "https://api.example.com/mcp"
       }
     }
   }
   ```

2. **Stdio server**: Local command spawned as subprocess.
   ```json
   {
     "servers": {
       "local-server": {
         "type": "stdio",
         "command": "/path/to/server",
         "args": []
       }
     }
   }
   ```

3. **SDK server**: Instantiated programmatically (Agent SDK only).

### MCP Server Authentication
- **OAuth2**: Automatic browser-based flow; `claude mcp login <name>` to authenticate.
- **Static credentials**: Pass via `env` variable in settings or `--env KEY=value`.
- **Dynamic headers**: Script to generate auth headers on each request.
- **Pre-configured credentials**: Store OAuth token in settings (encrypted at rest).

### MCP Tool Use
- **Discovery**: Claude auto-discovers tools from connected servers; list via `/mcp`.
- **Tool naming**: MCP tools prefixed with server name (e.g., `slack/post_message`).
- **Tool search**: If many tools available, MCP tool search defers tool loading (fetches schema on demand).
- **Auto-approval**: Pre-approve MCP tools via `permissions.allow` rules.
- **Tool restrictions**: Deny specific MCP tools via `permissions.deny` rules.

### MCP Prompts as Commands
Some MCP servers offer prompts (reusable instructions). Invoke as `/mcp-server:prompt-name` in the message.

### Managed MCP Configuration
- **Exclusive control**: `.managed-mcp.json` locks MCP servers (admins only).
- **Allowlist/denylist**: Policy-based control over which servers users can add.
- **Per-user credentials**: Authenticate all users to the same server via org credentials.

### Cache Invalidation with MCP
Switching, connecting, or disconnecting an MCP server invalidates prompt cache. Reconnecting keeps cache.

---

## 10. SESSIONS

### Resume & Continue
- **`claude --continue`**: Load most recent conversation in current directory.
- **`claude --resume [name]`**: Open session picker or resume named session directly.
- **`claude --resume <session-id>`**: Resume by UUID.
- **`/resume [name]`**: Switch to different session from inside active session.
- **Session storage**: `~/.claude/projects/<project>/` (one JSONL transcript per session).
- **Retention**: 30 days by default (configurable via `cleanupPeriodDays`).

### Session Naming
- **At startup**: `claude -n "auth-refactor"`.
- **During session**: `/rename "new-name"`.
- **From picker**: Highlight and press `Ctrl+R`.
- **Auto-name after plan acceptance**: Extracted from plan content (unless already named).
- **Default display name** (v2.1.196+): Auto-generated from directory name + suffix if not explicitly named.

### Session Picker (Interactive UI)
- **Navigate**: Up/Down arrows.
- **Search**: Type any character to filter; paste PR/MR URL to find linked session.
- **Preview**: Space to preview conversation content.
- **Expand groups**: Left/Right arrows (forks grouped under root).
- **Scope widening**: `Ctrl+A` (all projects), `Ctrl+W` (all worktrees), `Ctrl+B` (filter by branch).
- **Rename**: Highlight and press `Ctrl+R`.

### Branching (Forking)
- **`/branch [name]`**: Create conversation copy; original unchanged and resumable.
- **`--fork-session`**: CLI equivalent; combine with `--continue` or `--resume`.
- **Behavior**: Branch inherits conversation up to that point; new session ID; permissions (session-specific allow) do not carry over.
- **Viewing original**: Session picker shows forks grouped under root; pass root ID to `/resume` to return.

### Checkpointing & Rewind
- **Automatic**: Snapshot after each turn; no user action required.
- **Manual rewind**: Double-Esc when input is empty to open rewind menu.
- **Rewind options**: Restore code to earlier checkpoint, restore conversation, or both.
- **Limitation**: Does not track Bash changes or external file modifications; not a version control replacement.

### Session Export
- **`/export [filename]`**: Save rendered conversation as plain text or copy to clipboard.
- **Structured access**: For scripts, use `/export` output, transcripts JSONL, or Agent SDK message API.
- **Transcript location**: `~/.claude/projects/<project>/<session-id>.jsonl` (JSONL per-message format; internal and may change).

### Transcript Locations & Formats
- **Default storage**: `~/.claude/projects/<project-name>/<session-id>.jsonl`.
- **Customization**: Set `CLAUDE_CODE_SKIP_PROMPT_HISTORY=1` to suppress writes; `--no-session-persistence` for one-off `-p` runs.
- **Alternate location**: Set `CLAUDE_CONFIG_DIR` to move `~/.claude` entirely.

---

## 11. NON-INTERACTIVE MODE

### Print Mode (`-p` / `--print`)
- **Basic**: `claude -p "query"` runs Claude once and prints response.
- **Exit code**: 0 on success; non-zero on error.
- **Stdin**: Reads piped input; cap 10MB.
- **No session persistence**: Use `--no-session-persistence` to skip transcript storage.

### Bare Mode (`--bare`)
- **Speed**: Skip auto-discovery of hooks, skills, plugins, MCP, auto memory, CLAUDE.md.
- **Use case**: CI/scripts where you need reproducible results on every machine.
- **Authentication**: Bare mode skips OAuth/keychain; use `ANTHROPIC_API_KEY` or `apiKeyHelper`.
- **Explicit config**: Pass context via flags (`--settings`, `--mcp-config`, `--append-system-prompt`, etc.).

### Output Formats
- **`text`** (default): Plain text response.
- **`json`**: Structured JSON: `{ "result": "...", "session_id": "...", "total_cost_usd": 0.05 }`.
- **`stream-json`**: Newline-delimited JSON; each line is an event (text deltas, tool calls, etc.).

### Streaming Output
- **`--output-format stream-json --verbose --include-partial-messages`**: Stream tokens in real-time.
- **Event types**: `stream_event` (text delta), `system/api_retry` (retry notifications), `system/init` (metadata), `system/plugin_install` (plugin progress).
- **Processing**: Use `jq` to extract specific fields (e.g., `jq -rj '.event.delta.text'` for tokens).

### Structured Output (JSON Schema)
- **`--json-schema <schema>`**: Validate output against JSON Schema.
- **Response**: `{ "structured_output": {...}, ... }`.
- **Example**: Extract function names as array of strings.

### Continuation in Print Mode
- **`--continue`**: Continue most recent session.
- **`--resume <id>`**: Continue specific session.
- **Capture session ID**: Use `--output-format json` to extract `session_id` for later resumption.

### Auto-Approve Tools
- **`--allowedTools "Read,Edit,Bash"`**: Pre-approve specified tools.
- **`--permission-mode acceptEdits`**: Pre-approve file edits + common filesystem commands.
- **`--permission-mode dontAsk`**: Only pre-approved tools execute (non-interactive for CI).

### Environment Variables for Print Mode
- **`ANTHROPIC_API_KEY`**: API key (required in bare mode).
- **`CLAUDE_CODE_*`**: Enable debug logging, skip features (see env-vars reference).

---

## 12. DISTINCTIVE FEATURES

### Model Selection & Configuration
- **Available models**: Sonnet 5, Opus 4.6–4.8, Haiku 4.5 (plus Fable 5 with always-on thinking).
- **Model aliases**: `default`, `opusplan` (Opus in plan mode), `opus`, `sonnet`, `haiku`.
- **Switch mid-session**: `Option+P` / `Alt+P` or `/model` command.
- **CLI**: `--model claude-sonnet-5` or `--model sonnet`.
- **Settings**: `"model": "claude-haiku-4-5"` in settings.json.
- **Fallback chain**: `--fallback-model sonnet,haiku` (try Sonnet, then Haiku if unavailable).
- **Extended thinking**: Toggle with `Option+T` / `Alt+T` or `--betas interleaved-thinking`; disabled on Fable 5 (always on).
- **Effort levels**: `low`, `medium`, `high`, `xhigh`, `max` (increase thinking budget); set at startup or toggle mid-session via `/effort`.

### IDE Integrations
- **VS Code extension**: Spark icon in activity bar; prompt box, file references, commands, plugin management.
- **JetBrains plugin**: Launch Claude in IDE terminal; same CLI features.
- **Desktop app**: Separate UI from CLI; supports cloud sessions, Remote Control, computer use, preview servers.
- **Web**: `claude.ai/code` (cloud sessions, Remote Control, Slack threads).

### Git Worktree Support
- **`claude -w feature-auth`**: Create isolated git worktree on new branch; run Claude in worktree; CLAUDE.md reloaded per-worktree context.
- **`--tmux`**: Create tmux session for worktree (for tmux-based coordination).
- **Multiple worktrees**: Session picker shows `Ctrl+W` to view all worktrees of repo; resume in any one.
- **Cleanup**: Worktrees auto-cleaned on exit or subagent end; manual via `/clean-worktree`.

### Background Agents & Agent View
- **`claude --bg "task here"`**: Start as background agent; monitor via `claude agents` or agent view.
- **`claude agents`**: Open agent view (table of running sessions, spawn new, attach to existing).
- **`claude attach <session-id>`**: Attach to background session and take over.
- **`claude stop <id>` / `claude respawn <id>` / `claude rm <id>`**: Manage background sessions.
- **Supervisor process**: Background agents managed by `claude daemon`; auto-restarts on crash.

### Remote Control
- **`claude remote-control --name "My Machine"`**: Start Remote Control server on local machine.
- **Access from claude.ai or mobile**: Connect to local session via Remote Control UI.
- **Mode control**: Can switch permission modes from Mobile UI; mode in terminal overrides.
- **Trusted devices**: Organization admins can require Trusted Device enrollment.

### Plugins & Marketplaces
- **Install**: `/plugin install plugin-name@marketplace` or `/plugin install path/to/local/plugin`.
- **Marketplace**: Add via `/plugin marketplace add <url>`; builtin Anthropic marketplace, community marketplace, custom.
- **Plugin components**: Skills, hooks, MCP servers, LSP servers, monitors, themes, output styles.
- **Auto-update**: Managed via marketplace version resolution; pin specific versions.
- **Plugin hints**: Plugins can emit hints to suggest themselves to users when relevant files appear.

### `/doctor` Command
Diagnostic utility to check:
- Claude Code version and installation integrity.
- Authentication status.
- Network connectivity.
- MCP server health.
- Plugin load errors.
- Configuration validity.
- Git status.

### `/login` & `/logout` Commands
- **`/login`**: Authenticate to Claude (OAuth or API key).
- **`--console`**: CLI-only login method (no browser).
- **`/logout`**: Sign out.
- **Manage accounts**: Multiple accounts via `CLAUDE_CONFIG_DIR` env var for profile switching.

### Security Review (`/security-review`)
Audit configuration for security issues: overly permissive rules, exposed credentials, dangerous hooks, etc.

### `ultraplan` (Plan Mode in Browser)
- **`/ultraplan`** in terminal: Launch plan in browser.
- **Visual review**: See plan rendered beautifully; edit before approval.
- **Execute locally or on web**: Choose to execute planned changes on local machine or in cloud session.

### Environment Variables (`CLAUDE_CODE_*`)
Control behavior via env vars:
- **`CLAUDE_CODE_DISABLE_AUTO_MEMORY`**: Disable auto memory.
- **`CLAUDE_CODE_SKIP_PROMPT_HISTORY`**: Skip transcript storage.
- **`CLAUDE_CODE_TASK_LIST_ID`**: Shared task list directory.
- **`CLAUDE_CODE_DISABLE_BACKGROUND_TASKS`**: Disable background Bash.
- **`CLAUDE_CODE_SYNC_PLUGIN_INSTALL`**: Emit plugin install events.
- **`CLAUDE_CODE_ENABLE_PROMPT_SUGGESTION`**: Enable/disable prompt suggestions.
- **`CLAUDE_CODE_DISABLE_BG_SHELL_PRESSURE_REAP`**: Disable memory-pressure task termination (macOS/Linux).
- **`CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS`**: Cap on background task wait in `-p` mode.
- **`CLAUDE_CODE_NEW_INIT`**: Enable interactive `/init` flow.
- **`CLAUDE_CONFIG_DIR`**: Override `~/.claude` location.
- **`CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD`**: Load CLAUDE.md from `--add-dir` directories.
- **`CLAUDE_CODE_ENABLE_AUTO_MODE`** (Bedrock/Foundry/Agent Platform): Enable auto mode.

### Fast Mode
- **Toggle**: `Option+O` / `Alt+O` or `/config` → Fast mode.
- **Behavior**: Route reasoning to faster, cheaper model (e.g., Haiku) instead of default.
- **Trade-off**: Speed/cost vs. quality.
- **Requirements**: Claude Code v2.1.132+; requires account tier with fast mode enabled.
- **Cache invalidation**: Switching fast mode invalidates prompt cache.

### Advisor Tool
- **`--advisor <model>`**: Enable advisor (server-side model approves actions before execution).
- **Use case**: Human-in-the-loop safety gate for autonomous workflows.
- **Behavior**: For each action, advisor model reviews and approves/denies before Claude Code proceeds.
- **Cost**: Adds extra token usage per action.

### Auto Mode Classifier Configuration
- **`/auto-mode defaults`**: Print full rule list for auto mode.
- **Trusted infrastructure**: Set `autoMode.environment` in managed settings to define trusted repos, buckets, services.
- **Classifier behavior**: Routes actions through ML-based evaluator; blocks deployments, destructive ops, hostile content; allows local edits.
- **Fallback**: If classifier repeatedly denies, auto mode falls back to manual prompting (3 consecutive or 20 total blocks trigger fallback).

### Channels (Research Preview)
- **Webhook-based notifications**: Configure MCP servers as channels to push messages into session.
- **Supported protocols**: Webhook receivers, relay to permission prompts, custom handlers.
- **Use case**: React to Slack messages, Discord chats, or external events while Claude Code is away.

### `//continue` Session Continuation (Shorthand)
In some interfaces (web, mobile), `//continue` resumes the most recent session. Equivalent to `claude --continue` in CLI.

### Import/Export Artifacts
- **Artifacts**: Interactive code/design outputs created by Claude; shareable via URL.
- **Web-only feature**: Not available in CLI (use `/export` for conversations instead).
- **Domains**: `claude.ai`, `artifacts.ai` (configurable allowlist in org settings).

### PR Linking & Automation
- **Auto-detect PR**: When on a branch with open PR, footer shows PR status badge (green/yellow/red/gray).
- **`--from-pr <number>`**: Resume session linked to PR.
- **GitHub Actions**: Claude Code can auto-fix PRs via GitHub Actions integration (with GA workflow).
- **Session attachment**: Push to PR automatically links session for easy resume.

### Composer Mode (Web/Desktop Only)
- **Artifact-centric UI**: Focus on building interactive outputs (not in CLI).

---

## 13. FINE-GRAINED INTERACTION DETAILS

### Prefix Notation in Prompts
- **`/` prefix**: Command or skill (autocomplete available).
- **`!` prefix**: Shell mode; run command directly without Claude interpretation.
- **`@` in body**: File path autocomplete (triggered by `/` or `~/`).
- **`#` in body**: Memory reference shortcut.

### Confirmation Dialogs
- **Permission prompt**: Interactive approval for tools; `Left/Right` to cycle options, `Space/Enter` to confirm, `Esc` to cancel.
- **Rewind menu**: Select checkpoint to restore; `Up/Down` to navigate, `Enter` to rewind.
- **Session picker**: Search, filter, rename sessions; `Ctrl+R` to rename highlighted.

### Transcript Rendering
- **Plain text**: User prompts, assistant responses, tool invocations summarized.
- **Collapsed MCP calls**: "Called slack 3 times" (expand via `Ctrl+O` transcript viewer).
- **Code diffs**: Displayed inline with context lines.
- **Tool outputs**: Summarized; full output in transcript viewer.

### Error Handling
- **Tool execution error**: Claude sees error message; can retry or try alternative.
- **Permission denied**: Shown as tool result; Claude adjusts approach.
- **API errors**: Auto-retry with exponential backoff; `system/api_retry` event in stream-json mode.
- **Context overflow**: Auto-compaction triggered or manual `/compact` offered.

### Performance Tuning
- **Prompt caching**: System prompt + CLAUDE.md cached after first request in session (reduced cost on follow-ups).
- **Background tasks**: Long-running Bash backgrounded to not block Claude's next turn.
- **Token counting**: `/cost` and `/usage` show exact token usage.

---

## ARCHITECTURE & DEPLOYMENT NOTES

- **Execution model**: Local subprocess (not Anthropic-hosted for CLI; Managed Agents on web are Anthropic-hosted).
- **State storage**: Transcripts in `~/.claude/projects/`; sessions resumable across restarts.
- **Security**: Sandboxable Bash via sandbox runtime (Linux/WSL2); protected paths guard `.git`, `.claude`, shell config.
- **Scalability**: Background agents via supervisor daemon; parallel subagents with isolated contexts.
- **Extensibility**: Hooks (pre/post tool-use), skills (reusable workflows), MCP (external tool integration), plugins (distribute skills+hooks+MCP).

---

**End of Feature Inventory**

Generated for Claude Code mid-2026. See https://code.claude.com/docs for official documentation.
