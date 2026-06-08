---
name: deep-review
description: "Review a PR branch written by another model — fetch PR + Linear ticket context, output critical issues and nitpicks"
trigger: /deep-review
---

# /deep-review

Review a pull request branch, gathering context from GitHub and Linear, then output critical issues and nitpicks.

## Usage

```
/deep-review <pr-number>
```

## Workflow

### Step 1 — Gather GitHub context

Use the `gh` CLI to fetch PR metadata and comments in parallel:

```bash
gh pr view <pr-number> --json title,body,baseRefName,headRefName,author,labels,comments,reviewRequests
gh pr diff <pr-number>
gh api repos/{owner}/{repo}/pulls/<pr-number>/comments   # inline review comments
gh api repos/{owner}/{repo}/pulls/<pr-number>/reviews     # review summaries
```

Then check out the branch locally:

```bash
gh pr checkout <pr-number>
```

### Step 2 — Extract and fetch the Linear ticket

Parse the PR title and body for a Linear ticket identifier (pattern: `MAR2-\d+` or similar project prefix).

Use the `linear-server` MCP tools (load schemas via ToolSearch first):

1. `mcp__linear-server__get_issue` with the identifier (e.g. `MAR2-1476`) — returns description, status, assignee, labels, attachments (linked PRs), and `parentId`
2. `mcp__linear-server__list_comments` with `issueId` — returns ticket discussion and inline comments
3. If `parentId` is present, fetch the parent issue with `mcp__linear-server__get_issue` for broader context

### Step 3 — Read the changed files

Read every file that appears in the PR diff. For large files, focus on the changed hunks and their surrounding context (50 lines above and below each hunk). Understand what each change does in the context of the codebase.

### Step 4 — Output

#### Summary

Output a brief (2–4 sentence) summary with two parts:
- **Ask**: What the ticket requested
- **Done**: What the PR actually implements

#### Review comments

Output comments as a numbered list. Each comment must follow these rules:

- 1–2 sentences
- Friendly tone
- Intended for a senior engineer with experience in this application
- Include the location as a clickable file link followed by a visual line reference: `[filename.ts](file:///absolute/path/to/filename.ts#L20) (20-35)`. The link uses `file:///` with `#L{start-line}` for navigation; the parenthesised range after it shows the reader which lines are quoted.
- Use the `—` sign for dash, `-` for hyphen. Try not to use dashes.
- Group into **Critical** (blocking issues: bugs, logic errors, missing edge cases, security) and **Nitpicks** (style, naming, minor improvements — 2–3 max)

#### Comment tone

Write like a senior colleague suggesting alternatives, not issuing commands:

- **"You can …" / "A better approach would be …"** — suggest, don't instruct. Never "you should", "please do", or "I think".
- **Acknowledge before redirecting** — if the code works but there's a cleaner path, say so: "This would ultimately work, but …"
- **Explain the benefit in the same sentence** — "You can move X to Y. That way Z wouldn't need …"
- **Terse is fine** — "You can do this in a single pass" is a complete comment.
- **No praise, no hedging, no filler** — skip "nice work", "I believe", "perhaps consider". Go straight to the point.
- **Escape hatches welcome** — when a suggestion is expensive, end with "but feel free to ignore if it requires a massive refactor" or similar.

Format each comment like this:

```
### Critical

1. [filename.ts](file:///absolute/path/to/filename.ts#L20) (20-35)
\`\`\`ts
// the relevant code snippet
\`\`\`
> Your comment here

### Nitpicks

1. [filename.ts](file:///absolute/path/to/filename.ts#L42) (42)
\`\`\`ts
// the relevant code snippet
\`\`\`
> Your comment here
```

### Important

- Do NOT run tests or builds — assume CI passes.
- Do NOT make any code changes — this is a read-only review.
- Read the project's CLAUDE.md for coding conventions and gotchas before commenting.
- If no critical issues are found, say so explicitly and only output nitpicks.
- Consult PR comments and Linear ticket comments — someone may have already flagged an issue or provided context that makes a change intentional.
