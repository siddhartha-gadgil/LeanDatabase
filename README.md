# LeanDatabase

LeanDatabase provides a small HTTP server for checking equivalence of SQL-like
queries using Lean. The Python entry point is `sql_server.py`; it starts the Lean
executable `sql_process` through Lake and exposes an HTTP endpoint.

## What it does

Given two SQL queries and a schema, it *machine-proves* whether they are equivalent — not by
testing rows, but by parsing each query into a relational-algebra term over a `TypedRelation`
(`rows : Finset`, **set semantics**) and closing the goal with the `sql_equiv` tactic. A green proof
is a guarantee for **all** possible tables, not a sample. If two queries are *not* equivalent, the
proof fails rather than yielding a false positive — soundness is the top priority.

`CREATE TABLE t (a INT, b STRING)` declares a schema; `sql%([t_schema]) "…"` parses a query against
it; the two are compared with `= … := by sql_equiv`. See `Examples/` for worked equivalences and
`ROADMAP.md` for the coverage plan and its limits.

## Supported SQL features — what each buys you

Each feature below is paired with the concrete problem it solves. "Without it" means the query would
fail to parse/elaborate, or (worse) would prove something *false* — which is why several features are
about making the *wrong* thing impossible, not just the right thing possible.

- **`ORDER BY … ASC|DESC`** — direction is parsed and discarded (row order is unobservable on a
  `Finset`), so `ORDER BY a DESC` ≡ `ORDER BY a ASC` ≡ unordered.
  *Without it:* every query carrying a direction token (60% of the benchmark) died at parse time.

- **Qualified star `t.*`** — expands to exactly table `t`'s columns.
  `SELECT t.* FROM t, u` keeps only `t`'s columns, not `u`'s.
  *Without it:* joins that project one side's columns with `*` couldn't be written.

- **`COUNT(CASE WHEN p THEN 1 END)`** (CASE without ELSE, aggregate position) — rewritten to the
  indicator sum `SUM(CASE WHEN p THEN 1 ELSE 0 END)`, i.e. a count of the rows where `p` holds.
  *Without it:* a bare `CASE … END` in an ordinary column position is **rejected** on purpose —
  defaulting the missing branch to `0` would be silently wrong for `SUM`/`AVG`/`MIN`.

- **Scalar functions** (`ROUND`, `ABS`, `YEAR`/`MONTH`/`DAY`, `UPPER`/`LOWER`/`TRIM`, …) — modelled
  as *uninterpreted* (opaque) functions, so identical calls on both sides cancel by congruence.
  *Without it:* `ROUND(SUM(x),2)` on both sides wouldn't parse. And note `SELECT ROUND(v,2)` is
  **not** provably equal to `SELECT v` — opaqueness stops a rounding difference from being laundered
  into an equality.

- **`CAST(x AS type)`** — a *real*, type-directed coercion, **not** opaque. `CAST(int AS FLOAT)` is a
  genuine `Int → Rat` coercion.
  *Without it (if it were opaque):* `a/b` (integer division) would silently equate with
  `CAST(a AS FLOAT)/CAST(b AS FLOAT)` (real division) — a soundness hole. Here the two even have
  different result types (`Int` vs `Rat`), so the false claim is rejected as a type mismatch.

- **CTEs — `WITH x AS (q) SELECT … FROM x`** — a CTE is a local relation binding, inlined at each
  reference; stacked projections fuse (`SELECT a FROM (SELECT a,b …)` collapses to one projection).
  ```sql
  WITH x AS (SELECT * FROM t WHERE a > 3), y AS (SELECT * FROM x WHERE b > 1) SELECT * FROM y
    ≡  SELECT * FROM t WHERE a > 3 AND b > 1
  ```
  *Without it:* `WITH` appears in ~76% of the benchmark; those queries couldn't be expressed at all.
  (`WITH RECURSIVE` is out of scope.)

- **`NULL` (sound 2-valued slice)** — columns are opt-in nullable (`amt INT NULL` → `Option Int`);
  `x IS NULL` / `x IS NOT NULL` are 2-valued `Bool`, `COALESCE(x,d)`/`IFNULL(x,d)` return a non-null
  value, `NULLIF(a,b)` returns a nullable one.
  *Without it:* no way to talk about NULLs at all. Crucially there is **no bare `NULL` literal**, so
  `WHERE x = NULL` cannot be written — that avoids the classic three-valued-logic trap where
  `WHERE NOT(x = NULL)` wrongly keeps NULL rows. A raw nullable column in a comparison (`amt = 5`)
  fails to typecheck rather than mis-evaluating. Full three-valued predicate logic is future work.

## Run With Docker

Build the image from the repository root:

```sh
docker build -t lean-database-sql .
```

Run the server on port `6767`:

```sh
docker run --rm -p 6767:6767 lean-database-sql
```

Open the demo page:

```sh
open http://127.0.0.1:6767/
```

Or test the JSON endpoint:

```sh
curl -sS \
  -H 'Content-Type: application/json' \
  --data '{"schema":[{"name":"age","type":"Int"},{"name":"isActive","type":"Bool"}],"first":"SELECT * FROM table WHERE age > 30 && isActive","second":"SELECT * FROM table WHERE age > 30 && isActive"}' \
  http://127.0.0.1:6767/
```

If Docker Desktop installed the CLI but `docker` is not on your `PATH`, use:

```sh
/Applications/Docker.app/Contents/Resources/bin/docker build -t lean-database-sql .
/Applications/Docker.app/Contents/Resources/bin/docker run --rm -p 6767:6767 lean-database-sql
```

## Run Locally

Install elan, which installs and manages the Lean toolchain:

```sh
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh
```

Restart the shell or load elan into the current shell:

```sh
source "$HOME/.elan/env"
```

Fetch dependencies and pull the Mathlib cache:

```sh
lake exe cache get
```

Build the Lean library and server process:

```sh
lake build LeanDatabase sql_process
```

Start the Python HTTP server:

```sh
python3 sql_server.py --host 127.0.0.1 --port 6767
```

Then open:

```sh
open http://127.0.0.1:6767/
```

The server prints `sql_process is ready` when the Lean subprocess has finished
initializing and requests can be processed.
