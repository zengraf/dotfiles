---
name: implement
description: "Fetch a Linear ticket, create a branch, assess scope, and produce an implementation plan"
disable-model-invocation: true
---

# /implement

Read a Linear ticket, set up the branch, and produce a thorough implementation plan.

Assumes the user has already created a worktree in Zed and started a new thread in it.

## Usage

```
/implement <ticket-number>
```

`<ticket-number>` is a Linear identifier, e.g. `MAR2-1476`.

## Workflow

### Step 1 — Fetch Linear context

Load the `linear-server` MCP tool schemas via ToolSearch first.

1. `mcp__linear-server__get_issue` with the identifier — returns description, status, assignee, labels, attachments, `gitBranchName`, and `parentId`
2. `mcp__linear-server__list_comments` with `issueId` — returns ticket discussion and inline comments
3. If `parentId` is present, fetch the parent issue with `mcp__linear-server__get_issue` for broader context

### Step 2 — Create the branch

```bash
git fetch origin main
git checkout -b <gitBranchName> --no-track origin/main
```

Use the `gitBranchName` returned by Linear in Step 1. The explicit `origin/main` base ensures the branch starts from the latest remote main, not from the worktree's detached HEAD. `--no-track` keeps the branch from adopting `origin/main` as its upstream — it starts with no tracking branch, so the first push sets its own remote.

### Step 3 — Assess scope

Based on the ticket description, comments, and parent context:

- Evaluate whether the work fits a single PR
- If the scope is clearly too large (multiple independent concerns, touches many unrelated subsystems), suggest a split into multiple PRs with a brief outline of each
- Default to a single PR — the user prefers this unless there's a strong reason to split
- If suggesting a split, wait for the user to confirm before proceeding

### Step 4 — Plan via grilling

1. Explore the codebase first — read CLAUDE.md, understand existing patterns, find related code, and confirm the scope assessment from Step 3. Facts are yours to find; only decisions go to the user.
2. Invoke the `grilling` skill over the implementation approach: map the design decisions as a tree and work the frontier in rounds. Per the global Grilling rule, prose carries each round's argument and `AskUserQuestion` carries the decisions.
3. When the frontier is empty, output the consolidated implementation plan as a chat message. Cover:
   - Which files to create/modify
   - The approach for each change, with enough detail that implementation is mechanical
   - Edge cases and gotchas from CLAUDE.md that apply
   - Migration or schema changes if needed
   - What does NOT need to change (to keep scope tight)
   - If a PR split is warranted (see Step 3), outline each PR
4. Wait for the user's explicit go-ahead on the plan.

### Important

- Do NOT start implementing before the user approves the plan.
- Do NOT create a worktree — the user does that in Zed before running this command.
- Read the project's CLAUDE.md before planning — conventions and gotchas matter.
