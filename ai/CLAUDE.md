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

# Code comments

Default to no comments. Add one only when the code cannot speak for itself.

- A comment explains *why*, never *what*. If it restates the code, delete it.
- When one is genuinely needed, write the shortest phrase that carries the insight.
- No banner/section headers, no narration of steps, no restating types or signatures.

# Working style

- Be terse and direct. No preamble, no flattery, no summaries of what I can already see.
- Say what's actually true: if something failed, is unverified, or was skipped, state it plainly.
- Match the surrounding code's naming, structure, and idiom — don't impose a different style.

# Git

Never run `git commit` when shipping a feature or any code change. Stage the work, show me the diff and a proposed message, and let me commit it myself.

The one exception is a commit that finishes a merge or rebase, and only with git's default message: a bare `git commit`, or `git merge`/`git rebase` with no message flag. Never author or edit the message yourself. A PreToolUse hook enforces this.
