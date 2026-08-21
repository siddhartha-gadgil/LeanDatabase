# Proven cross-skill equivalences (14 files, 17 pairs)

Each file proves via `sql_equiv` that independently-written SQL answers to one question denote the
same relation for all table contents. Hypothesis-conditioned files state the bridging data fact
(`WHERE`/`SELECT` equality, `FUNCDEP`, `UNIQUE`, `BIJECTION`) as an explicit `HYPOTHESIS` antecedent.
Full schema (no column pruning). All checked by `lake build`.

- `P_sf_bq044.lean` — sf_bq044 (0 pairs)
- `P_sf_bq060.lean` — sf_bq060 (1 pair)
- `P_sf_bq074.lean` — sf_bq074 (0 pairs)
- `P_sf_bq126.lean` — sf_bq126 (1 pair)
- `P_sf_bq169.lean` — sf_bq169 (0 pairs)
- `P_sf_bq232.lean` — sf_bq232 (3 pairs)
- `P_sf_bq284.lean` — sf_bq284 (1 pair)
- `P_sf_bq300.lean` — sf_bq300 (1 pair)
- `P_sf_bq303.lean` — sf_bq303 (0 pairs)
- `P_sf_bq327.lean` — sf_bq327 (1 pair)
- `P_sf_bq432.lean` — sf_bq432 (1 pair)
- `P_sf_local040.lean` — sf_local040 (1 pair)
- `P_sf_local041.lean` — sf_local041 (6 pairs)
- `P_sf_local085.lean` — sf_local085 (1 pair)
