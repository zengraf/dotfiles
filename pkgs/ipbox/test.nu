use std/assert
use lib.nu *

let r = (month-range 2026-10)
assert equal $r {start: '2026-10-01', end: '2026-10-31'}
assert equal (month-range 2026-12) {start: '2026-12-01', end: '2026-12-31'}
assert equal (month-range 2028-02).end '2028-02-29'
assert error { month-range 2026-13 }
assert error { month-range october }

assert equal (ticket-id 'Add export' 'Closes MAR2-1476, uses SHA-256' 'hlib/mar2-1476-export') MAR2-1476
assert equal (ticket-id 'UTF-8 fix' 'CRC-16/XMODEM and RS-232' 'main') null

assert equal (patch-name 7 widget 'Add CSV export: v2 (draft)') '007_widget_add-csv-export-v2-draft.patch'
assert (is-thin 'short')
assert not (is-thin ((1..50 | each { 'word' }) | str join ' '))

def cls [title: string, labels: list<string> = [], files: list<string> = []] {
  classify {title: $title, labels: $labels, files: $files}
}
assert equal (cls 'Add CSV export' [] [src/export.rs]) {class: rd, reason: feature}
assert equal (cls 'Revert "Add CSV export"') {class: non-rd, reason: revert}
assert equal (cls 'Bump rack to 3.1.2' [dependencies]) {class: non-rd, reason: deps}
assert equal (cls 'Update lockfile' [] [Cargo.lock]) {class: non-rd, reason: deps}
assert equal (cls 'Upgrade Node to v22' [] [.tool-versions Dockerfile]) {class: non-rd, reason: deps}
assert equal (cls 'chore: tidy imports') {class: non-rd, reason: chore}
assert equal (cls 'ci: cache gems' [] [.github/workflows/ci.yml]) {class: non-rd, reason: ci}
assert equal (cls 'Pin runner image' [] [.github/workflows/ci.yml]) {class: non-rd, reason: ci}
assert equal (cls 'docs: explain retries' [] [README.md docs/retries.md]) {class: non-rd, reason: docs}
assert equal (cls 'style: run prettier') {class: non-rd, reason: style}
assert equal (cls 'fix(export): handle empty rows' [] [src/export.rs]) {class: review, reason: bugfix}
assert equal (cls 'Handle empty rows' [bug] [src/export.rs]) {class: review, reason: bugfix}

# End-to-end against a fake gh on PATH.
let tmp = (mktemp -d)
let bin = ($tmp | path join bin)
let fixtures = ($tmp | path join fixtures)
mkdir $bin $fixtures

[{url: 'https://github.com/acme/widget/pull/7'}] | to json | save ($fixtures | path join search.json)
{
  url: 'https://github.com/acme/widget/pull/7'
  number: 7
  title: 'Add CSV export'
  body: 'Implements MAR2-12.'
  mergedAt: '2026-10-05T10:00:00Z'
  headRefOid: 'abc123'
  headRefName: 'hlib/csv-export'
  mergeCommit: {oid: 'def456'}
  author: {login: zengraf}
  labels: [{name: feature}]
  commits: [{oid: 'abc123', messageHeadline: 'Add CSV export'}]
  files: [{path: 'src/export.rs'}]
  additions: 120
  deletions: 3
  reviews: [{state: APPROVED}]
} | to json | save ($fixtures | path join view.json)
"From abc123 Mon Sep 17 00:00:00 2001\nSubject: [PATCH] Add CSV export\n" | save ($fixtures | path join pr.patch)

$"#!/bin/sh
echo \"$@\" >> ($tmp)/calls
case \"$1 $2\" in
  'search prs')
    case \"$@\" in
      *'--owner acme '*) cat ($fixtures)/search.json ;;
      *'--owner sso '*) echo 'Access to the requested organization sso is blocked by SAML single sign-on.' >&2; exit 1 ;;
      *) echo '[]' ;;
    esac ;;
  'pr view') cat ($fixtures)/view.json ;;
  'api repos/acme/widget/pulls/7') cat ($fixtures)/pr.patch ;;
  *) echo \"unexpected gh $@\" >&2; exit 1 ;;
esac
" | save ($bin | path join gh)
^chmod +x ($bin | path join gh)

let script = ($env.FILE_PWD | path join ipbox-fetch.nu)
let out = ($tmp | path join 2026-10)
def --wrapped fetch [...args] {
  do { $env.PATH = ($env.PATH | prepend $bin); ^$nu.current-exe --no-config-file --no-std-lib --include-path $env.FILE_PWD $script ...$args } | complete
}

let r = (fetch fetch 2026-10 $out)
assert equal $r.exit_code 1
assert str contains $r.stderr 'at least one GitHub org'

let r = (fetch fetch 2026-10 $out acme sso)
assert equal $r.exit_code 1
assert str contains $r.stderr 'gh search in sso failed'
assert str contains $r.stderr 'blocked by SAML'

let r = (fetch fetch 2026-10 $out acme other)
assert equal $r.exit_code 0 $r.stderr
let calls = (open ($tmp | path join calls))
assert str contains $calls 'search prs --owner acme --author @me --merged --merged-at 2026-10-01..2026-10-31'
assert str contains $calls 'search prs --owner other --author @me'

let rows = (open ($out | path join prs.json))
assert equal ($rows | length) 1
let row = $rows.0
assert equal $row.repo acme/widget
assert equal $row.ticket MAR2-12
assert equal $row.class rd
assert equal $row.merge_sha def456
assert equal $row.thin true
assert equal $row.patch 'patches/001_widget_add-csv-export.patch'
assert str contains (open --raw ($out | path join $row.patch)) 'Subject: [PATCH] Add CSV export'

"month,url\n" | save ($out | path join log.csv)
let r = (fetch fetch 2026-10 $out acme)
assert equal $r.exit_code 0 $r.stderr
assert equal (open --raw ($out | path join log.csv)) "month,url\n"

let r = (fetch sums $out)
assert equal $r.exit_code 0 $r.stderr
let sums = (open --raw ($out | path join SHA256SUMS))
assert str contains $sums '  patches/001_widget_add-csv-export.patch'
assert str contains $sums '  log.csv'
assert not ($sums | str contains SHA256SUMS)
assert equal ($sums | lines | length) 3

rm -rf $tmp
