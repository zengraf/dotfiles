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

### Step 4 — Plan (in native Plan Mode)

`EnterPlanMode` and `ExitPlanMode` are Claude Code's **native Plan Mode** tools — load their schemas via ToolSearch first (same as the Linear tools in Step 1: `select:EnterPlanMode,ExitPlanMode`). Plan Mode is **read-only**: the harness blocks every edit/write until you exit, which is why the branch is created back in Step 2 (a write) *before* this step.

1. Call `EnterPlanMode` to transition into Plan Mode. This requires the user's consent to enter.
2. Explore the codebase thoroughly inside Plan Mode — read CLAUDE.md, understand existing patterns, find related code, and confirm the scope assessment from Step 3.
3. Write an implementation plan **to the plan file named in the Plan Mode system message**. Do NOT just print the plan as a chat message — `ExitPlanMode` reads the plan from that file. Cover:
   - Which files to create/modify
   - The approach for each change, with enough detail that implementation is mechanical
   - Edge cases and gotchas from CLAUDE.md that apply
   - Migration or schema changes if needed
   - What does NOT need to change (to keep scope tight)
   - If a PR split is warranted (see Step 3), outline each PR
4. Call `ExitPlanMode` to surface the plan file for approval.

### Important

- Use native Plan Mode for the plan — `EnterPlanMode`, write to the plan file, then `ExitPlanMode`. Don't substitute a plain chat message for the plan file.
- Do NOT start implementing before the plan is approved via `ExitPlanMode`.
- Do NOT create a worktree — the user does that in Zed before running this command.
- Read the project's CLAUDE.md before planning — conventions and gotchas matter.
