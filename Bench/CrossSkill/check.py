#!/usr/bin/env python3
"""Combined verification gate: BOTH proofs and elaboration must hold.

The `Proven/` theorems (`sql_equiv` proofs) are NOT in the lake glob, so `lake build` never checks
them — a change can regress a real proof unnoticed. Run this after any change to core elaboration
(`expandNames`, `withLetColumnVars`, the tactic, aggregate/operator shapes):

    python3 check.py            # proofs only (fast — the regression guard)
    python3 check.py --census   # proofs + full isolated elaboration census (slow)

Exit code = number of regressed proofs (0 = clean).
"""
import subprocess, glob, os, sys
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

def check_file(f):
    p = subprocess.run(['lake', 'env', 'lean', f], cwd=ROOT, capture_output=True, text=True)
    out = (p.stdout or '') + (p.stderr or '')
    errs = [l for l in out.splitlines() if 'error' in l]
    return (os.path.basename(f), not errs, errs[:1])

proven = sorted(glob.glob(os.path.join(os.path.dirname(__file__), 'Proven', 'P_*.lean')))
print(f"checking {len(proven)} proven theorems (must all still prove)...", file=sys.stderr)
with ThreadPoolExecutor(max_workers=5) as ex:
    res = list(ex.map(check_file, proven))
regressed = [(n, e) for n, ok, e in res if not ok]
print(f"PROVEN: {len(res) - len(regressed)}/{len(res)} prove")
for n, e in regressed:
    print(f"  REGRESSED {n}: {e}")

if '--census' in sys.argv:
    print("running elaboration census (dump_failures.py all)...", file=sys.stderr)
    subprocess.run([sys.executable, os.path.join(os.path.dirname(__file__), 'dump_failures.py'), 'all'],
                   cwd=os.path.dirname(__file__))

sys.exit(len(regressed))
