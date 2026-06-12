---
name: ctx
description: "Load, create, or switch the active task context — a dense, persistent working-memory file in ~/.local/share/claude-contexts/ that makes resuming long tasks cheap and prevents context poisoning"
trigger: /ctx
---

# /ctx — task contexts

A **task context** is a single dense file holding the durable working memory of a task: goal, current state, decisions, gotchas, corrections, file map, next steps. It lets a fresh session resume in a few hundred tokens instead of replaying a huge transcript, and it is rewritten in place so a later agent never inherits stale or superseded notes.

Contexts are **freeform** — one can span multiple tickets or repos. They live globally at `~/.local/share/claude-contexts/<slug>.md`. Reading and writing there is pre-authorized (no permission prompts).

A `SessionStart` hook lists recent contexts and asks which to load at the start of each chat; this skill is the schema reference and gives explicit control.

## Usage

```
/ctx                 # list contexts (recent + stale)
/ctx <slug>          # load <slug>, make it the active context
/ctx new <slug>      # create ~/.local/share/claude-contexts/<slug>.md from the skeleton, make it active
/ctx none            # disable the protocol for this session
```

`<slug>` is kebab-case (`auth-refactor`, `q3-billing-spike`).

## Loading

`Read ~/.local/share/claude-contexts/<slug>.md` and treat it as ground truth for prior work — do not re-derive what it already records. If something in it contradicts what you now observe, the file is stale: fix it in place (see Maintenance).

## Schema

Exactly these keys, in this order, each appearing **once**. Omit a key if empty. **Never invent new sections** — if something doesn't fit a key it belongs in the closest one, or it isn't durable enough to keep.

```
# <slug> · <last-updated date> · scope: <freeform — area / tickets / repos>
G: goal — what "done" looks like + the frame (epic, tickets, hard constraints).   [durable]
S: state — where things stand RIGHT NOW; the active focus. Rewrite every session.  [volatile]
D: decisions — durable choices + rationale, as "X not Y (why)".                    [durable]
!: gotchas — true, surprising landmines + the fix. Things that WILL bite again.    [durable]
✗: corrections — wrong assumptions / dead ends a future agent must NOT repeat.     [durable]
F: files — path = role; path = role.                                               [durable]
N: next — ordered, FUTURE-only steps.                                              [volatile]
Q: open questions / unknowns.                                                      [volatile]
```

**`!` vs `✗`** — the two anti-poisoning keys, kept distinct:
- `!` = something *true and non-obvious* that will trip you (a footgun + its fix): "Tailwind `svg{display:block}` drops inline icons → wrap in an inline-flex span."
- `✗` = something *false or abandoned* you'd otherwise assume or retry: "branch X is NOT the design ref — it's a legacy snapshot."

Example:

```
# auth-refactor · 2026-06-08 · scope: marker-api · MAR2-1476/1490
G: session auth → JWT, /login API unchanged. 1476=core, 1490=refresh.
S: access+refresh issuing done; rotation in review; revoke-list next.
D: RS256 not HS256 (multi-service verify); 15m access + 7d refresh.
!: verify() must resolve Element via ownerDocument realm — bare `instanceof` fails cross-iframe.
✗: NOT Redis — stateless now; don't reintroduce a session store.
F: src/auth/jwt.ts=core; src/mw/auth.ts=guard.
N: 1 revoke-list 2 e2e
Q: rotate refresh every use or sliding window?
```

## Maintenance (the point of the whole thing)

The file is a **continuously compressed snapshot, not a worklog.** After each meaningful step, edit it so it reads as if the current state had always been the plan:

- **Rewrite the volatile keys** (`S`, `N`, `Q`) freely. `S` must always name the *current* focus — never leave last session's focus sitting there. `N` is **future-only**: the moment a step is done, delete it and fold its durable outcome into `D`/`!`/`F`. A dated list of finished work is the exact failure mode this format exists to prevent.
- **Grow the durable keys** (`D`, `!`, `✗`, `F`) sparingly, and **correct or delete in place** the instant something is superseded — never leave both the old and new value (a colour that changed blue→orange: the file says orange, full stop). A known-false line is poison.
- **Keep the destination, not the journey.** "tried blue, then green, settled on yellow because X" → "yellow (X)". Dead branches aren't knowledge.
- **Don't record** what the repo already says (test names, line-by-line diffs, anything re-derivable from code), transient status ("check passes"), or narration/praise.
- **Stay small** — aim < ~1 KB. A bloating key is the signal to compress it, not to spill into a new section.

## Density rules

Write for the model, not for prose. Maximize meaning per token:

- Telegraphic: drop articles and filler. "mw swapped" not "I have swapped the middleware".
- Symbols: `→` leads-to/becomes, `=` is/maps, `;` separates, `&` and, `✗` not/wrong, `✓` done.
- Abbreviate once unambiguous (`mw`=middleware, `cov`=coverage, `req`/`resp`, `repo`).
- **Do not** gzip, base64, or binary-encode the file. High-entropy bytes tokenize *worse* than terse text (≈1 token/byte vs ~4 chars/token), so it costs more, not less. Dense natural shorthand is the actual win.
