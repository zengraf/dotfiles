def secret [name: string] {
  age -d -i ($env.HOME | path join ".config/age/se.txt") (
    $env.CACHE_SECRETS | path join $"($name).age"
  ) | str trim
}

def main [...paths: string] {
  if ($paths | is-empty) {
    print -e "usage: cache-push <store-path|out-link>..."
    print -e "  e.g. cache-push (nix build --no-link --print-out-paths .#nomad-image)"
    exit 2
  }

  let resolved = ($paths | each {|p| $p | path expand })
  let r2 = (secret "r2" | from json)

  # /dev/stdin keeps the key out of a temp file; on APFS, deletion is not erasure.
  secret "cache-key" | nix store sign --key-file /dev/stdin --recursive ...$resolved

  # Republishing what upstream already serves costs storage for nothing.
  let ours = (
    nix path-info --recursive ...$resolved
    | lines
    | par-each {|p|
      if (nix path-info --store $env.CACHE_UPSTREAM $p | complete).exit_code != 0 { $p }
    }
    | compact
  )

  if ($ours | is-empty) {
    print "everything is already on upstream; nothing to push"
    return
  }

  print $"pushing ($ours | length) path\(s\) not served by ($env.CACHE_UPSTREAM)"
  nix store verify --sigs-needed 1 --trusted-public-keys $env.CACHE_PUBLIC_KEY ...$ours

  with-env {
    AWS_ACCESS_KEY_ID: $r2.access_key_id
    AWS_SECRET_ACCESS_KEY: $r2.secret_access_key
  } {
    let target = $"s3://($r2.bucket)?endpoint=($r2.account_id).r2.cloudflarestorage.com&region=auto"
    nix copy --to $target ...$ours
  }
}
