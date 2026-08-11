# Keep the agent from authoring git commits. A feature commit must be surfaced to
# the user; the only commit the agent may run finishes a merge or rebase with
# git's default message. Fails open on any error.

def allow [] { exit 0 }

def deny [reason: string] {
  { hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason } } | to json | print
  exit 0
}

let parsed = (try { open --raw /dev/stdin | from json } catch { null })
let input = (if (($parsed | describe) | str starts-with "record") { $parsed } else { null })
if $input == null { allow }

let cmd = ($input.tool_input?.command? | default "")
if $cmd == "" { allow }

# A commit that writes its own message: a feature commit, or a merge/rebase
# finished with a hand-written message. A bare `git commit` is left alone; off a
# merge or rebase it carries no message and aborts on its own.
let writes_commit = (($cmd =~ '(^|\s)git\s([^|;&]*\s)?commit(\s|$)') and ($cmd =~ '(^|\s)(-[a-zA-Z]*[mcCF]|--message|--file|--reuse-message|--reedit-message|--amend|--fixup|--squash|-e|--edit)(\s|=|$)'))
if $writes_commit {
  deny "Do not run this commit. When shipping a feature, leave the work unstaged and surface the commit to the user: show them the diff and a proposed message and let them run it. The only commit you may run yourself finishes a merge or rebase with git's default message (a bare git commit, no -m)."
}

# A merge or rebase whose message you wrote yourself.
let writes_merge = (($cmd =~ '(^|\s)git\s([^|;&]*\s)?(merge|rebase)(\s|$)') and ($cmd =~ '(^|\s)(-m|--message|-e|--edit|--reword)(\s|=|$)'))
if $writes_merge {
  deny "Do not hand-write the merge or rebase message. Run it with git's default message so the commit message is not one you authored."
}

allow
