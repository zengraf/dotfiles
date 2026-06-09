# Claude Code SessionStart hook — surface task contexts + inject the maintenance protocol.
# stdout is added to the model's context. Schema and details live in the `ctx` skill.

let input = (try { $in | from json } catch { {} })
let sid = ($input.session_id? | default "unknown")

let dir = ($env.HOME | path join ".claude" "contexts")
mkdir $dir

# Prune stale per-session gate markers written by the PreToolUse gate.
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
• First message names a context → Read ~/.claude/contexts/<slug>.md (auto-resolves the gate).
• Else ask: load one listed above / a NEW name (create from the /ctx schema) / "none".
• "none" → Write an empty ~/.claude/contexts/.gates/<Session id above> to unblock.
WHILE working (context active):
• After each meaningful step/decision/correction, Edit the file: add new state AND fix or delete now-stale lines (prevents context poisoning).
• Keep it dense and small (<~1KB): telegraphic, single-letter keys G/S/D/✗/F/N/Q (schema in /ctx).
• Reading and writing in ~/.claude/contexts/ is pre-authorized.'#
