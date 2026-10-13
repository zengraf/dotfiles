use std/assert

let out = (^$nu.current-exe --no-config-file hello.nu world | lines)
assert equal $out ["hello world" "0"]
