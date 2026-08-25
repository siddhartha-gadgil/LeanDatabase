#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["sqlglot>=25"]
# ///
"""
HTTP wrapper for `sql_process`.

GET  /      serves a demo page.
POST /      accepts the JSON payload expected by LeanDatabase.Parser.checkEquiv
            and returns the JSON line produced by `sql_process`.

The HTTP layer is stdlib-only; `sqlglot` is used solely to enumerate input dialects and transpile
them to the canonical PostgreSQL the prover works over. `uv run sql_server.py` installs it from the
inline script metadata above; without it the demo falls back to PostgreSQL-only input.
"""

from __future__ import annotations

import argparse
import html
import json
import os
import queue
import socket
import subprocess
import sys
import threading
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

PORT = 6767
REQUEST_TIMEOUT_SECONDS = 300.0
MAX_BODY_BYTES = 1_000_000

# The prover works over ONE canonical dialect (PostgreSQL); any other input dialect is transpiled to it
# via sqlglot before being sent to Lean. `transpile.py` lives with the corpus tooling.
sys.path.insert(0, str(Path(__file__).resolve().parent / "Bench" / "CrossSkill"))
try:
    from transpile import transpile_sql
except Exception:  # noqa: BLE001 — sqlglot may be absent; then only PostgreSQL input is accepted
    transpile_sql = None


def is_postgres_dialect(dialect: str | None) -> bool:
    return (dialect or "postgres").strip().lower() in ("", "postgres", "postgresql", "pg")


def transpile_queries(queries: list[str], dialect: str | None) -> tuple[list[str], list[str | None]]:
    """Transpile each query from `dialect` to PostgreSQL. Identity when the input already is PostgreSQL
    (or sqlglot is unavailable). Returns (converted_queries, per-query error-or-None)."""
    if is_postgres_dialect(dialect) or transpile_sql is None:
        return list(queries), [None] * len(queries)
    out, errs = [], []
    for q in queries:
        pg, err = transpile_sql(q, read=dialect, write="postgres")
        out.append(pg); errs.append(err)
    return out, errs


class SqlProcess:
    def __init__(
        self,
        repo_dir: Path,
        timeout: float = REQUEST_TIMEOUT_SECONDS,
        warmup: bool = True,
    ) -> None:
        self.repo_dir = repo_dir
        self.timeout = timeout
        self.warmup = warmup
        self.lock = threading.Lock()
        self.ready = threading.Event()
        self.stderr_lines: "queue.Queue[str]" = queue.Queue(maxsize=200)
        self.responses: "queue.Queue[Any]" = queue.Queue()
        self.proc: subprocess.Popen[str] | None = None
        self.start()

    def start(self) -> None:
        self.ready.clear()
        self._clear_responses()
        command = self._process_command()
        print(f"Starting {' '.join(command)}", file=sys.stderr, flush=True)
        self.proc = subprocess.Popen(
            command,
            cwd=self.repo_dir,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
        )
        threading.Thread(target=self._drain_stderr, daemon=True).start()
        threading.Thread(target=self._drain_stdout, daemon=True).start()

    def stop(self) -> None:
        proc = self.proc
        if proc is not None and proc.poll() is None:
            proc.terminate()

    def _process_command(self) -> list[str]:
        binary = self.repo_dir / ".lake" / "build" / "bin" / "sql_process"
        if binary.exists() and not self._compiled_binary_is_stale(binary):
            return ["lake", "env", str(binary)]
        return ["lake", "exe", "sql_process"]

    def _compiled_binary_is_stale(self, binary: Path) -> bool:
        binary_mtime = binary.stat().st_mtime
        tracked_inputs = [
            self.repo_dir / "sql_process.lean",
            self.repo_dir / "lakefile.toml",
            self.repo_dir / "lake-manifest.json",
            self.repo_dir / "lean-toolchain",
        ]
        for path in tracked_inputs:
            if path.exists() and path.stat().st_mtime > binary_mtime:
                return True

        lean_database_dir = self.repo_dir / "LeanDatabase"
        if lean_database_dir.exists():
            for path in lean_database_dir.rglob("*.lean"):
                if path.stat().st_mtime > binary_mtime:
                    return True
        return False

    def wait_until_ready(self) -> None:
        deadline = time.monotonic() + self.timeout
        next_notice = time.monotonic()
        while not self.ready.is_set():
            proc = self.proc
            if proc is not None and proc.poll() is not None:
                raise RuntimeError(
                    f"sql_process exited before readiness with code {proc.returncode}"
                )
            now = time.monotonic()
            if now >= deadline:
                raise TimeoutError(
                    "timed out waiting for sql_process readiness on stderr"
                )
            if now >= next_notice:
                print(
                    "Waiting for sql_process readiness...",
                    file=sys.stderr,
                    flush=True,
                )
                next_notice = now + 10.0
            self.ready.wait(timeout=min(1.0, deadline - now))
        print("sql_process is ready", file=sys.stderr, flush=True)

    def warm_up(self, payload: Any) -> None:
        started = time.monotonic()
        print(
            "Warming sql_process with a sample equivalence check...",
            file=sys.stderr,
            flush=True,
        )
        response = self.request(payload)
        elapsed = time.monotonic() - started
        if not (
            isinstance(response, dict)
            and response.get("status") == "ok"
            and response.get("equivalent") is True
        ):
            raise RuntimeError(f"sql_process warmup failed: {response!r}")
        print(
            f"sql_process warmup completed in {elapsed:.3f}s",
            file=sys.stderr,
            flush=True,
        )

    def _clear_responses(self) -> None:
        while True:
            try:
                self.responses.get_nowait()
            except queue.Empty:
                return

    def _drain_stderr(self) -> None:
        proc = self.proc
        if proc is None or proc.stderr is None:
            return
        for line in proc.stderr:
            line = line.rstrip("\n")
            print(f"[sql_process] {line}", file=sys.stderr, flush=True)
            if "Ready to process equivalence checks." in line:
                self.ready.set()
            try:
                self.stderr_lines.put_nowait(line)
            except queue.Full:
                try:
                    self.stderr_lines.get_nowait()
                except queue.Empty:
                    pass
                self.stderr_lines.put_nowait(line)

    def _drain_stdout(self) -> None:
        proc = self.proc
        if proc is None or proc.stdout is None:
            return
        for raw_line in proc.stdout:
            line = raw_line.rstrip("\n")
            stripped = line.strip()
            if not stripped:
                continue
            try:
                parsed = json.loads(stripped)
            except json.JSONDecodeError:
                print(f"[sql_process] {line}", file=sys.stderr, flush=True)
                continue
            if isinstance(parsed, dict) and parsed.get("status") in {"ok", "error"}:
                self.responses.put(parsed)
            else:
                print(f"[sql_process] {line}", file=sys.stderr, flush=True)

    def recent_stderr(self) -> list[str]:
        return list(self.stderr_lines.queue)

    def request(self, payload: Any) -> Any:
        encoded = json.dumps(payload, separators=(",", ":"))
        with self.lock:
            proc = self.proc
            if (
                proc is None
                or proc.poll() is not None
                or proc.stdin is None
                or proc.stdout is None
            ):
                self.start()
                proc = self.proc
                if proc is None or proc.stdin is None or proc.stdout is None:
                    raise RuntimeError("failed to start sql_process")

            if not self.ready.wait(timeout=self.timeout):
                raise TimeoutError(
                    "timed out waiting for sql_process readiness on stderr"
                )

            proc.stdin.write(encoded + "\n")
            proc.stdin.flush()

            deadline = time.monotonic() + self.timeout
            while True:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise TimeoutError("timed out waiting for sql_process")
                if proc.poll() is not None:
                    raise RuntimeError(
                        f"sql_process exited unexpectedly with code {proc.returncode}"
                    )
                try:
                    return self.responses.get(timeout=min(0.2, remaining))
                except queue.Empty:
                    continue


class Handler(BaseHTTPRequestHandler):
    server_version = "LeanDatabaseSqlServer/0.1"

    def do_OPTIONS(self) -> None:
        self.send_response(HTTPStatus.NO_CONTENT)
        self._cors_headers()
        self.end_headers()

    def do_GET(self) -> None:
        if self.path not in ("/", "/index.html"):
            self._send_json({"status": "error", "message": "Not found"}, HTTPStatus.NOT_FOUND)
            return
        body = demo_html().encode("utf-8")
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:
        length_header = self.headers.get("Content-Length")
        if length_header is None:
            self._send_json(
                {"status": "error", "message": "Missing Content-Length"},
                HTTPStatus.LENGTH_REQUIRED,
            )
            return
        try:
            length = int(length_header)
        except ValueError:
            self._send_json(
                {"status": "error", "message": "Invalid Content-Length"},
                HTTPStatus.BAD_REQUEST,
            )
            return
        if length > MAX_BODY_BYTES:
            self._send_json(
                {"status": "error", "message": "Request body too large"},
                HTTPStatus.REQUEST_ENTITY_TOO_LARGE,
            )
            return

        raw = self.rfile.read(length)
        try:
            payload = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            self._send_json(
                {"status": "error", "message": f"Invalid JSON: {exc}"},
                HTTPStatus.BAD_REQUEST,
            )
            return

        # `/transpile` — preview only: convert the queries to PostgreSQL and return them (no proof).
        if self.path == "/transpile":
            queries = payload.get("queries") or []
            converted, errs = transpile_queries(queries, payload.get("dialect"))
            self._send_json(
                {"status": "ok", "queries": converted, "errors": errs,
                 "dialect": payload.get("dialect") or "postgres"},
                HTTPStatus.OK,
            )
            return

        # Normalise to PostgreSQL before proving; keep the source dialect in the payload so the Lean
        # side has the input language available (future per-dialect handling, e.g. casts).
        dialect = payload.get("dialect")
        converted, errs = transpile_queries(payload.get("queries") or [], dialect)
        forward = {**payload, "queries": converted}

        try:
            response = self.server.sql_process.request(forward)  # type: ignore[attr-defined]
        except Exception as exc:
            self._send_json(
                {
                    "status": "error",
                    "message": str(exc),
                    "recentStderr": self.server.sql_process.recent_stderr()[-20:],  # type: ignore[attr-defined]
                },
                HTTPStatus.BAD_GATEWAY,
            )
            return
        if isinstance(response, dict):
            response = {**response, "sourceDialect": dialect or "postgres"}
            if not is_postgres_dialect(dialect):
                response["convertedQueries"] = converted
            transpile_errors = [e for e in errs if e]
            if transpile_errors:
                response["transpileErrors"] = transpile_errors
        self._send_json(response, HTTPStatus.OK)

    def _cors_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _send_json(self, payload: Any, status: HTTPStatus) -> None:
        body = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(status)
        self._cors_headers()
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: Any) -> None:
        print(
            f"{self.address_string()} - {self.log_date_time_string()} - {format % args}",
            file=sys.stderr,
        )


class SqlServer(ThreadingHTTPServer):
    sql_process: SqlProcess


DEFAULT_DEMO = {
    "schemas": [
        {
            "name": "table",
            "columns": [
                {"name": "age", "type": "Int"},
                {"name": "isActive", "type": "Bool"},
            ],
        }
    ],
    "queries": [
        "SELECT * FROM table WHERE age > 30 && isActive",
        "SELECT * FROM table WHERE age > 30 && isActive && age > 20",
    ],
}


TABLE_AGE_ACTIVE_HEIGHT = {
    "name": "table",
    "columns": [
        {"name": "age", "type": "Int"},
        {"name": "isActive", "type": "Bool"},
        {"name": "height", "type": "Float"},
    ],
}


EXAMPLE_GROUPS = [
    {
        "label": "Boolean examples",
        "examples": [
            {
                "label": "Example0: AND reorder",
                "schemas": [TABLE_AGE_ACTIVE_HEIGHT],
                "queries": [
                    "SELECT * FROM table WHERE age > 30 AND isActive",
                    "SELECT * FROM table WHERE isActive AND age > 30",
                ],
            },
            {
                "label": "Example0: AND idempotent",
                "schemas": [TABLE_AGE_ACTIVE_HEIGHT],
                "queries": [
                    "SELECT * FROM table WHERE isActive AND isActive",
                    "SELECT * FROM table WHERE isActive",
                ],
            },
            {
                "label": "Example0: comparison reorder",
                "schemas": [TABLE_AGE_ACTIVE_HEIGHT],
                "queries": [
                    "SELECT * FROM table WHERE age > 30 AND height < 180",
                    "SELECT * FROM table WHERE height < 180 AND age > 30",
                ],
            },
            {
                "label": "Example0: double negation",
                "schemas": [TABLE_AGE_ACTIVE_HEIGHT],
                "queries": [
                    "SELECT * FROM table WHERE NOT (NOT isActive)",
                    "SELECT * FROM table WHERE isActive",
                ],
            },
            {
                "label": "Example0: De Morgan",
                "schemas": [TABLE_AGE_ACTIVE_HEIGHT],
                "queries": [
                    "SELECT * FROM table WHERE NOT (age > 30 OR isActive)",
                    "SELECT * FROM table WHERE NOT (age > 30) AND NOT isActive",
                ],
            },
            {
                "label": "Example0: OR idempotent",
                "schemas": [TABLE_AGE_ACTIVE_HEIGHT],
                "queries": [
                    "SELECT * FROM table WHERE isActive OR isActive",
                    "SELECT * FROM table WHERE isActive",
                ],
            },
            {
                "label": "Example0: repeated comparison",
                "schemas": [TABLE_AGE_ACTIVE_HEIGHT],
                "queries": [
                    "SELECT * FROM table WHERE age > 30 AND age > 30",
                    "SELECT * FROM table WHERE age > 30",
                ],
            },
            {
                "label": "Example0: absorption",
                "schemas": [TABLE_AGE_ACTIVE_HEIGHT],
                "queries": [
                    "SELECT * FROM table WHERE isActive OR (isActive AND age > 30)",
                    "SELECT * FROM table WHERE isActive",
                ],
            },
            {
                "label": "Example0: OR reorder",
                "schemas": [TABLE_AGE_ACTIVE_HEIGHT],
                "queries": [
                    "SELECT * FROM table WHERE isActive OR age > 30",
                    "SELECT * FROM table WHERE age > 30 OR isActive",
                ],
            },
            {
                "label": "Example0: AND distributes over OR",
                "schemas": [TABLE_AGE_ACTIVE_HEIGHT],
                "queries": [
                    "SELECT * FROM table WHERE age > 30 AND (isActive OR height < 180)",
                    "SELECT * FROM table WHERE (age > 30 AND isActive) OR (age > 30 AND height < 180)",
                ],
            },
        ],
    },
    {
        "label": "Relational examples",
        "examples": [
            {
                "label": "Example1: predicate pushdown through UNION",
                "schemas": [
                    {
                        "name": "r1",
                        "columns": [
                            {"name": "is_high_value", "type": "Bool"},
                            {"name": "val", "type": "Int"},
                        ],
                    },
                    {
                        "name": "r2",
                        "columns": [
                            {"name": "is_high_value", "type": "Bool"},
                            {"name": "val", "type": "Int"},
                        ],
                    },
                ],
                "queries": [
                    "SELECT * FROM (SELECT * FROM r1 UNION SELECT * FROM r2) AS u WHERE is_high_value",
                    "SELECT * FROM r1 WHERE r1.is_high_value UNION SELECT * FROM r2 WHERE r2.is_high_value",
                ],
            },
            {
                "label": "Example2: cascading selection",
                "schemas": [
                    {
                        "name": "table",
                        "columns": [
                            {"name": "is_active", "type": "Bool"},
                            {"name": "is_high_value", "type": "Bool"},
                        ],
                    }
                ],
                "queries": [
                    "SELECT * FROM (SELECT * FROM table WHERE is_active) AS r WHERE is_high_value",
                    "SELECT * FROM table WHERE is_high_value AND is_active",
                ],
            },
            {
                "label": "Example4: combined anti-set",
                "schemas": [
                    {
                        "name": "tableA",
                        "columns": [
                            {"name": "is_active", "type": "Bool"},
                            {"name": "is_banned", "type": "Bool"},
                        ],
                    },
                    {
                        "name": "tableB",
                        "columns": [
                            {"name": "is_active", "type": "Bool"},
                            {"name": "is_banned", "type": "Bool"},
                        ],
                    },
                ],
                "queries": [
                    "(SELECT * FROM tableA WHERE tableA.is_active UNION SELECT * FROM tableB WHERE tableB.is_active) EXCEPT SELECT * FROM (SELECT * FROM tableA UNION SELECT * FROM tableB) AS u WHERE is_banned",
                    "SELECT * FROM (SELECT * FROM tableA UNION SELECT * FROM tableB) AS u WHERE is_active AND NOT is_banned",
                ],
            },
            {
                "label": "Example5: EXISTS equals IN",
                "schemas": [
                    {
                        "name": "customers",
                        "columns": [
                            {"name": "customer_id", "type": "Int"},
                            {"name": "name", "type": "String"},
                        ],
                    },
                    {
                        "name": "orders",
                        "columns": [
                            {"name": "customer_id", "type": "Int"},
                            {"name": "total", "type": "Int"},
                        ],
                    },
                ],
                "queries": [
                    "SELECT * FROM customers WHERE EXISTS (SELECT * FROM orders WHERE orders.customer_id = customers.customer_id)",
                    "SELECT * FROM customers WHERE customers.customer_id IN (SELECT orders.customer_id FROM orders)",
                ],
            },
            {
                "label": "Example8: NOT IN equals NOT EXISTS",
                "schemas": [
                    {
                        "name": "customers",
                        "columns": [
                            {"name": "customer_id", "type": "Int"},
                            {"name": "name", "type": "String"},
                        ],
                    },
                    {
                        "name": "orders",
                        "columns": [
                            {"name": "customer_id", "type": "Int"},
                            {"name": "total", "type": "Int"},
                        ],
                    },
                ],
                "queries": [
                    "SELECT * FROM customers WHERE customers.customer_id NOT IN (SELECT orders.customer_id FROM orders)",
                    "SELECT * FROM customers WHERE NOT EXISTS (SELECT * FROM orders WHERE orders.customer_id = customers.customer_id)",
                ],
            },
            {
                "label": "Example10: OR equals UNION",
                "schemas": [
                    {
                        "name": "table",
                        "columns": [
                            {"name": "status", "type": "String"},
                            {"name": "priority", "type": "String"},
                        ],
                    }
                ],
                "queries": [
                    "SELECT * FROM table WHERE status = 'open' OR priority = 'high'",
                    "SELECT * FROM table WHERE status = 'open' UNION SELECT * FROM table WHERE priority = 'high'",
                ],
            },
            {
                "label": "Example10: OR equals disjoint UNION ALL",
                "schemas": [
                    {
                        "name": "table",
                        "columns": [
                            {"name": "status", "type": "String"},
                            {"name": "priority", "type": "String"},
                        ],
                    }
                ],
                "queries": [
                    "SELECT * FROM table WHERE status = 'open' OR priority = 'high'",
                    "SELECT * FROM table WHERE status = 'open' UNION ALL SELECT * FROM table WHERE priority = 'high' AND status <> 'open'",
                ],
            },
            {
                "label": "Example13: UNION absorption",
                "schemas": [
                    {
                        "name": "table",
                        "columns": [
                            {"name": "age", "type": "Int"},
                            {"name": "isActive", "type": "Bool"},
                        ],
                    },
                    {
                        "name": "table2",
                        "columns": [
                            {"name": "age", "type": "Int"},
                            {"name": "isActive", "type": "Bool"},
                        ],
                    },
                ],
                "queries": [
                    "SELECT * FROM table UNION (SELECT * FROM table INTERSECT SELECT * FROM table2)",
                    "SELECT * FROM table",
                ],
            },
            {
                "label": "Example16: DISTINCT and cascading WHERE",
                "schemas": [
                    {
                        "name": "R",
                        "columns": [
                            {"name": "a", "type": "Int"},
                            {"name": "b", "type": "Int"},
                            {"name": "p", "type": "Bool"},
                            {"name": "q", "type": "Bool"},
                        ],
                    }
                ],
                "queries": [
                    "SELECT DISTINCT a + b AS g FROM (SELECT * FROM (SELECT * FROM R WHERE q) AS x WHERE p) AS y",
                    "SELECT a + b AS g FROM R WHERE p AND q",
                ],
            },
        ],
    },
    {
        "label": "Hypothesis examples",
        "examples": [
            {
                "label": "WHERE dropped: every row is valid",
                "schemas": [
                    {
                        "name": "orders",
                        "columns": [
                            {"name": "qty", "type": "Int"},
                            {"name": "valid", "type": "Bool"},
                        ],
                    }
                ],
                "hypotheses": [{"table": "orders", "predicate": "valid"}],
                "queries": [
                    "SELECT qty FROM orders WHERE valid",
                    "SELECT qty FROM orders",
                ],
            },
            {
                "label": "Column bridge: total = qty * price",
                "schemas": [
                    {
                        "name": "orders",
                        "columns": [
                            {"name": "qty", "type": "Int"},
                            {"name": "price", "type": "Int"},
                            {"name": "total", "type": "Int"},
                        ],
                    }
                ],
                "hypotheses": [{"table": "orders", "predicate": "total = qty * price"}],
                "queries": [
                    "SELECT total AS amount FROM orders",
                    "SELECT qty * price AS amount FROM orders",
                ],
            },
            {
                "label": "Chained assumptions: bridge + nonneg drop WHERE",
                "schemas": [
                    {
                        "name": "orders",
                        "columns": [
                            {"name": "qty", "type": "Int"},
                            {"name": "price", "type": "Int"},
                            {"name": "total", "type": "Int"},
                        ],
                    }
                ],
                "hypotheses": [
                    {"table": "orders", "predicate": "total = qty * price"},
                    {"table": "orders", "predicate": "total >= 0"},
                ],
                "queries": [
                    "SELECT qty * price AS amount FROM orders WHERE total >= 0",
                    "SELECT total AS amount FROM orders",
                ],
            },
            {
                "label": "GROUP BY collapse under functional dependency a -> b",
                "schemas": [
                    {
                        "name": "emp",
                        "columns": [
                            {"name": "a", "type": "Int"},
                            {"name": "b", "type": "Int"},
                        ],
                    }
                ],
                "hypotheses": [{"table": "emp", "funcdep": ["a", "b"]}],
                "queries": [
                    "SELECT a, COUNT(*) AS c FROM emp GROUP BY a, b",
                    "SELECT a, COUNT(*) AS c FROM emp GROUP BY a",
                ],
            },
        ],
    },
]


DIALECT_LABELS = {
    "postgres": "PostgreSQL (default)", "tsql": "SQL Server (T-SQL)",
    "bigquery": "BigQuery", "mysql": "MySQL", "duckdb": "DuckDB", "clickhouse": "ClickHouse",
    "sqlite": "SQLite", "redshift": "Redshift", "spark": "Spark SQL", "spark2": "Spark SQL 2",
    "databricks": "Databricks", "trino": "Trino", "presto": "Presto", "snowflake": "Snowflake",
    "oracle": "Oracle", "teradata": "Teradata", "starrocks": "StarRocks", "risingwave": "RisingWave",
    "materialize": "Materialize",
}


def dialect_options_html() -> str:
    """`<option>`s for every dialect sqlglot supports, PostgreSQL first (selected/default)."""
    try:
        from sqlglot.dialects.dialect import Dialects
        vals = sorted(d.value for d in Dialects if d.value)
    except Exception:  # noqa: BLE001 — sqlglot absent: offer PostgreSQL only
        vals = ["postgres"]
    others = [v for v in vals if v != "postgres"]
    opts = [f'<option value="postgres" selected>{DIALECT_LABELS["postgres"]}</option>']
    opts += [f'<option value="{html.escape(v)}">{html.escape(DIALECT_LABELS.get(v, v))}</option>'
             for v in others]
    return "\n        ".join(opts)


def demo_html() -> str:
    initial = DEFAULT_DEMO
    initial_json = html.escape(json.dumps(initial, indent=2))
    examples_json = json.dumps(EXAMPLE_GROUPS)
    dialect_options = dialect_options_html()
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>LeanDatabase SQL Equivalence</title>
  <style>
    :root {{
      color-scheme: light dark;
      --bg: #f7f7f4;
      --panel: #ffffff;
      --text: #1d2428;
      --muted: #5f6b72;
      --line: #d8ddd8;
      --accent: #16615d;
      --accent-2: #2f6f31;
      --danger: #9e2f2f;
      --code: #eef3f1;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }}
    @media (prefers-color-scheme: dark) {{
      :root {{
        --bg: #171b1c;
        --panel: #202627;
        --text: #edf1ef;
        --muted: #a7b1ad;
        --line: #384244;
        --accent: #6fb7aa;
        --accent-2: #8fc77f;
        --danger: #ef8f8f;
        --code: #141819;
      }}
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      background: var(--bg);
      color: var(--text);
      font-size: 15px;
      line-height: 1.45;
    }}
    header {{
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      gap: 16px;
      padding: 24px clamp(16px, 4vw, 48px) 14px;
      border-bottom: 1px solid var(--line);
      background: var(--panel);
    }}
    h1 {{
      margin: 0 0 4px;
      font-size: clamp(24px, 3vw, 36px);
      font-weight: 700;
      letter-spacing: 0;
    }}
    header p {{
      margin: 0;
      color: var(--muted);
      max-width: 760px;
    }}
    .gh-link {{
      display: inline-flex;
      align-items: center;
      gap: 7px;
      flex: none;
      text-decoration: none;
      color: var(--text);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 8px 12px;
      font-weight: 650;
      font-size: 13.5px;
      white-space: nowrap;
    }}
    .gh-link:hover {{ border-color: var(--accent); color: var(--accent); }}
    .gh-link svg {{ width: 18px; height: 18px; fill: currentColor; }}
    main {{
      display: grid;
      grid-template-columns: minmax(320px, 0.95fr) minmax(360px, 1.05fr);
      gap: 18px;
      padding: 18px clamp(16px, 4vw, 48px) 32px;
    }}
    section {{
      min-width: 0;
    }}
    .panel {{
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 16px;
    }}
    h2 {{
      margin: 0 0 12px;
      font-size: 16px;
      font-weight: 700;
      letter-spacing: 0;
    }}
    label {{
      display: block;
      margin: 12px 0 6px;
      font-weight: 650;
      color: var(--text);
    }}
    textarea, input, select {{
      width: 100%;
      border: 1px solid var(--line);
      border-radius: 6px;
      background: var(--panel);
      color: var(--text);
      font: inherit;
    }}
    textarea {{
      min-height: 104px;
      resize: vertical;
      padding: 10px 11px;
      font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
      font-size: 13px;
      line-height: 1.5;
    }}
    input, select {{
      height: 38px;
      padding: 0 9px;
    }}
    .schema-card {{
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 12px;
      margin: 10px 0;
    }}
    .schema-title {{
      display: grid;
      grid-template-columns: auto minmax(90px, 1fr) 36px;
      gap: 8px;
      align-items: center;
      margin-bottom: 10px;
    }}
    .tag {{
      display: inline-block;
      padding: 3px 9px;
      border-radius: 999px;
      background: var(--code);
      border: 1px solid var(--line);
      color: var(--muted);
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.04em;
      text-transform: uppercase;
    }}
    .hyp-card {{
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 12px;
      margin: 10px 0;
    }}
    .hyp-card-head {{
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 10px;
    }}
    .hyp-grid {{
      display: grid;
      grid-template-columns: minmax(80px, 0.8fr) 120px minmax(140px, 1.7fr);
      gap: 8px;
      align-items: end;
    }}
    .field {{ min-width: 0; }}
    .field .mini {{
      display: block;
      margin: 0 0 4px;
      color: var(--muted);
      font-size: 11.5px;
      font-weight: 700;
    }}
    @media (max-width: 520px) {{
      .hyp-grid {{ grid-template-columns: 1fr; }}
    }}
    .schema-head, .schema-row {{
      display: grid;
      grid-template-columns: minmax(92px, 1fr) 110px 36px;
      gap: 8px;
      align-items: center;
    }}
    .schema-head {{
      color: var(--muted);
      font-size: 12px;
      font-weight: 700;
      margin: 2px 0 6px;
    }}
    .schema-row {{ margin-bottom: 8px; }}
    .add-row {{
      display: flex;
      align-items: center;
      gap: 8px;
      margin-top: 10px;
    }}
    .info-badge {{
      position: relative;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 20px;
      height: 20px;
      border-radius: 50%;
      border: 1px solid var(--line);
      color: var(--muted);
      font-size: 12px;
      font-weight: 700;
      font-style: normal;
      cursor: help;
      user-select: none;
    }}
    .info-badge:hover {{ border-color: var(--accent); color: var(--accent); }}
    .info-badge .tooltip {{
      position: absolute;
      bottom: calc(100% + 8px);
      left: 50%;
      transform: translateX(-50%);
      width: min(340px, 78vw);
      background: var(--panel);
      color: var(--text);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 10px 12px;
      font-size: 12.5px;
      font-weight: 400;
      line-height: 1.5;
      box-shadow: 0 6px 20px rgba(0,0,0,0.18);
      opacity: 0;
      visibility: hidden;
      transition: opacity 0.12s ease;
      z-index: 20;
    }}
    .info-badge .tooltip code {{
      background: var(--code);
      border-radius: 4px;
      padding: 0 4px;
    }}
    .info-badge:hover .tooltip, .info-badge:focus .tooltip {{ opacity: 1; visibility: visible; }}
    .example-picker {{ margin-bottom: 14px; }}
    button {{
      min-height: 38px;
      border: 1px solid var(--line);
      border-radius: 6px;
      background: var(--panel);
      color: var(--text);
      cursor: pointer;
      font: inherit;
      font-weight: 700;
      padding: 0 12px;
    }}
    button:hover {{ border-color: var(--accent); }}
    .primary {{
      background: var(--accent);
      border-color: var(--accent);
      color: #fff;
    }}
    .danger {{
      color: var(--danger);
      padding: 0;
      width: 36px;
    }}
    .actions {{
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 14px;
    }}
    .examples {{
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin: 8px 0 0;
    }}
    .examples button {{
      min-height: 32px;
      font-size: 13px;
      font-weight: 650;
    }}
    pre {{
      margin: 0;
      white-space: pre-wrap;
      overflow-wrap: anywhere;
      background: var(--code);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 12px;
      min-height: 148px;
      font: 13px/1.5 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    }}
    .status {{
      margin: 10px 0 0;
      color: var(--muted);
      min-height: 22px;
    }}
    .result-ok {{ color: var(--accent-2); font-weight: 700; }}
    .result-error {{ color: var(--danger); font-weight: 700; }}
    .hint {{ margin: 6px 0 0; color: var(--muted); font-size: 12.5px; line-height: 1.4; }}
    .muted {{ color: var(--muted); font-weight: 400; font-size: 12.5px; }}
    .stack {{
      display: grid;
      gap: 14px;
    }}
    @media (max-width: 880px) {{
      main {{ grid-template-columns: 1fr; }}
    }}
  </style>
</head>
<body>
  <header>
    <div>
      <h1>LeanDatabase SQL Equivalence</h1>
      <p>Build named schemas and SQL query pairs, then send the generated JSON to the Lean <code>sql_equiv</code>-backed checker.</p>
    </div>
    <a class="gh-link" href="https://github.com/siddhartha-gadgil/LeanDatabase" target="_blank" rel="noopener">
      <svg viewBox="0 0 16 16" aria-hidden="true"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0016 8c0-4.42-3.58-8-8-8z"/></svg>
      GitHub
    </a>
  </header>
  <main>
    <section class="panel">
      <h2>Query Pair</h2>
      <label for="examplePicker">Load an example</label>
      <select id="examplePicker" class="example-picker"></select>

      <label for="dialect">Input SQL dialect</label>
      <select id="dialect">
        {dialect_options}
      </select>
      <p class="hint">Proofs run over one canonical dialect (PostgreSQL). Other dialects are transpiled
      to it with sqlglot — the converted SQL is what the prover actually receives.</p>

      <div id="schemas"></div>
      <div id="hypotheses"></div>
      <div class="add-row">
        <button type="button" id="addSchema">+ Table</button>
        <button type="button" id="addHypothesis">+ Hypothesis</button>
        <span class="info-badge" tabindex="0" aria-label="About hypotheses">i<span class="tooltip">Optional <code>HYPOTHESIS</code> facts. Each is assumed about a table's rows, so
        equivalences that only hold under it become provable — while staying sound (the assumption is
        explicit). Kinds: <code>predicate</code> (every row satisfies a bool expr),
        <code>funcdep</code> (<code>a, b</code> ⟹ a→b), <code>unique</code> (<code>k</code> is a key),
        <code>bijection</code> (<code>a, b</code> same partition).</span></span>
      </div>

      <label for="first">First query</label>
      <textarea id="first" spellcheck="false"></textarea>

      <label for="second">Second query</label>
      <textarea id="second" spellcheck="false"></textarea>

      <div class="actions">
        <button class="primary" type="button" id="check">Check equivalence</button>
        <button type="button" id="reset">Reset</button>
      </div>
      <div id="status" class="status"></div>
    </section>

    <section class="stack">
      <div class="panel" id="convertedPanel" style="display:none">
        <h2>Converted to PostgreSQL <span id="convertedFrom" class="muted"></span></h2>
        <pre id="convertedSql">-</pre>
      </div>
      <div class="panel">
        <h2>JSON Sent</h2>
        <pre id="requestJson">{initial_json}</pre>
      </div>
      <div class="panel">
        <h2>JSON Received</h2>
        <pre id="responseJson">No request sent yet.</pre>
      </div>
    </section>
  </main>

  <script>
    const initial = {json.dumps(initial)};
    const exampleGroups = {examples_json};

    const schemasEl = document.querySelector("#schemas");
    const first = document.querySelector("#first");
    const second = document.querySelector("#second");
    const requestJson = document.querySelector("#requestJson");
    const responseJson = document.querySelector("#responseJson");
    const statusLine = document.querySelector("#status");
    const dialect = document.querySelector("#dialect");
    const convertedPanel = document.querySelector("#convertedPanel");
    const convertedSql = document.querySelector("#convertedSql");
    const convertedFrom = document.querySelector("#convertedFrom");

    function addSchema(schema = {{ name: "", columns: [] }}) {{
      const card = document.createElement("div");
      card.className = "schema-card";
      card.innerHTML = `
        <div class="schema-title">
          <span class="tag">Table</span>
          <input aria-label="Table name" class="schema-name" value="${{escapeAttr(schema.name || "")}}" placeholder="table name">
          <button type="button" class="danger remove-schema" title="Remove table">x</button>
        </div>
        <div class="schema-head"><span>Column</span><span>Type</span><span></span></div>
        <div class="schema-rows"></div>
        <button type="button" class="add-column">+ Column</button>
      `;
      const rows = card.querySelector(".schema-rows");
      card.querySelector(".schema-name").addEventListener("input", updateRequest);
      card.querySelector(".remove-schema").addEventListener("click", () => {{
        card.remove();
        updateRequest();
      }});
      card.querySelector(".add-column").addEventListener("click", () => {{
        addRow(rows);
        updateRequest();
      }});
      (schema.columns || []).forEach(col => addRow(rows, col.name, col.type));
      schemasEl.appendChild(card);
    }}

    function addRow(rows, name = "", type = "Int") {{
      const row = document.createElement("div");
      row.className = "schema-row";
      row.innerHTML = `
        <input aria-label="Column name" class="col-name" value="${{escapeAttr(name)}}" placeholder="age">
        <select aria-label="Column type" class="col-type">
          <option>Int</option>
          <option>Bool</option>
          <option>String</option>
          <option>Float</option>
          <option>varchar</option>
          <option>text</option>
        </select>
        <button type="button" class="danger" title="Remove column">x</button>
      `;
      row.querySelector(".col-type").value = type;
      row.querySelector(".danger").addEventListener("click", () => {{
        row.remove();
        updateRequest();
      }});
      row.querySelectorAll("input, select").forEach(el => el.addEventListener("input", updateRequest));
      rows.appendChild(row);
    }}

    function escapeAttr(value) {{
      return String(value).replaceAll("&", "&amp;").replaceAll('"', "&quot;").replaceAll("<", "&lt;");
    }}

    const hypothesesEl = document.querySelector("#hypotheses");

    // Map a hypothesis payload object to editor fields [kind, argText].
    function hypToFields(hyp) {{
      if (hyp.predicate !== undefined) return ["predicate", hyp.predicate];
      if (hyp.unique !== undefined) return ["unique", hyp.unique];
      if (hyp.funcdep !== undefined) return ["funcdep", (hyp.funcdep || []).join(", ")];
      if (hyp.bijection !== undefined) return ["bijection", (hyp.bijection || []).join(", ")];
      return ["predicate", ""];
    }}

    function addHypothesis(hyp = {{}}) {{
      const [kind, arg] = hypToFields(hyp);
      const row = document.createElement("div");
      row.className = "hyp-card";
      row.innerHTML = `
        <div class="hyp-card-head">
          <span class="tag">Hypothesis</span>
          <button type="button" class="danger" title="Remove hypothesis">x</button>
        </div>
        <div class="hyp-grid">
          <div class="field">
            <label class="mini">Table</label>
            <input aria-label="Table" class="hyp-table" value="${{escapeAttr(hyp.table || "")}}" placeholder="table">
          </div>
          <div class="field">
            <label class="mini">Type</label>
            <select aria-label="Kind" class="hyp-kind">
              <option value="predicate">predicate</option>
              <option value="funcdep">funcdep</option>
              <option value="unique">unique</option>
              <option value="bijection">bijection</option>
            </select>
          </div>
          <div class="field">
            <label class="mini">Statement</label>
            <input aria-label="Statement" class="hyp-arg" value="${{escapeAttr(arg)}}" placeholder="age > 30  /  a, b  /  k">
          </div>
        </div>
      `;
      row.querySelector(".hyp-kind").value = kind;
      row.querySelector(".danger").addEventListener("click", () => {{ row.remove(); updateRequest(); }});
      row.querySelectorAll("input, select").forEach(el => el.addEventListener("input", updateRequest));
      hypothesesEl.appendChild(row);
    }}

    function currentHypotheses() {{
      return [...hypothesesEl.querySelectorAll(".hyp-card")].map(row => {{
        const table = row.querySelector(".hyp-table").value.trim();
        const kind = row.querySelector(".hyp-kind").value;
        const arg = row.querySelector(".hyp-arg").value.trim();
        if (!table || !arg) return null;
        if (kind === "predicate") return {{ table, predicate: arg }};
        if (kind === "unique") return {{ table, unique: arg }};
        const cols = arg.split(",").map(s => s.trim()).filter(Boolean);
        return {{ table, [kind]: cols }};   // funcdep / bijection: [a, b]
      }}).filter(Boolean);
    }}

    function currentPayload() {{
      const payload = {{
        schemas: [...schemasEl.querySelectorAll(".schema-card")].map(card => ({{
          name: card.querySelector(".schema-name").value.trim(),
          columns: [...card.querySelectorAll(".schema-row")].map(row => ({{
            name: row.querySelector(".col-name").value.trim(),
            type: row.querySelector(".col-type").value.trim()
          }})).filter(col => col.name && col.type)
        }})).filter(schema => schema.name && schema.columns.length),
        queries: [first.value, second.value],
        dialect: dialect.value
      }};
      const hyps = currentHypotheses();
      if (hyps.length) payload.hypotheses = hyps;
      return payload;
    }}

    function updateRequest() {{
      requestJson.textContent = JSON.stringify(currentPayload(), null, 2);
    }}

    let convTimer = null;
    function scheduleConverted() {{ clearTimeout(convTimer); convTimer = setTimeout(refreshConverted, 350); }}
    async function refreshConverted() {{
      if (dialect.value === "postgres") {{ convertedPanel.style.display = "none"; return; }}
      try {{
        const res = await fetch("/transpile", {{
          method: "POST",
          headers: {{ "Content-Type": "application/json" }},
          body: JSON.stringify({{ queries: [first.value, second.value], dialect: dialect.value }})
        }});
        const data = await res.json();
        const out = (data.queries || []).map((q, i) => {{
          const err = (data.errors || [])[i];
          return `-- query ${{i + 1}}` + (err ? ` (transpile error: ${{err}})` : "") + `\\n${{q}}`;
        }}).join("\\n\\n");
        convertedFrom.textContent = `(from ${{dialect.value}})`;
        convertedSql.textContent = out || "-";
        convertedPanel.style.display = "";
      }} catch (err) {{
        convertedFrom.textContent = "";
        convertedSql.textContent = "transpile request failed: " + err.message;
        convertedPanel.style.display = "";
      }}
    }}

    function loadPayload(payload) {{
      schemasEl.replaceChildren();
      (payload.schemas || []).forEach(addSchema);
      hypothesesEl.replaceChildren();
      (payload.hypotheses || []).forEach(addHypothesis);
      first.value = (payload.queries && payload.queries[0]) || "";
      second.value = (payload.queries && payload.queries[1]) || "";
      dialect.value = payload.dialect || "postgres";
      responseJson.textContent = "No request sent yet.";
      statusLine.textContent = "";
      updateRequest();
      refreshConverted();
    }}

    function reset() {{
      loadPayload(initial);
    }}

    async function check() {{
      const payload = currentPayload();
      requestJson.textContent = JSON.stringify(payload, null, 2);
      responseJson.textContent = "Waiting for Lean...";
      statusLine.textContent = "Running equivalence check.";
      try {{
        const res = await fetch("/", {{
          method: "POST",
          headers: {{ "Content-Type": "application/json" }},
          body: JSON.stringify(payload)
        }});
        const text = await res.text();
        let data;
        try {{
          data = JSON.parse(text);
          responseJson.textContent = JSON.stringify(data, null, 2);
        }} catch {{
          responseJson.textContent = text;
          throw new Error(`HTTP ${{res.status}} returned non-JSON`);
        }}
        if (!res.ok || data.status === "error") {{
          statusLine.innerHTML = `<span class="result-error">Error:</span> ${{data.message || res.statusText}}`;
        }} else {{
          statusLine.innerHTML = data.equivalent
            ? `<span class="result-ok">Equivalent.</span>`
            : `<span class="result-error">Could not prove equivalent.</span>`;
        }}
      }} catch (err) {{
        statusLine.innerHTML = `<span class="result-error">Request failed:</span> ${{err.message}}`;
      }}
    }}

    document.querySelector("#addSchema").addEventListener("click", () => {{
      addSchema({{ name: "table" + (schemasEl.children.length + 1), columns: [] }});
      updateRequest();
    }});
    document.querySelector("#check").addEventListener("click", check);
    document.querySelector("#reset").addEventListener("click", reset);
    first.addEventListener("input", updateRequest);
    second.addEventListener("input", updateRequest);
    first.addEventListener("input", scheduleConverted);
    second.addEventListener("input", scheduleConverted);
    dialect.addEventListener("change", () => {{ updateRequest(); refreshConverted(); }});

    // A single picker with one <optgroup> per example group; strip internal "ExampleN:" prefixes.
    function buildExampleMenus() {{
      const menu = document.querySelector("#examplePicker");
      menu.replaceChildren();
      menu.append(new Option("Choose an example…", ""));
      exampleGroups.forEach((group, g) => {{
        const grp = document.createElement("optgroup");
        grp.label = group.label;
        group.examples.forEach((ex, i) =>
          grp.append(new Option(ex.label.replace(/^Example\d+:\s*/, ""), g + ":" + i)));
        menu.append(grp);
      }});
      menu.addEventListener("change", () => {{
        if (!menu.value) return;
        const [g, i] = menu.value.split(":").map(Number);
        loadPayload(exampleGroups[g].examples[i]);
        menu.value = "";
      }});
    }}

    document.querySelector("#addHypothesis").addEventListener("click", () => {{ addHypothesis(); updateRequest(); }});
    buildExampleMenus();
    reset();
  </script>
</body>
</html>"""


def lan_ips() -> list[str]:
    """Best-effort list of this host's non-loopback IPv4 addresses (e.g. the LAN 10.x/192.168.x)."""
    ips: set[str] = set()
    try:  # the IP of the interface used to reach the outside world
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80)); ips.add(s.getsockname()[0]); s.close()
    except OSError:
        pass
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            ips.add(info[4][0])
    except OSError:
        pass
    return sorted(i for i in ips if not i.startswith("127."))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="0.0.0.0",
                        help="interface to bind (default 0.0.0.0 = all, reachable on the LAN IP)")
    parser.add_argument("--port", default=PORT, type=int)
    parser.add_argument("--timeout", default=REQUEST_TIMEOUT_SECONDS, type=float)
    parser.add_argument(
        "--no-warmup",
        action="store_true",
        help="skip the startup sample check that warms Lean's first-query path",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    repo_dir = Path(__file__).resolve().parent
    os.chdir(repo_dir)

    server: SqlServer | None = None
    sql_process: SqlProcess | None = None
    try:
        sql_process = SqlProcess(
            repo_dir,
            timeout=args.timeout,
            warmup=not args.no_warmup,
        )
        sql_process.wait_until_ready()
        if sql_process.warmup:
            sql_process.warm_up(DEFAULT_DEMO)
        server = SqlServer((args.host, args.port), Handler)
        server.sql_process = sql_process
        print(f"Serving on http://{args.host}:{args.port}", file=sys.stderr, flush=True)
        if args.host in ("0.0.0.0", "::"):
            for url in [f"http://127.0.0.1:{args.port}"] + [f"http://{ip}:{args.port}" for ip in lan_ips()]:
                print(f"  reachable at {url}", file=sys.stderr, flush=True)
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        if server is not None:
            server.server_close()
        if sql_process is not None:
            sql_process.stop()


if __name__ == "__main__":
    main()
