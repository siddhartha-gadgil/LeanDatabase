#!/usr/bin/env python3
"""Score a dataset's proving census against VeriEQL's own published verdicts.

VeriEQL's experiment output (`experiments/<date>/<benchmark>.out`) carries, per pair, the verdict it
reached at each bound: `EQU` (bounded-equivalent), `NEQ` (refuted, with a counterexample), `TMO`,
or a parse/unsupported error. That is the ground truth to score against:

* of the pairs VeriEQL *verified equivalent*, how many do we prove (unbounded)?
* do we prove any pair it *refuted*? Each one is either a soundness bug or a modelling difference —
  most of their counterexamples insert `NULL`, which our all-`NOT NULL` base tables cannot produce,
  so those are expected and are reported separately.

    python3 Bench/compare_verieql.py Literature <VeriEQL>/experiments/2025_10_31/literature.out
"""
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def verdict(rec: dict) -> str:
    states = rec.get("states") or []
    if "NEQ" in states:
        return "NEQ"
    if "EQU" in states:
        return "EQU"
    if "Parser" in (rec.get("err") or ""):
        return "PARSE-ERR"
    return states[-1] if states else "?"


def main(dataset: str, out_file: str):
    theirs, null_ce = {}, set()
    for line in open(out_file):
        rec = json.loads(line)
        idx = str(rec["index"])
        theirs[idx] = verdict(rec)
        if "NULL" in (rec.get("counterexample") or ""):
            null_ce.add(idx)

    results = json.loads((ROOT / dataset / "prove_results.json").read_text())["results"]
    ours = {r["id"].split(":")[0]: r["proved"] for r in results}

    table = Counter()
    missed, alarms, null_only = [], [], []
    for pid, proved in ours.items():
        v = theirs.get(pid, "ABSENT")
        table[(v, "proved" if proved else "not")] += 1
        if v == "EQU" and not proved:
            missed.append(pid)
        elif v == "NEQ" and proved:
            (null_only if pid in null_ce else alarms).append(pid)

    key = lambda s: int(s) if s.isdigit() else s
    print(f"{dataset}: {len(ours)} pairs scored against VeriEQL")
    for (v, o), n in sorted(table.items()):
        print(f"   {v:10s} {o:8s} {n}")
    print(f"\n   proved of VeriEQL-EQU : {table[('EQU','proved')]}/{table[('EQU','proved')] + len(missed)}")
    print(f"   EQU we miss           : {sorted(missed, key=key)}")
    print(f"   NEQ we prove, NULL-only counterexample (expected — our base columns are NOT NULL):")
    print(f"                           {sorted(null_only, key=key)}")
    print(f"   NEQ we prove, NON-NULL counterexample (SOUNDNESS ALARM — investigate each):")
    print(f"                           {sorted(alarms, key=key)}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
