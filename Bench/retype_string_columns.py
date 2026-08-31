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


def string_columns(sql: str) -> set[str]:
    """Bare column names (last component, upper-cased) compared against a string literal."""
    out = set()
    for pat in PATTERNS:
        for m in pat.finditer(sql):
            out.add(m.group(1).split(".")[-1].upper())
    return out


def retype(dataset: str):
    changed = 0
    for name, keys in [("corpus_pg.json", ["query"]), ("pairs.json", ["first", "second"])]:
        path = ROOT / dataset / name
        if not path.exists():
            continue
        recs = json.loads(path.read_text())
        for rec in recs:
            cols = set()
            for k in keys:
                cols |= string_columns(rec.get(k, ""))
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
