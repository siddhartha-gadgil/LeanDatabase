# Overnight `sql_equiv_llm` run — RUNBOOK

**Status:** launched & running detached (nohup+setsid) — survives terminal/session close.
**Started:** 2026-09-04. **Datasets:** Literature (64) + Calcite (397) + CrossSkill (1424) = **1885 files**.
**Config:** `WORKERS=16`, `MAX_COST_CENTS=100000` (effectively no cap — "run all, whatever cost"),
`PER_FILE_TIMEOUT=700s`, model `gpt-5.6-sol`, `maxRounds=3`.

## What each file does
1. **Step 0 — `sql_equiv_safe`** (dispatch's membership-free tier): free proofs, no LLM cost. Only ever
   fails cleanly (no uncatchable-timeout crash), so it always falls through to the LLM.
2. **Step 1 — LLM ×3** (`gpt-5.6-sol`, reasoning high): each round gets the goal + repo-context + the
   residual proof-state from the prior failed try; prompt recommends `sql_normalize` then a targeted close.
3. **Counterexample** — if the model says UNPROVABLE and returns rows: **Lean set-`decide`** verifies a
   SET counterexample (`METHOD=plausible_sql`); if Lean can't (multiplicity-only), it is emitted as a
   MULTISET candidate (`METHOD=plausible_sql_bag`) and **certified offline by sqlglot bag-check** in the
   runner. Spurious ones (real-SQL bag-equal) are rejected.

## Robustness (the "no cascading failure" guarantees)
- **Process-group kill on timeout** — no orphaned `lean` pileup (the earlier hang, fixed).
- **Resume/skip** — restart re-uses `scripts/overnight_progress.jsonl`; done files are never re-run
  (never re-burns $). **Delete that file to force a fully fresh run.**
- **Cost ceiling** `MAX_COST_CENTS` — cancels remaining files if hit (set high here).
- **curl timeout+retry** (20s connect / 300s max / 2 retries) — a network stall can't hang a file.

## Monitor
```bash
tail -f /home/anirudhgupta/LeanDatabase/scripts/overnight.log        # live progress + running cost
cat    /home/anirudhgupta/LeanDatabase/scripts/overnight_report.md    # tallies (refreshed every 20 files)
pgrep -af overnight_run.py | grep -v 'bash -c'                        # is it alive?
```

## Outputs
- `scripts/overnight_report.md` — per-dataset tallies + **separate disproof counts** (Lean-verified set /
  **sqlglot-certified multiset** / spurious-rejected) + **total estimated cost**.
- `scripts/overnight_results.csv`, `scripts/overnight_progress.jsonl` (resume log).
- `Bench/<ds>/Proven/<n>.lean` (proofs), `Bench/<ds>/CounterExample/<n>.lean` (set-CX),
  `Bench/<ds>/CounterExample/<n>.bag.json` (sqlglot-certified multiset CX).

## Relaunch / resume (if it ever stops)
```bash
cd /home/anirudhgupta/LeanDatabase
export OPENAI_API_KEY=$(grep -E '^OPENAI_API_KEY=' .env | head -1 | cut -d= -f2- | sed -e 's/^["'"'"']//' -e 's/["'"'"']$//')
# RESUME (keep progress.jsonl → skips done files):
WORKERS=16 MAX_COST_CENTS=100000 nohup setsid python3 scripts/overnight_run.py >> scripts/overnight.log 2>&1 &
```
Note: the OpenAI key is read from the env var first, else `.env`. A stale exported key SHADOWS `.env`,
so export the new one explicitly (as above) or `unset OPENAI_API_KEY` to fall back to `.env`.

## Estimated cost
- ~314 files close at Step 0 (`sql_equiv`) → **$0**.
- ~1571 reach the LLM. Observed: PROVED ≈ 0.2–0.3¢, INCONCLUSIVE (3 rounds) ≈ ~1¢, avg ≈ 0.5¢.
- **Estimate: ~$8, plausibly $8–20** (counterexample rounds + hard-pair 3-round exhaustion push it up).
- The running total prints on every log line (`run X¢`) and the final total is in `overnight_report.md`.
