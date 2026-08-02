import LeanDatabase.Parser
open LeanDatabase

/-!
# Example 26 — `LEFT JOIN … WHERE right IS NULL` over the real `leftOuterJoin` operator

Where Example 9 modelled the anti-join idiom with a hand-written `restriction`, this file uses the
actual **`leftOuterJoin`** operator (Phase 5) — the one whose output null-pads the right columns
(`Option`) — and shows that keeping only the rows where a right column `IS NULL` recovers exactly the
null-padded **anti-join** (the unmatched left rows). This is the `LEFT JOIN … WHERE b.key IS NULL`
≡ `NOT EXISTS` rewrite, discharged by the `@[simp]` lemma `leftOuterJoin_isNull_eq_antijoin_pad`.

```sql
SELECT * FROM customers c
LEFT JOIN orders o ON o.cust_id = c.id
WHERE o.cust_id IS NULL;          -- customers with no matching order = anti-join
```
-/

namespace Example26

abbrev custCT : Fin 1 → Type := fun _ => Nat        -- customers(id)
abbrev ordCT  : Fin 1 → Type := fun _ => Nat        -- orders(cust_id)
instance : ∀ i, DecidableEq (custCT i) := fun _ => inferInstance
instance : ∀ i, DecidableEq (ordCT i)  := fun _ => inferInstance
instance : ∀ i, Inhabited (custCT i)   := fun _ => inferInstance
instance : ∀ i, Inhabited (ordCT i)    := fun _ => inferInstance

/-- `ON o.cust_id = c.id`. -/
abbrev matchCond : TypedTuple custCT → TypedTuple ordCT → Bool := fun c o => decide (c 0 = o 0)

/-- `customers LEFT JOIN orders ON … WHERE o.cust_id IS NULL` equals the null-padded anti-join of
the unmatched customers — proved directly over the `leftOuterJoin` operator. -/
theorem left_join_null_eq_antijoin
    (customers : TypedRelation custCT) (orders : TypedRelation ordCT) :
    restriction (isNull (fun t => (splitTuple t).2 0)) (leftOuterJoin customers orders matchCond)
      = crossProductRel (antijoin customers orders matchCond) (nullRow ordCT orders.labels) := by
  rw [leftOuterJoin_isNull_eq_antijoin_pad]

end Example26
