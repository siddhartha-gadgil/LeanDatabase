#!/usr/bin/env python3
"""General SQL dialect transpilation (sqlglot), reused across the project.

We prove equivalence over ONE dialect, so every source query is first normalised to it. The default
target is PostgreSQL — the most ISO/ANSI-aligned dialect sqlglot supports. Translation only (no
algebraic simplification), so the equivalence theorem is still discharged by `sql_equiv` in Lean,
never silently by sqlglot's optimizer.

    from transpile import transpile_sql, to_postgres
    pg, err = to_postgres(snowflake_sql)     # err is None on success; on failure pg = original sql
"""
import sqlglot

def transpile_sql(sql: str, read: str | None = None, write: str = "postgres") -> tuple[str, str | None]:
    """Transpile `sql` from `read` dialect (None = sqlglot's generic parser) to `write` (default
    PostgreSQL). Returns (out, error?); on failure returns the original SQL with the error message."""
    try:
        out = sqlglot.transpile(sql, read=read, write=write)
        return (out[0] if out else sql, None)
    except Exception as e:  # noqa: BLE001 — any sqlglot parse/transpile failure is the caller's to see
        return (sql, f"{type(e).__name__}: {e}")

def to_postgres(sql: str, read: str = "snowflake") -> tuple[str, str | None]:
    """Convenience for the corpus pipeline: Snowflake → PostgreSQL."""
    return transpile_sql(sql, read=read, write="postgres")
