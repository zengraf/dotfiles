# After an edit that adds comment lines, ask the agent to re-review them against
# the CLAUDE.md comment rules — a reminder in both directions, not a gate.
# Fails open on any error.

def quiet [] { exit 0 }

let parsed = (try { open --raw /dev/stdin | from json } catch { null })
let input = (if (($parsed | describe) | str starts-with "record") { $parsed } else { null })
if $input == null { quiet }

let path = ($input.tool_input?.file_path? | default "")
if $path == "" { quiet }

let ext = ($path | path parse | get extension | str lowercase)
let name = ($path | path basename | str lowercase)

let slash = ["rs" "ts" "tsx" "js" "jsx" "mjs" "cjs" "c" "h" "cc" "cpp" "hpp" "java" "go" "swift" "kt" "kts" "scala" "cs" "dart" "zig" "proto" "php" "vue" "svelte"]
let hash = ["py" "nu" "sh" "bash" "zsh" "fish" "nix" "rb" "yml" "yaml" "toml" "tf" "pl" "r" "just" "mk" "cmake" "gd" "ex" "exs"]
let dash = ["lua" "sql" "hs" "elm"]

# Unknown file types stay silent: a wrong nudge is worse than a missed one,
# because noise teaches the agent to ignore the hook.
let base = (
  if $ext in $slash { ["//" "/*"] }
  else if $ext in $hash { ["#"] }
  else if $ext in $dash { ["--"] }
  else if $name in ["makefile" "gnumakefile" "dockerfile" "justfile"] { ["#"] }
  else { [] }
)
let prefixes = (if $ext == "py" { $base ++ ['"""' "'''"] } else { $base })
if ($prefixes | is-empty) { quiet }

# Only line-start markers count. Trailing comments are skipped deliberately:
# `https://` and `#` inside string literals false-positive there.
def count-comment-lines [text: string, prefixes: list<string>] {
  $text | lines | where {|line|
    let t = ($line | str trim)
    ($prefixes | any {|p| $t | str starts-with $p }) and (not ($t | str starts-with "#!"))
  } | length
}

let tool = ($input.tool_name? | default "")
let added = (if $tool == "Edit" {
  (count-comment-lines ($input.tool_input?.new_string? | default "") $prefixes) - (count-comment-lines ($input.tool_input?.old_string? | default "") $prefixes)
} else {
  count-comment-lines ($input.tool_input?.content? | default "") $prefixes
})
if $added <= 0 { quiet }

let noun = (if $added == 1 { "comment line" } else { "comment lines" })
{
  hookSpecificOutput: {
    hookEventName: "PostToolUse"
    additionalContext: $"What you just wrote to ($path | path basename) carries ($added) ($noun). Re-check each new comment against the comment rules: it stays only if it marks a deliberate absence or names the mechanism that breaks the obvious alternative; it goes if it restates the code, narrates steps, or describes a type or signature. Keep the ones that pass — this is a review, not a ban."
  }
} | to json | print
exit 0
