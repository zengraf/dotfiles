# Code comments

**Default: no comment.** Anything derivable from the code is noise: restatements, step narration, explanations of a type or signature, banner and section headers. If reading further in the file answers it, leave the code bare.

**Keep what the code cannot say.** These earn one or two lines, because nothing in the file recovers them:

- Why an absence (a field not added, a check not performed, an empty value, a lone enum variant, an unreachable branch) is deliberate. Absence leaves no trace, so the next reader takes it for unfinished work and fixes it.
- Why the obvious alternative is wrong, when taking it would be a silent bug and not just a difference in taste. State the constraint that still holds and name the upstream bug or spec clause that forces it; a link may back that up but cannot be the whole comment. The deliberation ("we considered X") belongs in the commit message.

Anything not covered above gets one test: without the comment, would the next editor make a plausible edit that regresses? If it doesn't clearly pass, delete it.

Write them in the present tense: describe the code as it stands, not the change that produced it.

Doc comments on a crate's public API are documentation, not commentary, and so are `--help` strings, NixOS option descriptions, and anything else a user reads at runtime. Trim those to what a caller needs; never strip them.

# Code navigation

Prefer the LSP tool over grep for symbol questions. It's a deferred tool — load it first with `ToolSearch("select:LSP")`.

- `hover` for a resolved type or signature. `goToDefinition` / `findReferences` for the symbol graph. `documentSymbol` to outline a file. `incomingCalls` / `outgoingCalls` for call hierarchy.
- Servers are configured for ts, py, rs, nix, and nu. The first call after a cold start can fail with `server is starting` — retry once, don't give up and fall back to grep.
- `line` and `character` are both 1-based. An off-by-one lands on whitespace and reports "no definition found".
- Still grep for what LSP excludes by design: comments, string keys (`vi.mock`), and generated artifacts. A rename needs both.

# Working style

- Be terse and direct. No preamble, no flattery, no summaries of what I can already see.
- Say what's actually true: if something failed, is unverified, or was skipped, state it plainly.
- Match the surrounding code's naming, structure, and idiom — but never its comment density. Existing comments are not evidence that new code needs any; apply the test above in every file.

# Git

Never run `git commit` when shipping a feature or any code change. Leave the work unstaged, show me the diff and a proposed message, and let me commit it myself.

Never change what's staged: no `git add`, `reset`, `restore`, `stash`, or `checkout -- <file>` unless I explicitly ask. Staged-vs-unstaged is how I track review — I stage each file as I finish reviewing it, so staging destroys the marker and unstaging silently re-opens files I've signed off on.

The exception is finishing a merge or rebase: stage the conflict resolutions, then commit only with git's default message — a bare `git commit`, or `git merge`/`git rebase` with no message flag. Never author or edit a commit message yourself; a PreToolUse hook blocks commits that carry one. The staging rules above have no hook behind them.
