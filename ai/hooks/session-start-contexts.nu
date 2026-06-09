# Claude Code SessionStart hook — surface task contexts + inject the maintenance protocol.
# stdout is added to the model's context. Schema and details live in the `ctx` skill.

let parsed = (try { open --raw /dev/stdin | from json } catch { {} })
let input = (if (($parsed | describe) | str starts-with "record") { $parsed } else { {} })
let sid = ($input.session_id? | default "unknown")

let dir = ($env.HOME | path join ".claude" "contexts")
mkdir $dir

let gatedir = ($dir | path join ".gates")
mkdir $gatedir
try {
  ls $gatedir
  | where type == file and $it.modified < ((date now) - 7day)
  | each {|f| rm --force $f.name }
  | ignore
}

let contexts = (
  ls $dir
  | where type == file and ($it.name | str ends-with ".md")
  | insert slug {|f| $f.name | path basename | str replace --regex '\.md$' '' }
  | insert days {|f| (((date now) - $f.modified) / 1day) | math floor }
  | sort-by modified --reverse
)

let recent = ($contexts | where days <= 7)
let stale = ($contexts | where days > 7 and days <= 30)

print "== TASK CONTEXTS (dense persistent memory for cheap resume; /ctx for schema) =="
print $"Session id: ($sid)"
print "Recent (≤7d):"
if ($recent | is-empty) {
  print "  (none)"
} else {
  for c in $recent { print $"  • ($c.slug) — ($c.days)d" }
}
if (not ($stale | is-empty)) {
  print "Stale (8–30d):"
  for c in $stale { print $"  • ($c.slug) — ($c.days)d" }
}

print r#'
PROTOCOL — a PreToolUse gate blocks ALL tools until resolved; resolve before any other tool call, even if the first message is a task:
• First message EXPLICITLY names a context → Read ~/.claude/contexts/<slug>.md (auto-resolves the gate).
• Otherwise you MUST ask the user and WAIT for their reply — never decide for them. A task in the first message is NOT permission to pick "none"; ask anyway. Options: load one listed above / a NEW name (create from the /ctx schema) / "none".
• ONLY after the user explicitly says "none" → Write an empty ~/.claude/contexts/.gates/<Session id above> to unblock.
WHILE working (context active):
• After each meaningful step, Edit the file: add new state AND fix/delete now-stale lines (prevents poisoning). Compress, don't log: N is future-only — fold finished steps into D/!/F and delete.
• Keep it dense and small (<~1KB): telegraphic, keys G/S/D/!/✗/F/N/Q (schema in /ctx).
• Reading and writing in ~/.claude/contexts/ is pre-authorized.'#
