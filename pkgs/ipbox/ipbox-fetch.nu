use lib.nu *

const view_fields = 'additions,author,body,commits,deletions,files,headRefName,headRefOid,labels,mergeCommit,mergedAt,number,reviews,title,url'

def main [] { help main }

# One search per org. A single query over several owners fails as a whole when
# one org sits behind SAML SSO that the token does not satisfy.
def search [org: string, range: record] {
  let r = (^gh search prs --owner $org --author '@me' --merged --merged-at $"($range.start)..($range.end)" --limit 500 --json url | complete)
  if $r.exit_code != 0 {
    error make --unspanned {msg: $"gh search in ($org) failed:\n($r.stderr | str trim)"}
  }
  $r.stdout | from json
}

# Fetch the PRs merged by @me in <orgs> during <month> into <out>/prs.json and
# <out>/patches/. Files the model writes (log.csv, narratives.md, invoice.txt)
# stay untouched on a re-run.
def "main fetch" [month: string, out: path, ...orgs: string] {
  if ($orgs | is-empty) { error make --unspanned {msg: "give at least one GitHub org"} }
  let range = (month-range $month)
  let found = ($orgs | each {|o| search $o $range } | flatten)
  let prs = ($found | each {|p| ^gh pr view $p.url --json $view_fields | from json } | sort-by mergedAt)

  let patches = ($out | path join patches)
  rm -rf $patches
  mkdir $patches

  let rows = ($prs | enumerate | each {|e|
    let pr = $e.item
    let repo = ($pr.url | parse --regex 'github\.com/(?<owner>[^/]+)/(?<name>[^/]+)/pull/' | get 0)
    let patch = (patch-name ($e.index + 1) $repo.name $pr.title)
    ^gh api $"repos/($repo.owner)/($repo.name)/pulls/($pr.number)" -H 'Accept: application/vnd.github.v3.patch'
    | save --raw -f ($patches | path join $patch)
    let body = ($pr.body | default '')
    let files = ($pr.files | get path)
    let labels = ($pr.labels | get name)
    let c = (classify {title: $pr.title, labels: $labels, files: $files})
    {
      url: $pr.url
      repo: $"($repo.owner)/($repo.name)"
      number: $pr.number
      title: $pr.title
      merged_at: $pr.mergedAt
      head_sha: $pr.headRefOid
      merge_sha: $pr.mergeCommit.oid?
      branch: $pr.headRefName
      author: $pr.author.login
      labels: $labels
      ticket: (ticket-id $pr.title $body $pr.headRefName)
      commits: ($pr.commits | each {|c| {sha: $c.oid, message: $c.messageHeadline} })
      files: $files
      additions: $pr.additions
      deletions: $pr.deletions
      reviews: ($pr.reviews | length)
      thin: (is-thin $body)
      class: $c.class
      reason: $c.reason
      patch: $"patches/($patch)"
      body: $body
    }
  })

  $rows | to json --indent 2 | save -f ($out | path join prs.json)
  print $"($rows | length) PRs merged ($range.start)..($range.end) in ($orgs | str join ', ') → ($out | path join prs.json)"
  $rows | select number repo class reason ticket thin | table --theme none | print
}

# Hash every file under <dir> except SHA256SUMS itself.
def "main sums" [dir: path] {
  let lines = (
    glob ($dir | path join '**/*') --no-dir
    | where { ($in | path basename) != SHA256SUMS }
    | sort
    | each {|f| $"(open --raw $f | hash sha256)  ($f | path relative-to $dir)" }
  )
  $lines | str join "\n" | $"($in)\n" | save -f ($dir | path join SHA256SUMS)
  print $"($lines | length) files hashed into ($dir | path join SHA256SUMS)"
}
