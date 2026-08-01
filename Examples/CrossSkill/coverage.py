#!/usr/bin/env python3
"""Coverage guard for the SQL-equivalence corpus (ROADMAP task 0.8).

Turns "coverage" from a claim into two tracked numbers, printed on every run:

  1. POTENTIAL  — a static feature-classifier over every query in
     `crossskill_equivalent_sql.jsonl`. Each query is assigned the *earliest
     roadmap phase* that unlocks it (the max over the phases of the features it
     uses); a record is unlocked only when all its variants are. This
     reproduces the ROADMAP "coverage unlock curve" as a measured number that
     moves as features land, so drift between the prose and reality is visible.

  2. VERIFIED   — how many corpus records are actually *proved* today, read from
     `result.json` (maintained by `gen_result.py`): a machine-checked count, not
     an estimate. `lake build` is what guarantees those proofs still compile;
     this script only reports the tally. Run order in CI: `lake build` then this.

The classifier is a deliberately transparent heuristic (regex on the SQL text),
not a SQL parser — see FEATURES below. It errs toward calling a query *blocked*
(a feature match pushes it to a later phase), so POTENTIAL is a lower bound on
what the real parser accepts once normalization is in place. It is meant to
track the shape of the curve and catch regressions, not to be exact.

Usage:  python3 Examples/CrossSkill/coverage.py [--json]
Exit code is always 0 (reporting tool); `--json` prints only the summary object.
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "crossskill_equivalent_sql.jsonl")
RESULT = os.path.join(HERE, "result.json")

# --- phase ranks (cumulative unlock order from ROADMAP) ---------------------
P1, P2, P3, P4, P5, OUT = 1, 2, 3, 4, 5, 99
PHASE_NAME = {
    P1: "P1 reachable now (cheap syntax)",
    P2: "P2 opaque scalars",
    P3: "P3 CTE / scalar-subquery",
    P4: "P4 NULL + 3VL",
    P5: "P5 outer joins",
    OUT: "out of scope (windows / recursive)",
}

# --- feature detectors: (name, phase, predicate over UPPERCASED sql) --------
# `proj` is the top-level projection list (SELECT..FROM of the outermost query),
# used to tell a scalar subquery in the SELECT list (P3) from an IN/EXISTS
# subquery in WHERE (already supported, so *not* a blocker).
def _projection_segment(sql: str) -> str:
    """Text between the first top-level SELECT and its matching FROM."""
    i = sql.find("SELECT")
    if i < 0:
        return ""
    depth, j = 0, i + len("SELECT")
    while j < len(sql):
        c = sql[j]
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
        elif depth == 0 and sql[j:j + 4] == "FROM":
            return sql[i + len("SELECT"):j]
        j += 1
    return sql[i + len("SELECT"):]

WINDOW_RE     = re.compile(r"\bOVER\s*\(")
RECURSIVE_RE  = re.compile(r"\bWITH\s+RECURSIVE\b")
CTE_RE        = re.compile(r"\bWITH\b[\s\S]{0,80}?\bAS\s*\(")
CAST_RE       = re.compile(r"\bCAST\s*\(|::")
SCALAR_FN_RE  = re.compile(
    r"\bROUND\s*\(|\b(YEAR|MONTH|DAY|QUARTER|WEEK|HOUR|MINUTE|SECOND|"
    r"DATE_TRUNC|DATEADD|DATEDIFF|DATE_DIFF|DATE_ADD|EXTRACT|TO_DATE|"
    r"TO_CHAR|TO_TIMESTAMP|CURRENT_DATE|NOW|DATE_PART)\s*\(|"
    r"\b(SUBSTR|SUBSTRING|LEFT|RIGHT|CONCAT|UPPER|LOWER|INITCAP|TRIM|LTRIM|"
    r"RTRIM|REPLACE|SPLIT|SPLIT_PART|LENGTH|LEN|REGEXP_\w+)\s*\(")
NULL_RE       = re.compile(r"\bNULL\b|\bCOALESCE\s*\(|\bIFNULL\s*\(|\bNULLIF\s*\(|\bNVL\s*\(")
OUTER_JOIN_RE = re.compile(r"\b(LEFT|RIGHT|FULL)\s+(OUTER\s+)?JOIN\b")
NESTED_SELECT_RE = re.compile(r"\(\s*SELECT\b")

FEATURE_PHASE = {
    "window": OUT, "recursive": OUT, "cte": P3, "scalar_subquery": P3,
    "cast": P2, "scalar_fn": P2, "null": P4, "outer_join": P5,
}

def features(sql: str):
    """Return the set of (feature_name -> phase) a query triggers."""
    s = re.sub(r"\s+", " ", sql.upper())
    proj = _projection_segment(s)
    f = {}
    if WINDOW_RE.search(s):                 f["window"] = OUT
    if RECURSIVE_RE.search(s):              f["recursive"] = OUT
    if CTE_RE.search(s):                    f["cte"] = P3
    if NESTED_SELECT_RE.search(proj):       f["scalar_subquery"] = P3
    if CAST_RE.search(s):                   f["cast"] = P2
    if SCALAR_FN_RE.search(s):              f["scalar_fn"] = P2
    if NULL_RE.search(s):                   f["null"] = P4
    if OUTER_JOIN_RE.search(s):             f["outer_join"] = P5
    return f

def required_phase(sql: str) -> int:
    f = features(sql)
    return max(f.values()) if f else P1

# --- run --------------------------------------------------------------------
def load_corpus():
    with open(DATA) as fh:
        return [json.loads(l) for l in fh if l.strip()]

def main():
    records = load_corpus()
    n_records = len(records)
    n_queries = sum(len(r["equivalent_sqls"]) for r in records)

    feat_counts = {}                          # feature -> # queries touching it
    q_phase = []                              # required phase per query
    rec_phase = []                            # required phase per record (max of variants)
    for r in records:
        rmax = P1
        for v in r["equivalent_sqls"]:
            fs = features(v["sql"])
            for name in fs:
                feat_counts[name] = feat_counts.get(name, 0) + 1
            rp = max(fs.values()) if fs else P1
            q_phase.append(rp)
            rmax = max(rmax, rp)
        rec_phase.append(rmax)

    # cumulative unlock curve
    ranks = [P1, P2, P3, P4, P5]
    curve = []
    for k in ranks:
        q_ok = sum(1 for p in q_phase if p <= k)
        r_ok = sum(1 for p in rec_phase if p <= k)
        curve.append((k, q_ok, r_ok))
    out_q = sum(1 for p in q_phase if p == OUT)
    out_r = sum(1 for p in rec_phase if p == OUT)

    # verified-today, from the machine-checked ledger
    verified = {}
    if os.path.exists(RESULT):
        res = json.load(open(RESULT))
        verified = res.get("summary", {})

    summary = {
        "corpus": {"records": n_records, "queries": n_queries},
        "reachable_now_queries": curve[0][1],
        "reachable_now_records": curve[0][2],
        "curve": [{"phase": PHASE_NAME[k], "queries_ok": q, "records_ok": r}
                  for (k, q, r) in curve],
        "out_of_scope": {"queries": out_q, "records": out_r},
        "feature_blocked_queries": dict(sorted(feat_counts.items(),
                                               key=lambda kv: -kv[1])),
        "verified_today": {
            "records_encoded": verified.get("encoded"),
            "pass": verified.get("pass"),
            "pass_under_hypothesis": verified.get("pass_under_hypothesis"),
            "on_disk_now": verified.get("on_disk_now"),
        },
    }

    if "--json" in sys.argv:
        print(json.dumps(summary, indent=2))
        return

    pct = lambda n: f"{100*n/n_queries:5.1f}%"
    pctr = lambda n: f"{100*n/n_records:5.1f}%"
    print(f"SQL-equivalence coverage guard  —  {DATA.split('/')[-1]}")
    print(f"corpus: {n_queries} queries / {n_records} records\n")

    print("feature classifier — queries blocked by each unsupported feature:")
    for name, cnt in summary["feature_blocked_queries"].items():
        print(f"  {name:<16} {cnt:>5}  ({pct(cnt)})  -> {PHASE_NAME[FEATURE_PHASE[name]]}")
    print()

    print("cumulative unlock curve (queries OK / records OK):")
    for (k, q, r) in curve:
        print(f"  {PHASE_NAME[k]:<34} {q:>5} ({pct(q)})   {r:>4} ({pctr(r)})")
    print(f"  {PHASE_NAME[OUT]:<34} {out_q:>5} ({pct(out_q)})   {out_r:>4} ({pctr(out_r)})")
    print()

    v = summary["verified_today"]
    print("verified today (machine-checked, from result.json):")
    if v["records_encoded"] is not None:
        print(f"  encoded records ........ {v['records_encoded']}")
        print(f"  pass (bare sql_equiv) .. {v['pass']}")
        print(f"  pass under hypothesis .. {v['pass_under_hypothesis']}")
        print(f"  files on disk now ...... {v['on_disk_now']}")
    else:
        print("  (result.json has no summary; run gen_result.py)")
    print("\n(POTENTIAL is a heuristic lower bound; VERIFIED is ground truth. "
          "`lake build` must pass for VERIFIED to be trustworthy.)")

if __name__ == "__main__":
    main()
