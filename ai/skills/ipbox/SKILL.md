---
name: ipbox
description: "Build the monthly IP Box evidence package (Polish) from the PRs merged by me for one client contract"
disable-model-invocation: true
---

# /ipbox

Collect one month of merged PRs as evidence of creative work for the Polish IP Box relief (art. 30ca and 30cb PIT). The output is a per-month directory in the private evidence repo. The user commits it.

## Usage

```
/ipbox <client> [YYYY-MM]
```

`<client>` is a key under `[client.*]` in the config. It names the contract, not a GitHub org. One contract can span several orgs, for example the end client's org. `YYYY-MM` defaults to the previous month.

## Facts the package must satisfy

- The record must show, per qualified IP, the works created and the income share. The statute sets no form (art. 30cb PIT).
- MF explanatory notes (2019) ask for a monthly archived snapshot (¶188) and a project log: description, dates, people, list of works per person (¶192).
- Development work excludes "rutynowe i okresowe zmiany, nawet jeżeli takie zmiany mają charakter ulepszeń" (art. 5a pkt 40 PIT). The log keeps those PRs with class `non-rd`. A log with only R&D looks curated.
- KIS asks: which program or module was created, what existed before, what is new, how the work was planned and tested, and how the rights moved to the client.

## Paths

- Evidence repo: `~/ipbox`. Stop if it is not a git repo.
- Config: `~/ipbox/ipbox.toml`. Stop if `[client.<client>]` is missing. See `ipbox.example.toml` next to this file.
- Month dir: `~/ipbox/<YYYY-MM>/`.

## Workflow

### Step 1 - Resolve the month and read the config

```bash
nua '((date now | format date %Y-%m-01) | into datetime) - 1day | format date %Y-%m'
nua 'open ~/ipbox/ipbox.toml | get client.<client>'
```

### Step 2 - Fetch

```bash
ipbox-fetch fetch <YYYY-MM> ~/ipbox/<YYYY-MM> <org>...
```

Pass every org from the config's `orgs` list. The script searches each org on its own and stops with the `gh` error when one is blocked, for example by SAML SSO. This writes `prs.json` and `patches/NNN_repo_title.patch` (full PR patch, all commits). A re-run replaces both and leaves the files from steps 4 to 6 alone. Each row carries a heuristic `class` (`rd`, `non-rd`, `review`) and `reason`, a `ticket` key, and `thin: true` when the body has under 40 words.

### Step 3 - Linear context

Load the `linear-server` MCP tool schemas with ToolSearch. For each row with a `ticket`, call `mcp__linear-server__get_issue`. The ticket title and description give the goal set before the work (¶41). Skip tickets that do not resolve.

### Step 4 - Classify

Propose the final class for every PR. Reason codes:

| class | reason | when |
|---|---|---|
| non-rd | bot, deps, ci, chore, style, docs, revert | routine change, no design |
| non-rd | bugfix-routine | restores intended behaviour, no new design |
| rd | bugfix-design | the fix needs a new algorithm or structure |
| rd | feature | new functionality or module |
| rd | redesign | changed structure of an existing module |
| rd | algorithm | new computation or data processing method |
| rd | integration | new connection between systems |

For rows with `class: review`, read the patch and decide. Show the full table (number, repo, title, class, reason) in chat. Then ask one `AskUserQuestion`: "Accept the classification?" with options Accept and Change. On Change the user lists PR numbers and the new class in Other. Apply and show the table again.

### Step 5 - Write the month files

Read the patch only for rows with `thin: true` or a bugfix reason. Patches run to hundreds of kilobytes, so read the commit messages in `prs.json` first and then the first 300 lines of the patch. For the rest, the body, the commit messages, the file list, and the ticket suffice.

`log.csv`, one row per PR, every PR:

```
month,ip_id,url,repo,number,merged_at,head_sha,merge_sha,ticket,class,reason,title,title_pl,patch
```

`ip_id` is the client key. `title_pl` is a Polish one-line title of the work.

`narratives.md`, Polish, present tense, one section per `rd` PR, 4 to 8 sentences in this order:

1. Problem lub potrzeba (wymaganie klienta, ograniczenie istniejącego systemu).
2. Stan przed pracą (co istniało i dlaczego nie wystarczało).
3. Co powstało: nazwany moduł, funkcja, interfejs lub algorytm, ustalony w postaci kodu źródłowego.
4. Element twórczy: decyzja projektowa i odrzucona alternatywa. Nowość w skali przedsiębiorstwa wystarcza.
5. Metoda: zadanie w Linear, przegląd kodu, testy, CI.
6. Rezultat: nowa funkcjonalność lub poprawa użyteczności.
7. Prawa: przeniesione na `<client>` na podstawie umowy z `<contract_date>`, `<rights_clause>`, z chwilą akceptacji pracy. Gdy `end_client` jest ustawiony: kod trafia do repozytorium `<end_client>`, klienta końcowego `<client>`.

Section header: `## NNN · <repo>#<number> · <title_pl>`. Footer line: `Źródło: <url> · commit <head_sha> · <ticket> · <patch>`.

End the file with `## Prace nieobjęte ulgą`: one line per `non-rd` PR with the Polish reason.

`invoice.txt`, two lines, each under 150 characters. Check with `str length`:

```
PL: Prace programistyczne B+R: <moduły> wraz z przeniesieniem autorskich praw majątkowych, <miesiąc> <rok>
EN: R&D software development: <modules> with transfer of copyright, <month> <year>
```

### Step 6 - Share and the cumulative files

Ask the user for the share of creative work in the month as a percentage. The skill never estimates it.

Append to `~/ipbox/months.csv` (create with a header when missing):

```
month,ip_id,share_pct,rd_prs,total_prs,invoice_pl,invoice_en
```

Append the month rows to `~/ipbox/log.csv` (same header as the month log). Drop rows whose `url` is already present before you append.

### Step 7 - Hash and hand over

```bash
ipbox-fetch sums ~/ipbox/<YYYY-MM>
```

Show `git -C ~/ipbox status --short` and the first lines of `narratives.md`. Propose the commit message `<YYYY-MM>`. Do not commit. The user commits, and the commit date is the month-end proof.

### Important

- Author is always `@me`. Reviews of other people's PRs are not creative work.
- The `gh` token must satisfy the SSO policy of every org in `orgs`. Run the skill on the machine that holds those credentials.
- Never write invoice amounts or costs into the repo.
- Do not paste diffs into the narratives. The patch files are the attachment.
- Keep the English PR title and URL in the log as the source link.
