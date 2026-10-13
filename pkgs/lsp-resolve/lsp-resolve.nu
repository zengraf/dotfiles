# The JSON keeps the build sandbox's values (HOME=/homeless-shelter, a TMPDIR
# under /nix/var). nix develop drops these same names.
const sandbox = [BASHOPTS HOME NIX_BUILD_TOP NIX_ENFORCE_PURITY NIX_LOG_FD NIX_REMOTE PPID SHELL SHELLOPTS SSL_CERT_FILE TEMP TEMPDIR TERM TMP TMPDIR TZ UID]

# Zed joins a relative binary.path onto the worktree root exactly once, and the
# biome extension only reads package.json there. Neither finds a project install
# when the opened root is a subdirectory of the package. Zed spawns language
# servers with cwd at the worktree root, so a walk from $PWD does.
def ancestors [] {
  generate {|d| if $d != '/' { {out: $d, next: ($d | path dirname)} } } $env.PWD
}

# load_direnv reads only .envrc, so in a devenv project without one Zed starts
# servers with none of its toolchain. print-dev-env is unlisted in
# `devenv --help`. It skips enterShell, so variables that only a shell hook
# exports never reach the server.
def devenv-vars [root: string, name: string] {
  # Without the empty pipe devenv inherits stdin, which is the LSP stream.
  let out = (do { cd $root; "" | ^@devenv@ print-dev-env --json } | complete)
  if $out.exit_code != 0 {
    print -e $"($name): devenv in ($root) failed to evaluate, starting without its environment"
    return {}
  }
  $out.stdout | from json | get variables | transpose k v
  | where v.type == exported and k not-in $sandbox
  | each {|r| {$r.k: $r.v.value} } | into record
}

def --wrapped main [spec: path, ...args] {
  let spec = (open $spec)
  let env_vars = ($spec.env? | default {} | items {|k, v|
    {$k: (if ($v | str starts-with '~') { $v | path expand --no-symlink } else { $v })}
  } | into record)
  load-env $env_vars

  for d in (ancestors) {
    for c in ($spec.project? | default []) {
      let bin = ($d | path join $c.path)
      if ($bin | path exists) { exec $bin ...($c.args? | default []) ...$args }
    }
  }

  if ($spec.devenv? | default false) {
    let root = (ancestors | where { $in | path join devenv.nix | path exists } | get 0?)
    if $root != null {
      let vars = (devenv-vars $root $spec.name | reject --optional ...($env_vars | columns))
      if ($vars | is-not-empty) {
        load-env ($vars | upsert PATH $"($vars.PATH? | default ''):($env.PATH | str join (char esep))")
        if 'DEVENV_PROFILE' in $env {
          let own = ($env.DEVENV_PROFILE | path join bin $spec.name)
          if ($own | path exists) { exec $own ...$args }
        }
      }
    }
  }

  if $spec.fallback? == null {
    print -e $"($spec.name): no project install in any ancestor of ($env.PWD)"
    exit 1
  }
  exec $spec.fallback.command ...($spec.fallback.args? | default []) ...$args
}
