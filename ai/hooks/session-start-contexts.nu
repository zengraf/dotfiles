# Claude Code SessionStart hook — surface task contexts + inject the maintenance protocol.
# stdout is added to the model's context. Schema and details live in the `ctx` skill.

let dir = ($env.HOME | path join ".claude" "contexts")
mkdir $dir

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
PROTOCOL — before starting the task:
• If the user's first message names a context, load it (Read ~/.claude/contexts/<slug>.md) without asking.
• Else ask which to use: an existing one above, a NEW name (create ~/.claude/contexts/<slug>.md from the /ctx schema), or "none" (disable for this session).
• Do not begin the task until a context is chosen or the user says "none".
WHILE working (context active):
• After each meaningful step/decision/correction, Edit the file: add new state AND fix or delete now-stale lines in place (prevents future-agent context poisoning).
• Keep it dense and small (<~1KB): telegraphic, symbols, single-letter keys G/S/D/✗/F/N/Q (schema in /ctx).
• Reading and writing in ~/.claude/contexts/ is pre-authorized — no permission prompts.'#
