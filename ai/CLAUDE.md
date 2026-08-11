# Code comments

**Default to zero comments.** Leave code uncommented unless it is genuinely ambiguous or hard to follow.

- When one is truly warranted, write one short line giving the single reason the code is unconventional.
- Never write history, alternatives weighed, or the decision trail — that belongs in the commit message or PR body.
- Delete anything that restates the code, narrates steps, or explains a type or signature. No banner or section headers.

# Skills

When I type one of these triggers, invoke the matching skill via the Skill tool FIRST — before any other tool call or reply:

- **`/implement`** — fetch a Linear ticket, create a branch, assess scope, produce a plan in native Plan Mode.
- **`/deep-review`** — review a PR branch with GitHub + Linear context; output critical issues and nitpicks.
- **`/ctx`** — load, create, or switch the active task context (dense persistent memory; first-turn picker each session).

# Code navigation

Prefer the LSP tool over grep for symbol questions. It's a deferred tool — load it first with `ToolSearch("select:LSP")`.

- `hover` for a resolved type or signature. `goToDefinition` / `findReferences` for the symbol graph. `documentSymbol` to outline a file. `incomingCalls` / `outgoingCalls` for call hierarchy.
- Servers are configured for ts, py, rs, nix, and nu. The first call after a cold start can fail with `server is starting` — retry once, don't give up and fall back to grep.
- `line` and `character` are both 1-based. An off-by-one lands on whitespace and reports "no definition found".
- Still grep for what LSP excludes by design: comments, string keys (`vi.mock`), and generated artifacts. A rename needs both.

# Working style

- Be terse and direct. No preamble, no flattery, no summaries of what I can already see.
- Say what's actually true: if something failed, is unverified, or was skipped, state it plainly.
- Match the surrounding code's naming, structure, and idiom — but never its comment density. Existing comments are not evidence that new code needs any; the zero-comment default applies in every file.

# Git

Never run `git commit` when shipping a feature or any code change. Leave the work unstaged, show me the diff and a proposed message, and let me commit it myself.

Never change what's staged: no `git add`, `reset`, `restore`, `stash`, or `checkout -- <file>` unless I explicitly ask. Staged-vs-unstaged is how I track review — I stage each file as I finish reviewing it, so staging destroys the marker and unstaging silently re-opens files I've signed off on.

The exception is finishing a merge or rebase: stage the conflict resolutions, then commit only with git's default message — a bare `git commit`, or `git merge`/`git rebase` with no message flag. Never author or edit a commit message yourself. A PreToolUse hook enforces this.
