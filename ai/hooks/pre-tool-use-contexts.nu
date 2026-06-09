# Claude Code PreToolUse hook — gate tool use until a task context is chosen this session.
# FAILS OPEN on any error or when CLAUDE_CTX_SKIP is set — must never wedge a session.

def allow [] { exit 0 }

# Escape hatch for headless / scheduled / automated runs.
if (($env.CLAUDE_CTX_SKIP? | default "") != "") { allow }

let parsed = (try { open --raw /dev/stdin | from json } catch { null })
let input = (if (($parsed | describe) | str starts-with "record") { $parsed } else { null })
if $input == null { allow }

let sid = ($input.session_id? | default "")
if $sid == "" { allow }

let contexts = ($env.HOME | path join ".claude" "contexts")
let gatedir = ($contexts | path join ".gates")
try { mkdir $gatedir }
let marker = ($gatedir | path join $sid)
if ($marker | path exists) { allow }

let tool = ($input.tool_name? | default "")
let file = ($input.tool_input?.file_path? | default "")

# Let the model write its own "none" marker into the gate dir.
if ($file != "" and ($file | str starts-with $gatedir)) { allow }

# Loading or creating a context (.md under contexts/) resolves the gate.
if (($tool in ["Read" "Edit" "Write"]) and ($file != "") and ($file | str starts-with $contexts) and ($file | str ends-with ".md")) {
  try { touch $marker }
  allow
}

let reason = $'Task-context gate unresolved — resolve before any other tool. Load or create a context in ~/.claude/contexts, or for "none" write an empty file at ~/.claude/contexts/.gates/($sid). See /ctx.'
{ hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason } } | to json | print
