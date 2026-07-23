# Claude Code SessionStart hook: surface task contexts, then tell the model to open the picker.
# stdout is added to the model's context. Schema and details live in the `ctx` skill.

let parsed = (try { open --raw /dev/stdin | from json } catch { {} })
let input = (if (($parsed | describe) | str starts-with "record") { $parsed } else { {} })
let sid = ($input.session_id? | default "unknown")

let dir = ($env.HOME | path join ".local" "share" "claude-contexts")
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
  | insert scope {|f|
      let head = (try { open --raw $f.name | lines | first } catch { "" })
      if ($head | str contains "scope:") { $head | str replace --regex '^.*scope:\s*' '' | str trim } else { "" }
    }
  | sort-by modified --reverse
)

let recent = ($contexts | where days <= 7)
let stale = ($contexts | where days > 7 and days <= 30)

def fmt [c] {
  if (($c.scope? | default "") == "") { $"  • ($c.slug) — ($c.days)d" } else { $"  • ($c.slug) — ($c.days)d · ($c.scope)" }
}

print "== TASK CONTEXTS (dense persistent memory for cheap resume; /ctx for schema) =="
print $"Session id: ($sid)"
print "Recent (≤7d):"
if ($recent | is-empty) {
  print "  (none)"
} else {
  for c in $recent { print (fmt $c) }
}
if (not ($stale | is-empty)) {
  print "Stale (8–30d):"
  for c in $stale { print (fmt $c) }
}

print r#'
GATE: a PreToolUse hook blocks EVERY tool except AskUserQuestion until a context is chosen this session. Resolve it as your FIRST action, before replying in prose and before starting the user's task (a task in the first message is NOT permission to skip this):
• If more than 3 contexts appear above, FIRST print one short prose line naming the overflow (every listed context except the 3 you'll show as options), since those aren't in the picker; the user selects one by typing its slug into the built-in Other field.
• Then call AskUserQuestion: ONE question, multiSelect false, header "Task ctx", question "Which task context for this session?". Options (the tool caps at 4): the 3 MOST-RECENT contexts above (label = slug, description = its "Nd · scope"), plus a final "None" option ("work without a task context"). Any other or older context, or a brand-new one, the user types as a slug via Other.
• Act on the answer. A slug whose file exists → Read ~/.local/share/claude-contexts/<slug>.md (auto-resolves the gate; treat it as ground truth for prior work and do not re-derive it). A slug with no file yet → create it from the /ctx skeleton (now active). "None" → Write an empty file at ~/.local/share/claude-contexts/.gates/<Session id above> to unblock.
WHILE working (context active): after each meaningful step, Edit the file: add new state AND fix/delete now-stale lines (prevents poisoning). N is future-only: fold finished steps into D/!/F and delete. Keep it dense and small (<~1KB): telegraphic, keys G/S/D/!/✗/F/N/Q (schema in /ctx). Reading and writing in ~/.local/share/claude-contexts/ is pre-authorized.'#
