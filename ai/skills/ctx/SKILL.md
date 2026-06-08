---
name: ctx
description: "Load, create, or switch the active task context — a dense, persistent working-memory file in ~/.claude/contexts/ that makes resuming long tasks cheap and prevents context poisoning"
trigger: /ctx
---

# /ctx — task contexts

A **task context** is a single dense file holding the durable working memory of a task: goal, current state, decisions, corrections, file map, next steps. It lets a fresh session resume in a few hundred tokens instead of replaying a huge transcript, and it is edited in place so a later agent never inherits stale assumptions.

Contexts are **freeform** — one can span multiple tickets or repos. They live globally at `~/.claude/contexts/<slug>.md`. Reading and writing there is pre-authorized (no permission prompts).

A `SessionStart` hook already lists recent contexts and asks which to load at the start of each chat; this skill is the schema reference and gives explicit control.

## Usage

```
/ctx                 # list contexts (recent + stale)
/ctx <slug>          # load <slug>, make it the active context
/ctx new <slug>      # create ~/.claude/contexts/<slug>.md from the skeleton, make it active
/ctx none            # disable the protocol for this session
```

`<slug>` is kebab-case (`auth-refactor`, `q3-billing-spike`).

## Loading

`Read ~/.claude/contexts/<slug>.md` and treat it as ground truth for prior work — do not re-derive what it already records. If something in it contradicts what you now observe, the file is stale: fix it (see Maintenance).

## Schema

Single-letter section keys, one section per line, terse. Omit empty sections.

```
# <slug> · <date> · scope: <freeform — tickets / repos / "general">
G: <goal — one line>
S: <state — where things stand; clauses joined by ;>
D: <decisions — each "X not Y (why)">
✗: <corrections — wrong assumptions a future agent must NOT repeat>
F: <file map — path=role; path=role>
N: <next — ordered, terse>
Q: <open questions>
```

Example:

```
# auth-refactor · 2026-06-08 · MAR2-1476 + MAR2-1490, repo: marker-api
G: migrate session auth → JWT, keep /login API stable
S: JWT issue/verify done src/auth/jwt.ts; mw swapped; refresh WIP
D: RS256 not HS256 (multi-service verify); 15m access + 7d refresh
✗: NOT Redis (removed, stateless now) · /login resp shape unchanged—don't "fix"
F: src/auth/jwt.ts=core; src/mw/auth.ts=guard; test/auth.spec.ts=cov
N: 1 refresh rotation 2 revoke-list 3 e2e
Q: rotate refresh every use or sliding window?
```

## Maintenance (the important part)

After each meaningful step, decision, or discovery, **Edit the file** to match reality:

- **Append** new state/decisions/files to the relevant section.
- **Correct or delete in place** any line that is now wrong or obsolete — never leave a known-false statement. This is what stops a future agent from being poisoned by stale notes.
- Use the **✗** section only for *traps*: a wrong assumption that is tempting to re-derive. Don't log every fixed typo — that wastes tokens.
- Keep the whole file **dense and small** (aim < ~1KB). If a section bloats, compress it: drop stopwords, fold resolved items into one line, delete finished `N` steps.

## Density rules

Write for the model, not for prose. Maximize meaning per token:

- Telegraphic: drop articles and filler. "mw swapped" not "I have swapped the middleware".
- Symbols: `→` leads-to/becomes, `=` is/maps, `;` separates, `&` and, `✗` not/wrong, `✓` done.
- Abbreviate once unambiguous (`mw`=middleware, `cov`=coverage, `req`/`resp`, `repo`).
- **Do not** gzip, base64, or binary-encode the file. High-entropy bytes tokenize *worse* than terse text (≈1 token/byte vs ~4 chars/token), so it costs more, not less. Dense natural shorthand is the actual win.
