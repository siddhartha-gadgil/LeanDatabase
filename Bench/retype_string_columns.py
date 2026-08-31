#!/usr/bin/env python3
"""Retype corpus columns that are compared against string literals.

The Lean-ified Calcite/Literature problems declare every column `INT`, but their queries still carry
the original `'…'` string comparisons (`D.DNAME = 'SECURITY'`), which then fail to elaborate as an
`Int`-vs-`String` type error. A column compared to (or `IN`-tested against) a string literal is a
string column, so this rewrites that column's type to STRING in `corpus_pg.json` / `pairs.json`.

    python3 Bench/retype_string_columns.py Literature Calcite
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
# `col = 'x'`, `'x' = col`, `col IN ('a','b')`, `col LIKE 'x'` — the column may be qualified.
PATTERNS = [
    re.compile(r"([A-Za-z_][\w.]*)\s*(?:=|<>|!=|LIKE|<|>|<=|>=)\s*'", re.I),
    re.compile(r"'[^']*'\s*(?:=|<>|!=)\s*([A-Za-z_][\w.]*)", re.I),
    re.compile(r"([A-Za-z_][\w.]*)\s+(?:NOT\s+)?IN\s*\(\s*'", re.I),
]


# `a.b = c.d` — a comparison between two column refs propagates the type from one side to the other.
COL_CMP = re.compile(r"([A-Za-z_][\w.]*)\s*(?:=|<>|!=)\s*([A-Za-z_][\w.]*)")


def bare(name: str) -> str:
    return name.split(".")[-1].upper()


def string_columns(sql: str) -> set[str]:
    """Bare column names (last component, upper-cased) compared against a string literal."""
    out = set()
    for pat in PATTERNS:
        for m in pat.finditer(sql):
            out.add(bare(m.group(1)))
    return out


def propagate(sqls: list[str], seeds: set[str]) -> set[str]:
    """Close `seeds` under column-to-column comparisons: `DNAME = PDEPT` makes PDEPT a string too.

    The datasets type every column INT, so a column is only known to be a string through *use*; a
    comparison is exactly such a use, and SQL has no cross-type `=`, so the two sides share a type.
    """
    edges: set[tuple[str, str]] = set()
    for sql in sqls:
        for m in COL_CMP.finditer(sql):
            a, b = bare(m.group(1)), bare(m.group(2))
            if a != b and not b.isdigit():
                edges.add((a, b))
    out = set(seeds)
    changed = True
    while changed:
        changed = False
        for a, b in edges:
            for x, y in ((a, b), (b, a)):
                if x in out and y not in out:
                    out.add(y); changed = True
    return out


def retype(dataset: str):
    """Infer the string columns of each *problem* (pooling both its queries, in both files) and apply."""
    files = [("corpus_pg.json", ["query"]), ("pairs.json", ["first", "second"])]
    loaded = []
    sqls_by_problem: dict[str, list[str]] = {}
    for name, keys in files:
        path = ROOT / dataset / name
        if not path.exists():
            continue
        recs = json.loads(path.read_text())
        loaded.append((path, keys, recs))
        for rec in recs:
            pid = rec.get("id", "").split(":")[0]
            sqls_by_problem.setdefault(pid, []).extend(rec.get(k, "") for k in keys)

    # One query of a problem may carry the literal that types a column its sibling only compares.
    strings_by_problem = {}
    for pid, sqls in sqls_by_problem.items():
        seeds = set()
        for sql in sqls:
            seeds |= string_columns(sql)
        strings_by_problem[pid] = propagate(sqls, seeds) if seeds else seeds

    changed = 0
    for path, _keys, recs in loaded:
        for rec in recs:
            cols = strings_by_problem.get(rec.get("id", "").split(":")[0], set())
            for schema in rec.get("schemas", []):
                for col in schema.get("columns", []):
                    if col["name"].upper() in cols and col["type"].upper() != "STRING":
                        col["type"] = "STRING"
                        changed += 1
        path.write_text(json.dumps(recs, indent=1) + "\n")
    print(f"{dataset}: retyped {changed} column declarations to STRING")


if __name__ == "__main__":
    for ds in sys.argv[1:] or ["Literature", "Calcite"]:
        retype(ds)
