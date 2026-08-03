# On the operator's Mac these are age files gated by the Secure Enclave: decrypted
# per invocation, held in this process, never written to disk. On the router the
# reaper reads what agenix already decrypted for it, since a systemd timer cannot
# answer a biometric prompt.
export def get [name: string] {
  let plain = ($env.NOMAD_SECRETS_PLAIN? | default "")
  if $plain != "" {
    open --raw ($plain | path join $"nomad-($name)") | str trim
  } else {
    age -d -i ($env.HOME | path join ".config/age/se.txt") (
      $env.NOMAD_SECRETS | path join $"nomad-($name).age"
    ) | str trim
  }
}

export def get-json [name: string] {
  get $name | from json
}
