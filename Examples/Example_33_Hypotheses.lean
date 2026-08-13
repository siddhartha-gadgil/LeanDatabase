import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Data assumptions with `HYPOTHESIS`

A file reads: `CREATE TABLE` → one or more `HYPOTHESIS` → a theorem of equivalence.

Each `HYPOTHESIS h : Table "<predicate>"` declares a *data assumption* — that every row satisfies the
predicate — as `h : TableRel Table_schema → Prop`. It is defined as "the filter drops no rows"
(`SELECT * WHERE <pred>` = `SELECT *`), which is exactly `∀ row, <pred>`.
-/

namespace HypothesesDemo

CREATE TABLE Orders (qty INT, price INT, total INT, discount FLOAT, valid BOOL)

-- four assumptions of different kinds --------------------------------------------------------------
HYPOTHESIS qty_le_total : Orders "qty <= total"                 -- a relation between two columns
HYPOTHESIS total_calc   : Orders "total = qty * price"          -- an arithmetic identity
HYPOTHESIS disc_rounded : Orders "discount = ROUND(discount, 2)" -- ROUND is a no-op on this column
HYPOTHESIS all_valid    : Orders "valid"                        -- a general boolean flag

/-- Warm-up: projecting `total` equals projecting `qty * price`, **given** the arithmetic identity.
The two queries read different columns; only `total_calc` bridges them. -/
theorem amount_bridge (t : TableRel Orders_schema) (h : total_calc t) :
    (sql%([Orders_schema]) "SELECT total AS amount FROM Orders") t
      = (sql%([Orders_schema]) "SELECT qty * price AS amount FROM Orders") t := by
  sql_equiv

/-- Warm-up: a `WHERE` that a hypothesis proves redundant drops nothing, so it can be removed. -/
theorem where_redundant (t : TableRel Orders_schema) (h : all_valid t) :
    (sql%([Orders_schema]) "SELECT qty FROM Orders WHERE valid") t
      = (sql%([Orders_schema]) "SELECT qty FROM Orders") t := by
  sql_equiv

/-- The full example: two independently-written queries, equal **given the four assumptions**:
* `WHERE qty <= total AND valid` drops nothing            (needs `qty_le_total`, `all_valid`)
* the projected `qty * price` equals `total`              (needs `total_calc`)
* the projected `ROUND(discount, 2)` equals `discount`    (needs `disc_rounded`) -/
theorem orders_equiv
    (t : TableRel Orders_schema)
    (h1 : qty_le_total t) (h2 : total_calc t) (h3 : disc_rounded t) (h4 : all_valid t) :
    (sql%([Orders_schema])
        "SELECT qty * price AS amount, ROUND(discount, 2) AS disc
         FROM Orders WHERE qty <= total AND valid") t
      = (sql%([Orders_schema])
        "SELECT total AS amount, discount AS disc FROM Orders") t := by
  sql_equiv

/-! ## Complexity scales with the *predicate*, not the *number* of hypotheses

`grind` chains and combines the assumptions on its own: a transitive chain (`total = qty*price`,
`qty*price ≥ 0` ⟹ the filter drops nothing) plus a multi-column arithmetic bridge, all at once. -/
HYPOTHESIS total_nonneg : Orders "total >= 0"

/-- A `WHERE total >= 0` shown redundant by *chaining* `total_calc` with a bound, while the projection
is bridged by the same `total_calc` — one hypothesis pulling double duty, another chained into it. -/
theorem chained (t : TableRel Orders_schema)
    (h1 : total_calc t) (h2 : total_nonneg t) :
    (sql%([Orders_schema]) "SELECT qty * price AS amount FROM Orders WHERE total >= 0") t
      = (sql%([Orders_schema]) "SELECT total AS amount FROM Orders") t := by
  
  sql_equiv

end HypothesesDemo
