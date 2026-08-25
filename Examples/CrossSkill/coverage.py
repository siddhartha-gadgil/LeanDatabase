#!/usr/bin/env python3
"""CrossSkill coverage guard for CI.

This script is intentionally lightweight for CI. It always reports VERIFIED
coverage using committed artifacts, and reports POTENTIAL only when the full
corpus file is present locally.
"""

from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
bench = ROOT / "Bench" / "CrossSkill"
status_path = bench / "status.json"
proven_dir = bench / "Proven"
corpus_path = bench / "crossskill_equivalent_sql.jsonl"

if not status_path.exists():
    print(f"ERROR: missing status file: {status_path}")
    sys.exit(2)

status = json.loads(status_path.read_text())
summary = status.get("summary", {})
total = int(summary.get("total", 0))
elaborates = int(summary.get("elaborates", 0))

proven_count = len(list(proven_dir.glob("P_*.lean"))) if proven_dir.exists() else 0
verified_pct = (100.0 * proven_count / total) if total else 0.0

print(f"VERIFIED: {proven_count}/{total} ({verified_pct:.1f}%) proven files on disk")
print(f"ELABORATES: {elaborates}/{total}")

if corpus_path.exists():
    with corpus_path.open() as f:
        corpus_total = sum(1 for line in f if line.strip())
    potential_pct = (100.0 * elaborates / corpus_total) if corpus_total else 0.0
    print(f"POTENTIAL: {elaborates}/{corpus_total} ({potential_pct:.1f}%) from corpus")
else:
    print("POTENTIAL: skipped (corpus file not present)")

sys.exit(0)
