use std/assert

$env.TEST_HOME = (mktemp -d)
let home = $env.TEST_HOME
let contexts = ($home | path join .local/share/claude-contexts)

def run-hook [sub: string, input, extra_env: record = {}] {
  let stdin = (if ($input | describe) == string { $input } else { $input | to json })
  let r = (do { $env.HOME = $env.TEST_HOME; load-env $extra_env; $stdin | ^$nu.current-exe --no-config-file --no-std-lib ($env.FILE_PWD | path join claude-hook.nu) $sub } | complete)
  assert equal $r.exit_code 0 $r.stderr
  if ($r.stdout | str trim) == "" { null } else if $sub == session-start { $r.stdout } else { $r.stdout | from json | get hookSpecificOutput }
}

def bash [cmd: string] { {session_id: s1, tool_name: Bash, tool_input: {command: $cmd}} }

mkdir $contexts
"# alpha · 2026-10-13 · scope: the alpha work\n" | save ($contexts | path join alpha.md)

let out = (run-hook session-start {session_id: s1})
assert str contains $out "Session id: s1"
assert str contains $out "  • alpha — 0d · the alpha work"
assert ($contexts | path join .gates | path exists)

let d = (run-hook pre-tool-use (bash ls))
assert equal $d.permissionDecision deny
assert str contains $d.permissionDecisionReason "Task-context gate unresolved"

assert equal (run-hook pre-tool-use {session_id: s1, tool_name: AskUserQuestion}) null

let d = (run-hook pre-tool-use {session_id: s1, tool_name: Read, tool_input: {file_path: ($contexts | path join alpha.md)}})
assert equal $d.permissionDecision allow
assert equal $d.permissionDecisionReason "ctx: context file"
assert ($contexts | path join .gates/s1 | path exists)

assert equal (run-hook pre-tool-use (bash ls)) null
assert equal (run-hook pre-tool-use (bash "git commit")) null
assert equal (run-hook pre-tool-use (bash "git commit -m 'x'")).permissionDecision deny
assert equal (run-hook pre-tool-use (bash "git merge --no-ff -m x main")).permissionDecision deny
assert equal (run-hook pre-tool-use {session_id: s1, tool_name: Write, tool_input: {file_path: /tmp/x, content: "git commit -m x"}}) null

let s2 = {session_id: s2, tool_name: Bash, tool_input: {command: "git commit -am x"}}
let s2_ls = ($s2 | update tool_input.command ls)
let gate_reason = (run-hook pre-tool-use $s2_ls).permissionDecisionReason
assert str contains $gate_reason "Task-context gate unresolved"
assert equal (run-hook pre-tool-use $s2).permissionDecisionReason $gate_reason
assert str contains (run-hook pre-tool-use $s2 {CLAUDE_CTX_SKIP: 1}).permissionDecisionReason "Do not run this commit"
assert equal (run-hook pre-tool-use $s2_ls {CLAUDE_CTX_SKIP: 1}) null

assert equal (run-hook pre-tool-use "not json") null
assert equal (run-hook post-tool-use "not json") null
assert str contains (run-hook session-start "not json") "Session id: unknown"

let d = (run-hook post-tool-use {tool_name: Write, tool_input: {file_path: /x/a.nu, content: "# one\nlet a = 1\n  # two\n#!/bin/sh\n"}})
assert equal $d.hookEventName PostToolUse
assert str contains $d.additionalContext "What you just wrote to a.nu carries 2 comment lines."
let d = (run-hook post-tool-use {tool_name: Edit, tool_input: {file_path: /x/a.rs, old_string: "// a", new_string: "// a\n// b"}})
assert str contains $d.additionalContext "carries 1 comment line."
assert equal (run-hook post-tool-use {tool_name: Write, tool_input: {file_path: /x/a.unknown, content: "# a"}}) null

rm -rf $home
