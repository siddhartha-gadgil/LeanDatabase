#!/usr/bin/env python3
"""Build a dataset's census inputs from its `Problems/*.lean` files.

`Bench/<DS>/Problems/<n>.lean` is the source of truth for the Calcite / Literature datasets: the SQL
there is already in the one dialect we prove over, so (unlike the Snowflake CrossSkill corpus, which
goes through `transpile.py`) nothing is transpiled here — the queries are lifted verbatim.

    python3 Bench/extract_corpus.py Calcite Literature

writes, per dataset:
  * `corpus_pg.json` — `{id, schemas, query}` per query side (identical sides deduped), for `elabcheck`
  * `pairs.json`     — `{id, schemas, first, second, dataEq}` per `theorem eq`, for `provecheck`
`dataEq` is false: these theorems are plain `=`, so column labels must match too.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CREATE_RE = re.compile(r"^CREATE TABLE\s+(\S+)\s*\((.*)\)\s*$")
COL_RE = re.compile(r"«([^»]+)»\s+([A-Za-z0-9_]+)")
SQL_RE = re.compile(r'sql%\(\[([^\]]*)\]\)\s+"(.*)"\s*$')


def parse_problem(path: Path):
    """→ (schemas_by_name, [(schema_names, sql), ...]) for one Problems file."""
    tables, sides = {}, []
    for line in path.read_text().splitlines():
        line = line.strip()
        if m := CREATE_RE.match(line):
            tables[m.group(1)] = [{"name": c, "type": t} for c, t in COL_RE.findall(m.group(2))]
        elif m := SQL_RE.search(line):
            names = [n.strip().removesuffix("_schema") for n in m.group(1).split(",") if n.strip()]
            sides.append((names, m.group(2)))
    return tables, sides


def build(dataset: str):
    probs = sorted((ROOT / dataset / "Problems").glob("*.lean"),
                   key=lambda p: (len(p.stem), p.stem))
    corpus, pairs, skipped = [], [], []
    for path in probs:
        tables, sides = parse_problem(path)
        if len(sides) != 2:
            skipped.append(f"{path.name}: found {len(sides)} sql% queries, expected 2")
            continue
        names, first = sides[0]
        if sides[1][0] != names:
            skipped.append(f"{path.name}: the two sides list different schemas")
            continue
        missing = [n for n in names if n not in tables]
        if missing:
            skipped.append(f"{path.name}: no CREATE TABLE for {', '.join(missing)}")
            continue
        schemas = [{"name": n, "columns": tables[n]} for n in names]
        second = sides[1][1]
        for i, sql in enumerate([first, second] if first != second else [first]):
            corpus.append({"id": f"{path.stem}:q{i}", "schemas": schemas, "query": sql})
        pairs.append({"id": f"{path.stem}:eq", "schemas": schemas,
                      "first": first, "second": second, "dataEq": False})
    for out, data in [("corpus_pg.json", corpus), ("pairs.json", pairs)]:
        (ROOT / dataset / out).write_text(json.dumps(data, indent=1) + "\n")
    print(f"{dataset}: {len(pairs)} pairs, {len(corpus)} queries from {len(probs)} problems")
    for s in skipped:
        print(f"  SKIPPED {s}")


if __name__ == "__main__":
    for ds in sys.argv[1:] or ["Calcite", "Literature"]:
        build(ds)
