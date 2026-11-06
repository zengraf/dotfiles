# Acronyms that look like ticket keys. SHA-256 and UTF-8 appear in PR bodies.
const not_tickets = [UTF SHA MD5 CRC HMAC ISO RFC IEEE CVE PKCS HTTP HTTPS TLS SSL RSA AES RS EIA USB PCI IPV ES X]

const lockfiles = [package-lock.json yarn.lock pnpm-lock.yaml Gemfile.lock Cargo.lock flake.lock poetry.lock uv.lock go.sum composer.lock mix.lock]

export def month-range [month: string] {
  let m = ($month | parse --regex '^(?<y>\d{4})-(?<m>\d{2})$' | get 0?)
  if $m == null { error make {msg: $"month must be YYYY-MM, got ($month)"} }
  let y = ($m.y | into int)
  let mo = ($m.m | into int)
  if $mo < 1 or $mo > 12 { error make {msg: $"month out of range: ($month)"} }
  let next = (if $mo == 12 { {y: ($y + 1), m: 1} } else { {y: $y, m: ($mo + 1)} })
  let next_start = $"($next.y)-($next.m | fill --alignment right --character '0' --width 2)-01"
  {start: $"($month)-01", end: (($next_start | into datetime) - 1day | format date '%Y-%m-%d')}
}

export def ticket-id [...texts: string] {
  $texts | str join "\n"
  | parse --regex '(?<id>\b[A-Z][A-Z0-9]{1,9}-\d+\b)'
  | get id
  | where { ($in | split row '-' | first) not-in $not_tickets }
  | get 0?
}

export def slug [] {
  str lowercase | str replace --all --regex '[^a-z0-9]+' '-' | str trim --char '-'
}

export def patch-name [idx: int, repo: string, title: string] {
  let n = ($idx | fill --alignment right --character '0' --width 3)
  $"($n)_($repo | slug)_($title | slug | str substring 0..<60 | str trim --char '-').patch"
}

export def is-thin [body: string] {
  ($body | split words | length) < 40
}

def config-path [] {
  $in =~ '^(\.github/|\.gitlab-ci|\.circleci/|Dockerfile|\.dockerignore|\.editorconfig|\.prettierrc|\.eslintrc|\.rubocop|\.gitignore|\.tool-versions|renovate\.json|dependabot\.yml)'
}

def doc-path [] {
  $in =~ '(?i)(^docs?/|\.md$|^LICENSE|^CHANGELOG)'
}

# Returns {class: rd | non-rd | review, reason}. `review` means the heuristic
# cannot tell routine from design work. The model and the user decide.
export def classify [pr: record] {
  let title = $pr.title
  let labels = ($pr.labels | each { str lowercase })
  let files = $pr.files
  let prefix = ($title | parse --regex '^(?<t>chore|build|ci|style|docs|deps|test|fix|revert)(\(.*?\))?!?:' | get t.0?)
  let lock_only = ($files | is-not-empty) and ($files | all { ($in | path basename) in $lockfiles })
  let config_only = ($files | is-not-empty) and ($files | all { ($in | config-path) or (($in | path basename) in $lockfiles) })
  let docs_only = ($files | is-not-empty) and ($files | all { $in | doc-path })

  if ($title =~ '(?i)^revert\b') or $prefix == revert { return {class: non-rd, reason: revert} }
  if ($labels | any { $in in [dependencies deps dependabot renovate] }) or $lock_only { return {class: non-rd, reason: deps} }
  if ($title =~ '(?i)\b(bump|upgrade|update)\b.*(\bdependenc|\bversion\b|\bto v?\d)') { return {class: non-rd, reason: deps} }
  if $prefix in [chore build test] or ($labels | any { $in in [chore maintenance] }) { return {class: non-rd, reason: chore} }
  if $prefix == ci or $config_only or ($labels | any { $in in [ci infrastructure] }) { return {class: non-rd, reason: ci} }
  if $prefix == style { return {class: non-rd, reason: style} }
  if $prefix == docs or $docs_only or ($labels | any { $in in [documentation docs] }) { return {class: non-rd, reason: docs} }
  if $prefix == fix or ($title =~ '(?i)^(fix|hotfix|bugfix)\b') or ($labels | any { $in in [bug bugfix] }) { return {class: review, reason: bugfix} }
  {class: rd, reason: feature}
}
