# Code comments

My code is read by experienced engineers, so the default is no comment: anything the code already shows — a restated line, narrated steps, a described type or signature, a banner header — is noise to them. Only two kinds of knowledge earn a comment, because they live nowhere in the file:

- A deliberate absence: a field not added, a check not performed, an empty value, a lone enum variant. Absence reads as unfinished work, so without the comment the next editor "completes" it.
- A trap: the obvious alternative also works, until it silently breaks. Name the mechanism that fails (a syscall, an error message, an upstream bug, a spec clause); a rationale with no nameable mechanism is taste, and taste gets no comment.

Delete: `// Loop through users and mark stale ones inactive` — the next three lines say this.
Keep: `// Stripe retries webhooks for 72h; dedupe on event id or refunds double-process.` — nothing in the file recovers it.

When a case is borderline, one test decides: without the comment, would the next editor plausibly make an edit that regresses? If yes, write one or two lines in the present tense, describing the code as it stands rather than the change that produced it. If no, put the insight in the proposed commit message or your reply instead.

Don't add comments, docstrings, or type annotations to code you didn't change.

Doc comments are documentation, not commentary, only where the reader never opens the source: an API another project consumes, `--help` strings, NixOS option descriptions. Visibility isn't that test — a `pub fn` in a workspace-internal crate is plumbing, and the rules above apply to it unchanged. Trim documentation to what a caller needs; never strip it.

# Code navigation

Prefer the LSP tool over grep for symbol questions. It's a deferred tool — load it first with `ToolSearch("select:LSP")`.

- `hover` for a resolved type or signature. `goToDefinition` / `findReferences` for the symbol graph. `documentSymbol` to outline a file. `incomingCalls` / `outgoingCalls` for call hierarchy.
- Servers are configured for ts, py, rs, nix, and nu. The first call after a cold start can fail with `server is starting` — retry once, don't give up and fall back to grep.
- `line` and `character` are both 1-based. An off-by-one lands on whitespace and reports "no definition found".
- Still grep for what LSP excludes by design: comments, string keys (`vi.mock`), and generated artifacts. A rename needs both.

# Working style

- Be terse and direct. No preamble, no flattery, no summaries of what I can already see.
- Say what's actually true: if something failed, is unverified, or was skipped, state it plainly.
- Match the surrounding code's naming, structure, and idiom — but never its comment density. A file where every function is already documented is not a norm to match; the comment rules apply there unchanged.

# Git

Never run `git commit` when shipping a feature or any code change. Leave the work unstaged, show me the diff and a proposed message, and let me commit it myself.

Never change what's staged: no `git add`, `reset`, `restore`, `stash`, or `checkout -- <file>` unless I explicitly ask. Staged-vs-unstaged is how I track review — I stage each file as I finish reviewing it, so staging destroys the marker and unstaging silently re-opens files I've signed off on.

The exception is finishing a merge or rebase: stage the conflict resolutions, then commit only with git's default message — a bare `git commit`, or `git merge`/`git rebase` with no message flag. Never author or edit a commit message yourself; a PreToolUse hook blocks commits that carry one. The staging rules above have no hook behind them.

# Skills

## Grilling

Use `AskUserQuestion` with examples whenever a turn asks me to choose — including inside a skill whose own instructions prescribe a prose output format. Prose and the tool call are complements: the prose carries the argument, the tool carries the decision.
