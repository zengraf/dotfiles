# Gate tool use until a task context is chosen this session. Fails open on any error.

def allow [] { exit 0 }

# permissions.allow is ignored for writes under the protected ~/.claude dir; approve via PreToolUse instead.
def force-allow [reason: string] {
  { hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "allow", permissionDecisionReason: $reason } } | to json | print
  exit 0
}

if (($env.CLAUDE_CTX_SKIP? | default "") != "") { allow }

let parsed = (try { open --raw /dev/stdin | from json } catch { null })
let input = (if (($parsed | describe) | str starts-with "record") { $parsed } else { null })
if $input == null { allow }

let sid = ($input.session_id? | default "")
if $sid == "" { allow }

let contexts = ($env.HOME | path join ".local" "share" "claude-contexts")
let gatedir = ($contexts | path join ".gates")
try { mkdir $gatedir }
let marker = ($gatedir | path join $sid)

let tool = ($input.tool_name? | default "")
let file = ($input.tool_input?.file_path? | default "")

# The context picker must run while the gate is still unresolved.
if ($tool == "AskUserQuestion") { allow }

if ($file != "" and ($file | str starts-with $gatedir)) {
  force-allow "ctx: gate marker"
}

if (($tool in ["Read" "Edit" "Write"]) and ($file != "") and ($file | str starts-with $contexts) and ($file | str ends-with ".md")) {
  try { touch $marker }
  force-allow "ctx: context file"
}

if ($marker | path exists) { allow }

let reason = $'Task-context gate unresolved — resolve before any other tool. Load or create a context in ~/.local/share/claude-contexts, or for "none" write an empty file at ~/.local/share/claude-contexts/.gates/($sid). See /ctx.'
{ hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason } } | to json | print
