#!/usr/bin/env python3
"""Attach VeriEQL's integrity constraints to a dataset's `pairs.json`.

VeriEQL's paper reports that over 95% of its benchmarks *require* integrity constraints: a rewrite like
dropping a `DISTINCT` over a key, or eliminating a join, is an equivalence only under them. Their
encoder asserts the constraints in SMT; our analogue is the `HYPOTHESIS` vocabulary — a `primary` key
becomes `{"unique": col}` (that column determines the whole row, `FuncDepEq col id`), which
`provePair` now assumes.

    python3 Bench/verieql_constraints.py Literature <VeriEQL>/benchmarks/literature/literature.jsonlines
    python3 Bench/verieql_constraints.py Calcite    <VeriEQL>/benchmarks/calcite/calcite2.jsonlines --data-eq

`--data-eq` additionally marks every pair `dataEq: true` — VeriEQL compares output *tuples*
positionally, so its notion of equivalence ignores column labels, which is our `~=`.

`foreign` becomes `{"table", "foreign": [childCol, parentTable, parentCol]}` (`ForeignKey` in
`Constraints.lean`). Not carried over: `not_null` (base columns are already non-nullable in our
model). Composite keys are skipped — `unique` names a single determining column.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def hypotheses_of(constraints: list) -> tuple[list[dict], int, int]:
    """→ (hypotheses, #composite-keys skipped, #foreign skipped)."""
    hyps, composite, foreign = [], 0, 0
    for c in constraints or []:
        for kind, body in c.items():
            entries = body if isinstance(body, list) else [body]
            cols = [e["value"] for e in entries if isinstance(e, dict) and "value" in e]
            if kind == "primary":
                if len(cols) != 1:
                    composite += 1
                    continue
                table, _, col = cols[0].partition("__")
                if col:
                    hyps.append({"table": table, "unique": col})
            elif kind == "foreign":
                # `[child, parent]` — every child value occurs in the parent column.
                if len(cols) == 2:
                    ctbl, _, ccol = cols[0].partition("__")
                    ptbl, _, pcol = cols[1].partition("__")
                    if ccol and pcol:
                        hyps.append({"table": ctbl, "foreign": [ccol, ptbl, pcol]})
                        continue
                foreign += 1
    return hyps, composite, foreign


def main(dataset: str, source: str, data_eq: bool):
    by_index = {}
    for line in open(source):
        rec = json.loads(line)
        by_index[str(rec["index"])] = rec

    path = ROOT / dataset / "pairs.json"
    pairs = json.loads(path.read_text())
    attached = matched = composite = foreign = 0
    for pair in pairs:
        rec = by_index.get(pair["id"].split(":")[0])
        if rec is None:
            continue
        matched += 1
        hyps, comp, fk = hypotheses_of(rec.get("constraint"))
        composite += comp
        foreign += fk
        if hyps:
            pair["hypotheses"] = hyps
            attached += 1
        elif "hypotheses" in pair:
            del pair["hypotheses"]
        if data_eq:
            pair["dataEq"] = True
    path.write_text(json.dumps(pairs, indent=1) + "\n")
    print(f"{dataset}: matched {matched}/{len(pairs)} pairs, {attached} with key hypotheses"
          f" (skipped {composite} composite keys, {foreign} foreign keys)"
          + (", dataEq=true" if data_eq else ""))


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    main(args[0], args[1], "--data-eq" in sys.argv)
