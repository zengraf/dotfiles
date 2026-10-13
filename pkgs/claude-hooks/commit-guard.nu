# Keep the agent from authoring git commits. A feature commit must be surfaced to
# the user; the only commit the agent may run finishes a merge or rebase with
# git's default message.

def deny [reason: string] {
  { hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason }
}

export def main [input: record] {
  if ($input.tool_name? | default "") != "Bash" { return null }
  let cmd = ($input.tool_input?.command? | default "")
  if $cmd == "" { return null }

  # A commit that writes its own message: a feature commit, or a merge/rebase
  # finished with a hand-written message. A bare `git commit` is left alone; off a
  # merge or rebase it carries no message and aborts on its own.
  let writes_commit = (($cmd =~ '(^|\s)git\s([^|;&]*\s)?commit(\s|$)') and ($cmd =~ '(^|\s)(-[a-zA-Z]*[mcCF]|--message|--file|--reuse-message|--reedit-message|--amend|--fixup|--squash|-e|--edit)(\s|=|$)'))
  if $writes_commit {
    return (deny "Do not run this commit. When shipping a feature, leave the work unstaged and surface the commit to the user: show them the diff and a proposed message and let them run it. The only commit you may run yourself finishes a merge or rebase with git's default message (a bare git commit, no -m).")
  }

  # A merge or rebase whose message you wrote yourself.
  let writes_merge = (($cmd =~ '(^|\s)git\s([^|;&]*\s)?(merge|rebase)(\s|$)') and ($cmd =~ '(^|\s)(-m|--message|-e|--edit|--reword)(\s|=|$)'))
  if $writes_merge {
    return (deny "Do not hand-write the merge or rebase message. Run it with git's default message so the commit message is not one you authored.")
  }

  null
}
