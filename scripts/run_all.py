#!/usr/bin/env python3
"""Run `sql_equiv` (no LLM) over every Problem in Calcite + Literature + CrossSkill, classify each,
and write a report with ALL errors. Each Problem ends in `:= by first | sql_equiv | sorry`, so:
  RESOLVED  = compiles clean, no `sorry`  -> sql_equiv closed the goal (proved)
  UNPROVED  = compiles with `sorry`       -> sql_equiv failed CLEANLY, sorry took over
  ERROR     = rc!=0 or `error:`           -> parser failure OR uncatchable timeout escaping `first`
  TIMEOUT   = wall-clock cap hit
Usage: run_all.py [tag]   (tag names the output files, default "new")
"""
import os, signal, subprocess, glob, sys, time
from concurrent.futures import ThreadPoolExecutor, as_completed

ROOT = "/home/anirudhgupta/LeanDatabase"
DATASETS = ["Calcite", "Literature", "CrossSkill"]
TIMEOUT = int(os.environ.get("TIMEOUT", "300"))
WORKERS = int(os.environ.get("WORKERS", "12"))
TAG = sys.argv[1] if len(sys.argv) > 1 else "new"
TMPDIR = "/tmp/claude-1016/-home-anirudhgupta-LeanDatabase/91b02a3d-e928-4306-8e57-bd587647c196/scratchpad/runtmp"
os.makedirs(TMPDIR, exist_ok=True)

def run_one(ds, path):
    t = time.time()
    src = open(path).read()
    tmp = None
    if "sql_equiv_llm" in src:                       # force plain sql_equiv: NO LLM / OpenAI calls
        tmp = os.path.join(TMPDIR, f"{ds}_{os.path.basename(path)}")
        open(tmp, "w").write(src.replace("sql_equiv_llm", "sql_equiv"))
        runpath = tmp
    else:
        runpath = path
    # Popen in its OWN process group so a timeout kills lake AND its `lean` grandchild — otherwise the
    # orphaned lean keeps the stdout pipe open and communicate() hangs forever (the leak that stalled us).
    p = subprocess.Popen(["lake", "env", "lean", runpath], cwd=ROOT,
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, start_new_session=True)
    try:
        out, _ = p.communicate(timeout=TIMEOUT); rc = p.returncode
    except subprocess.TimeoutExpired:
        try: os.killpg(os.getpgid(p.pid), signal.SIGKILL)
        except ProcessLookupError: pass
        try: p.communicate(timeout=10)
        except Exception: pass
        return (ds, os.path.basename(path), "TIMEOUT", "", round(time.time() - t, 1))
    finally:
        if tmp:
            try: os.remove(tmp)
            except OSError: pass
    dt = round(time.time() - t, 1)
    # rc-based: only real Lean errors (parser failure, uncatchable deterministic timeout) give rc!=0.
    if rc != 0:
        return (ds, os.path.basename(path), "ERROR", out, dt)
    # NOTE: Lean prints "declaration uses `sorry`" with BACKTICKS — matching 'sorry' with straight
    # quotes silently never fires and mislabels every failed (sorry'd) file as RESOLVED. Match robustly.
    if "declaration uses" in out and "sorry" in out:
        return (ds, os.path.basename(path), "UNPROVED", "", dt)
    return (ds, os.path.basename(path), "RESOLVED", "", dt)

def load_skip():
    """(ds,file) already PROVED in the overnight run — skip them (user: don't re-run the 217)."""
    skip = set()
    csvp = os.path.join(ROOT, "scripts", "overnight_results.csv")
    if os.path.exists(csvp):
        import csv as _csv
        for r in _csv.DictReader(open(csvp)):
            if r["outcome"] == "PROVED":
                skip.add((r["dataset"], r["file"]))
    return skip

def main():
    skip = load_skip()
    jobs = [(ds, p) for ds in DATASETS for p in sorted(glob.glob(f"{ROOT}/Bench/{ds}/Problems/*.lean"))
            if (ds, os.path.basename(p)[:-5]) not in skip]
    print(f"running {len(jobs)} problems ({len(skip)} already-PROVED skipped), {WORKERS} workers, "
          f"timeout {TIMEOUT}s, tag={TAG}", flush=True)
    rows = []; t0 = time.time()
    with ThreadPoolExecutor(max_workers=WORKERS) as ex:
        futs = {ex.submit(run_one, ds, p): (ds, p) for ds, p in jobs}
        for i, f in enumerate(as_completed(futs), 1):
            rows.append(f.result())
            if i % 50 == 0:
                print(f"  {i}/{len(jobs)}  ({round(time.time()-t0)}s)", flush=True)
    # summary
    rep = os.path.join(ROOT, f"run_all_{TAG}.txt")
    with open(rep, "w") as fh:
        fh.write(f"# sql_equiv full run (tag={TAG})  wall={round(time.time()-t0)}s  timeout={TIMEOUT}s\n\n")
        grand = {}
        for ds in DATASETS:
            sub = [r for r in rows if r[0] == ds]
            c = {k: sum(1 for r in sub if r[2] == k) for k in ("RESOLVED","UNPROVED","ERROR","TIMEOUT")}
            for k, v in c.items(): grand[k] = grand.get(k, 0) + v
            fh.write(f"## {ds}: total={len(sub)}  RESOLVED={c['RESOLVED']}  "
                     f"UNPROVED={c['UNPROVED']}  ERROR={c['ERROR']}  TIMEOUT={c['TIMEOUT']}\n")
        fh.write(f"\n## TOTAL: {sum(grand.values())}  RESOLVED={grand['RESOLVED']}  "
                 f"UNPROVED={grand['UNPROVED']}  ERROR={grand['ERROR']}  TIMEOUT={grand['TIMEOUT']}\n")
        fh.write(f"   (resolved = proved by sql_equiv; net resolved rate = "
                 f"{round(100*grand['RESOLVED']/max(1,sum(grand.values())),1)}%)\n\n")
        # error/timeout details
        fh.write("=" * 80 + "\nERRORS AND TIMEOUTS (file : error lines)\n" + "=" * 80 + "\n")
        for ds, name, st, out, dt in sorted(rows):
            if st == "TIMEOUT":
                fh.write(f"\n--- {ds}/{name}  [TIMEOUT {dt}s] ---\n")
            elif st == "ERROR":
                errs = [l for l in out.splitlines() if "error:" in l or "(deterministic) timeout" in l]
                fh.write(f"\n--- {ds}/{name}  [ERROR {dt}s] ---\n")
                for l in errs[:8]: fh.write("  " + l.strip() + "\n")
        # unproved list (compact)
        fh.write("\n" + "=" * 80 + "\nUNPROVED (clean sql_equiv failure -> sorry)\n" + "=" * 80 + "\n")
        for ds in DATASETS:
            u = [name for d, name, st, o, dt in sorted(rows) if d == ds and st == "UNPROVED"]
            fh.write(f"\n{ds} ({len(u)}): " + " ".join(name[:-5] for name in u) + "\n")
    # csv
    import csv
    with open(os.path.join(ROOT, f"run_all_{TAG}.csv"), "w", newline="") as fh:
        w = csv.writer(fh); w.writerow(["dataset","file","status","secs"])
        for ds, name, st, out, dt in sorted(rows): w.writerow([ds, name, st, dt])
    print("wrote", rep, flush=True)
    with open(rep) as fh:
        print("".join(l for l in fh if l.startswith("## ") or l.startswith("   ")))

if __name__ == "__main__":
    main()
