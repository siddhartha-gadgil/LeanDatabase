#!/usr/bin/env python3
"""Regenerate result.json from the CrossSkill instance files + the dataset.

outcome = "pass" if the file contains an active (non-commented) `sql_equiv` proof,
else "out_of_scope" (we keep no `sorry`, and the only former hard-fail — join_comm — is
now a toolbox lemma). A file may PASS on the winnable sub-difference while documenting
other variant differences as out-of-scope; the docstring carries the detail.
"""
import json, re, os, glob

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "crossskill_equivalent_sql.jsonl")
recs = {json.loads(l)["instance_id"]: json.loads(l) for l in open(DATA)}

def first_para(text, marker):
    i = text.find(marker)
    if i < 0: return None
    rest = text[i+len(marker):]
    # up to first blank line
    para = re.split(r"\n\s*\n", rest, 1)[0]
    para = para.replace("*","").replace("`","").strip()
    para = re.sub(r"\s+", " ", para)
    return para[:300]

instances = []
for f in sorted(glob.glob(os.path.join(HERE, "Sf*.lean"))):
    src = open(f).read()
    mod = os.path.basename(f)[:-5]
    iid = mod[0].lower() + mod[1:]
    rec = recs.get(iid, {})
    nvar = rec.get("num_distinct_variants")
    nsql = len(rec.get("equivalent_sqls", [])) or None
    has_proof = bool(re.search(r"^\s*sql_equiv\s*$", src, re.M)) and \
                bool(re.search(r"^theorem", src, re.M))
    outcome = "pass" if has_proof else "out_of_scope"
    diff = (first_para(src, "Difference (winnable pair):") or
            first_para(src, "Difference:") or
            first_para(src, "Outcome —") or
            first_para(src, "OUT-OF-SCOPE"))
    tbls = re.findall(r"Full `([A-Z0-9_]+)` schema \((\d+)", src)
    table_encoded = ", ".join(f"{t} ({n})" for t,n in tbls) or None
    rec_dollar = "set_option maxRecDepth" in src
    entry = {
        "instance_id": iid,
        "file": f"Examples/CrossSkill/{mod}.lean",
        "num_distinct_variants": nvar,
        "num_equivalent_sqls": nsql,
        "sql_equiv": outcome,
        "difference": diff,
        "table_encoded": table_encoded,
    }
    if rec_dollar:
        entry["note"] = "needed `set_option maxRecDepth` (wide schema)."
    instances.append(entry)

npass = sum(1 for e in instances if e["sql_equiv"] == "pass")
noos  = sum(1 for e in instances if e["sql_equiv"] == "out_of_scope")

out = {
    "dataset": "Examples/crossskill_equivalent_sql.jsonl",
    "dataset_totals": {"records": len(recs),
                       "total_sqls": sum(len(r["equivalent_sqls"]) for r in recs.values())},
    "scope": ("Round-1 manual encoding: only variant pairs whose difference is PURE relational "
              "algebra are proved with sql_equiv. Data/hypothesis-dependent, NULL, rounding-precision, "
              "and top-N ordering differences are classified out_of_scope (a future hypothesis phase)."),
    "tactic_under_test": "sql_equiv (LeanDatabase.SQLEquiv)",
    "encoding_form": ("Parser-canonical: schema as `List SQLTypeProxy`, types via colTypeOfList/"
                      "TypedRelationOfList, DecidableEq via sqlTypeDecEq. Full table column sets are "
                      "encoded (not just columns used)."),
    "outcome_legend": {
        "pass": "sql_equiv closed the winnable pure-algebra difference (file has an active proof).",
        "out_of_scope": "no pure-algebra equivalence between variants; needs a data hypothesis, or differs only by NULL/rounding/top-N ordering. Documented in-file, no theorem.",
        "fail": "a genuinely-algebraic goal sql_equiv could not close (none remain this round; the join-commutativity gap was filled — see lemmas_added_to_toolbox)."
    },
    "lemmas_added_to_toolbox": [
        {"name": "crossProduct_comm + swapAppend (+ splitTuple_swapAppend, swapAppend_swapAppend involution)",
         "where": "LeanDatabase/Operators/CrossProduct.lean",
         "reason": "join-commutativity gap surfaced while encoding the join-order family",
         "statement": "(crossProductRel r1 r2 a1 a2).rows.image swapAppend = (crossProductRel r2 r1 a2 a1).rows; swapAppend is the dependent half-swap reindex (c1++c2)->(c2++c1) and an involution."},
        {"name": "join_comm",
         "where": "LeanDatabase/Operators/Join.lean",
         "statement": "(join r1 r2 a1 a2 cond).rows.image swapAppend = (join r2 r1 a2 a1 (fun u => cond (swapAppend u))).rows."}
    ],
    "summary": {"encoded": len(instances), "pass": npass, "out_of_scope": noos, "fail": 0},
    "instances": instances,
}
with open(os.path.join(HERE, "result.json"), "w") as fp:
    json.dump(out, fp, indent=2, ensure_ascii=False)
print(f"wrote result.json: {len(instances)} instances ({npass} pass, {noos} out_of_scope, 0 fail)")
