# `name` is a path under the secrets root, without the .age suffix: "nomad/vultr",
# or "r2", which sits above nomad because one bucket serves both the cache and the
# disk images.
#
# Falling back to the checkout keeps the CLI runnable from source, not only when
# packaged.
const CHECKOUT = (path self | path dirname | path join ".." ".." "secrets")

def root [] {
  $env.NOMAD_SECRETS? | default $CHECKOUT
}

# The router reads what agenix decrypted for it, since a systemd timer cannot
# answer a biometric prompt. agenix flattens paths, hence the basename.
export def get [name: string] {
  let plain = ($env.NOMAD_SECRETS_PLAIN? | default "")
  if $plain != "" {
    open --raw ($plain | path join ($name | path basename)) | str trim
  } else {
    age -d -i ($env.HOME | path join ".config/age/se.txt") (
      (root) | path join $"($name).age"
    ) | str trim
  }
}

export def get-json [name: string] {
  get $name | from json
}

# Absence means unconfigured. A file that exists but fails to decrypt still
# raises, so a transient fault cannot silently skip a backend with live instances.
export def exists [name: string] {
  let plain = ($env.NOMAD_SECRETS_PLAIN? | default "")
  if $plain != "" {
    ($plain | path join ($name | path basename)) | path exists
  } else {
    ((root) | path join $"($name).age") | path exists
  }
}
