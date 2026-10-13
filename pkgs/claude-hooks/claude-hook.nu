use contexts.nu [banner gate]
use commit-guard.nu
use comments.nu [comment-review]

def read-input [] {
  let parsed = (try { open --raw /dev/stdin | from json } catch { null })
  if (($parsed | describe) | str starts-with "record") { $parsed } else { null }
}

def emit [decision] {
  if $decision != null { { hookSpecificOutput: $decision } | to json | print }
}

def main [] { help main }

# Claude Code reports any non-zero exit as a hook error, so every error stays
# inside try and the hook fails open. The explicit exit skips Nu's engine
# teardown, which costs about 6 ms per call.
def "main session-start" [] {
  try { banner (read-input | default {}) }
  exit 0
}

def "main pre-tool-use" [] {
  try {
    let input = (read-input)
    if $input != null {
      let gated = (gate $input)
      emit (if $gated != null { $gated } else { commit-guard $input })
    }
  }
  exit 0
}

def "main post-tool-use" [] {
  try {
    let input = (read-input)
    if $input != null { emit (comment-review $input) }
  }
  exit 0
}
