# Proven cross-skill equivalences (10)

Each file proves, via the `sql_equiv` tactic, that two independently-written SQL queries
answering the same question denote the *same* relation for all table contents. Generated from
the crossskill corpus by `Examples/CrossSkill/gen_proven.py`; all are checked by `lake build`.
Some are **hypothesis-conditioned** — where the variants differ by a `WHERE` conjunct, that data
assumption is stated as an explicit `HYPOTHESIS` antecedent (see `P_sf_local041`, `P_sf_bq232`).

- `P_sf_local041.lean` — sf_local041 (full schema, applied form; 6 pairs)
- `P_sf_bq044.lean` — sf_bq044
- `P_sf_bq060.lean` — sf_bq060
- `P_sf_bq074.lean` — sf_bq074
- `P_sf_bq126.lean` — sf_bq126
- `P_sf_bq169.lean` — sf_bq169
- `P_sf_bq232.lean` — sf_bq232
- `P_sf_bq300.lean` — sf_bq300
- `P_sf_bq303.lean` — sf_bq303
- `P_sf_bq432.lean` — sf_bq432
