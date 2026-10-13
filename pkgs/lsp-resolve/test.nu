use std/assert

let resolve = ($env.FILE_PWD | path join lsp-resolve.nu)
let policy = ($env.FILE_PWD | path join npm-policy.nu)
let tmp = (mktemp -d)

def --wrapped invoke [script: string, cwd: string, ...args] {
  do { cd $cwd; ^$nu.current-exe --no-config-file --no-std-lib $script ...$args } | complete
}

def spec [record] {
  let f = (mktemp --tmpdir --suffix .json)
  $record | to json | save -f $f
  $f
}

mkdir ($tmp | path join pkg/node_modules/.bin) ($tmp | path join pkg/sub/deep)
let server = ($tmp | path join pkg/node_modules/.bin/server)
"#!/bin/sh\necho \"project $* $LOG_DIR $LEVEL\"\n" | save $server
^chmod +x $server

let fallback = {command: $nu.current-exe, args: [--no-config-file -c 'print $"fallback ($env.LEVEL? | default unset)"']}

let s = (spec {
  name: server
  env: {LOG_DIR: '~/logs', LEVEL: none}
  project: [{path: node_modules/.bin/missing, args: []} {path: node_modules/.bin/server, args: [lsp-proxy]}]
  fallback: $fallback
})
let r = (invoke $resolve ($tmp | path join pkg/sub/deep) $s --extra)
assert equal $r.exit_code 0
assert equal ($r.stdout | str trim) $"project lsp-proxy --extra ($env.HOME)/logs none"

let s = (spec {name: server, env: {LEVEL: kept}, project: [{path: nope, args: []}], devenv: true, fallback: $fallback})
let r = (invoke $resolve $tmp $s)
assert equal $r.exit_code 0
assert equal ($r.stdout | str trim) "fallback kept"

let s = (spec {name: server, project: [{path: nope, args: []}]})
let r = (invoke $resolve $tmp $s)
assert equal $r.exit_code 1
assert str contains $r.stderr "server: no project install in any ancestor of"

let s = (spec {npm: $nu.current-exe, allow: ['@github/copilot-language-server']})
let r = (invoke $policy $tmp $s install left-pad)
assert equal $r.exit_code 1
assert str contains $r.stderr "npm denied: install left-pad"

let r = (invoke $policy $tmp $s --no-config-file -c 'print allowed' '@github/copilot-language-server@1.0')
assert equal $r.exit_code 0
assert equal ($r.stdout | str trim) allowed

rm -rf $tmp
