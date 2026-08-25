#!/usr/bin/env python3
"""Convert the (Snowflake) crossskill corpus JSON into PostgreSQL — the canonical dialect we prove over.

Transpiles every `equivalent_sqls[].sql` and the `ddl` from Snowflake to PostgreSQL via sqlglot
(TRANSLATION ONLY — no algebraic/optimizer passes), preserving all other fields. Writes a sibling
`crossskill_equivalent_postgres.jsonl`. Queries sqlglot can't transpile are kept verbatim and counted.

Usage: python3 to_postgres_corpus.py
"""
import json, os
from transpile import transpile_sql

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "crossskill_equivalent_sql.jsonl")
DST = os.path.join(HERE, "crossskill_equivalent_postgres.jsonl")

def main() -> None:
    n_rec = n_q = n_qfail = n_ddlfail = 0
    with open(SRC) as f, open(DST, "w") as out:
        for line in f:
            if not line.strip():
                continue
            r = json.loads(line)
            n_rec += 1
            # DDL is left in the source dialect on purpose: it's only ever read by `parse_ddl` (which
            # extracts column names/types dialect-agnostically), and the giant multi-table DDLs are slow
            # to transpile. Only the QUERIES — what the Lean prover consumes — are canonicalised.
            for e in r.get("equivalent_sqls", []):
                n_q += 1
                pg, err = transpile_sql(e["sql"], read="snowflake", write="postgres")
                if err: n_qfail += 1
                else: e["sql"] = pg
            out.write(json.dumps(r) + "\n")
    print(f"records: {n_rec}  queries: {n_q}  (transpile failures: {n_qfail} queries, {n_ddlfail} ddl)")
    print(f"wrote {DST}")

if __name__ == "__main__":
    main()
