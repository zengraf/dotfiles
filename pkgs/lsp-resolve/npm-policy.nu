def --wrapped main [spec: path, ...args] {
  let spec = (open $spec)
  if ($args | any {|a| $spec.allow | any {|p| $a has $p } }) { exec $spec.npm ...$args }
  print -e $"npm denied: ($args | str join ' ') — pin this server with lsp.<id>.binary.path"
  exit 1
}
