import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Example 26 — outer joins: the operator identity and the SQL surface syntax (Phase 5)

Two halves of `LEFT`/`RIGHT`/`FULL OUTER JOIN`:

1. **The operator identity.** Over the real `leftOuterJoin` operator (whose output null-pads the
   right columns as `Option`), keeping only the rows where a right column `IS NULL` recovers exactly
   the null-padded **anti-join** — the unmatched left rows. This is the
   `LEFT JOIN … WHERE b.key IS NULL` ≡ `NOT EXISTS` rewrite, discharged by the `@[simp]` lemma
   `leftOuterJoin_filter_isNull_eq_antijoin_pad`. (Contrast Example 9, which modelled the same idiom
   with a hand-written `restriction`.)

2. **The SQL surface syntax.** `A LEFT|RIGHT|FULL [OUTER] JOIN B ON …` parses to those operators;
   the null-padded side's columns are nullable in the output schema (reachable via `IS NULL` /
   `COALESCE`), and `WHERE`/projection *over* an outer join elaborate (schema reconciliation via
   `ofOuter*` in `Parser/Query.lean`).
-/

namespace Example26

/-! ## 1. The operator-level anti-join identity -/

abbrev custCT : Fin 1 → Type := fun _ => Nat        -- customers(id)
abbrev ordCT  : Fin 1 → Type := fun _ => Nat        -- orders(cust_id)
instance : ∀ i, DecidableEq (custCT i) := fun _ => inferInstance
instance : ∀ i, DecidableEq (ordCT i)  := fun _ => inferInstance
instance : ∀ i, Inhabited (custCT i)   := fun _ => inferInstance
instance : ∀ i, Inhabited (ordCT i)    := fun _ => inferInstance

/-- `ON o.cust_id = c.id`. -/
abbrev matchCond : TypedTuple custCT → TypedTuple ordCT → Bool := fun c o => decide (c 0 = o 0)

/-- `customers LEFT JOIN orders ON … WHERE o.cust_id IS NULL` equals the null-padded anti-join of the
unmatched customers — proved directly over the `leftOuterJoin` operator. -/
theorem left_join_null_eq_antijoin
    (customers : TypedRelation custCT) (orders : TypedRelation ordCT) :
    restriction (isNull (fun t => (splitTuple t).2 0)) (leftOuterJoin customers orders matchCond)
      = crossProductRel (antijoin customers orders matchCond) (nullRow ordCT orders.labels) := by
  sql_equiv

/-! ## 2. The SQL surface syntax -/

CREATE TABLE customers (id INT)
CREATE TABLE orders (cust_id INT, amount INT)

/-- `LEFT JOIN`/`LEFT OUTER JOIN` are synonyms; unqualified/qualified `ON` agree. -/
theorem left_outer_synonym :
    sql%([customers_schema, orders_schema]) "SELECT * FROM customers LEFT JOIN orders ON id = cust_id"
      = sql%([customers_schema, orders_schema]) "SELECT * FROM customers LEFT OUTER JOIN orders ON customers.id = orders.cust_id" := by
  sql_equiv

/-- `RIGHT` and `FULL [OUTER] JOIN` parse to `rightOuterJoin`/`fullOuterJoin`. -/
theorem right_and_full_parse :
    sql%([customers_schema, orders_schema]) "SELECT * FROM customers RIGHT JOIN orders ON id = cust_id"
      = sql%([customers_schema, orders_schema]) "SELECT * FROM customers RIGHT OUTER JOIN orders ON id = cust_id"
  ∧ sql%([customers_schema, orders_schema]) "SELECT * FROM customers FULL JOIN orders ON id = cust_id"
      = sql%([customers_schema, orders_schema]) "SELECT * FROM customers FULL OUTER JOIN orders ON id = cust_id" := by
  constructor <;> sql_equiv

/-- A rewrite over a parsed outer join: the `ON` equality commutes. -/
theorem on_condition_commutes :
    sql%([customers_schema, orders_schema]) "SELECT * FROM customers LEFT JOIN orders ON id = cust_id"
      = sql%([customers_schema, orders_schema]) "SELECT * FROM customers LEFT JOIN orders ON cust_id = id" := by
  sql_equiv

/-- `WHERE` over a LEFT JOIN: the (now nullable) right column is reachable via `IS NULL`, and the
`WHERE` conjuncts commute — projection/`WHERE` over an outer join really elaborate. -/
theorem where_over_left_join_commutes :
    sql%([customers_schema, orders_schema])
        "SELECT * FROM customers LEFT JOIN orders ON id = cust_id WHERE amount IS NULL AND id > 3"
      = sql%([customers_schema, orders_schema])
        "SELECT * FROM customers LEFT JOIN orders ON id = cust_id WHERE id > 3 AND amount IS NULL" := by
  sql_equiv

/-- `COALESCE` over a nullable right column, projected out of a LEFT JOIN. -/
theorem coalesce_over_left_join :
    sql%([customers_schema, orders_schema])
        "SELECT COALESCE(amount, 0) AS amt FROM customers LEFT JOIN orders ON id = cust_id WHERE id > 1 AND id < 9"
      = sql%([customers_schema, orders_schema])
        "SELECT COALESCE(amount, 0) AS amt FROM customers LEFT JOIN orders ON id = cust_id WHERE id < 9 AND id > 1" := by
  sql_equiv

end Example26
