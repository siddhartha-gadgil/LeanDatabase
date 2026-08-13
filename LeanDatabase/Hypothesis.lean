import LeanDatabase.Parser

/-!
# Data assumptions with `HYPOTHESIS`

A file reads: `CREATE TABLE` → one or more `HYPOTHESIS` → a theorem of equivalence.

`HYPOTHESIS name : Table "<pred>"` declares a data assumption — that every row of `Table` satisfies the
predicate — as `name : TableRel Table_schema → Prop`, in its **unfolded, row-wise** form
`∀ row ∈ t.rows, pred row` (see `RowsSatisfy`). A theorem then lists the assumptions it needs as
ordinary hypotheses and proves two queries equal **under them**.

The row-wise form matters for the tactic: a folded `restriction p t = t` would carry the whole relation
term and make `grind`/`simp_all` churn; the `∀`-fact is a clean assumption it can instantiate directly.
-/

open Lean Meta Elab Term

namespace LeanDatabase

/--
## Column Hypotheses

The relation type of a declared table, from its `_schema`. Lets a theorem bind a concrete table
`(t : TableRel T_schema)` — needed to state hypotheses about the data — without spelling out the column proxies. -/
abbrev TableRel (s : Lean.Name × List (Lean.Name × SQLTypeProxy)) : Type :=
  TypedRelationOfList (s.2.map (·.2))

/--
## DATA HYPOTHESES

A data assumption in **unfolded, row-wise** form: predicate `p` holds on every row. What a
`HYPOTHESIS` declaration reduces to — a clean `∀`-fact the tactic can instantiate, with no relation term for `grind` to churn through. -/
abbrev RowsSatisfy {n} {ct : Fin n → Type} [∀ i, DecidableEq (ct i)]
    (p : TypedTuple ct → Bool) (r : TypedRelation ct) : Prop :=
  ∀ x ∈ r.rows, p x = true

/-- A filter that holds on every row is a no-op — collapses a redundant `WHERE`. -/
theorem restriction_of_forall {n} {ct : Fin n → Type} [∀ i, DecidableEq (ct i)]
    (p : TypedTuple ct → Bool) (r : TypedRelation ct) (h : ∀ x ∈ r.rows, p x = true) :
    restriction p r = r := by
  apply TypedRelation.ext (by rfl)
  simp only [restriction]; exact Finset.filter_true_of_mem h

/-- Recover the per-row fact `∀ row, p row` from the folded `restriction p t = t` form. -/
theorem forall_of_restriction_eq {n} {ct : Fin n → Type} [∀ i, DecidableEq (ct i)]
    (p : TypedTuple ct → Bool) (r : TypedRelation ct) (h : restriction p r = r) :
    ∀ x ∈ r.rows, p x = true := by
  intro x hx
  rw [← h] at hx
  simp only [restriction, Finset.mem_filter] at hx
  exact hx.2

/-- A projection can swap expressions that agree on every row. -/
theorem mapByList_congr_of_forall {n} {ct : Fin n → Type} [∀ i, DecidableEq (ct i)]
    {types : List SQLTypeProxy} (r : TypedRelation ct) (names : List String)
    (f g : TypedTuple ct → TypedTupleOfList types) (h : ∀ x ∈ r.rows, f x = g x) :
    r.mapByList names f = r.mapByList names g := by
  apply TypedRelation.ext (by rfl)
  exact Finset.image_congr h

/-- `HYPOTHESIS name : Table "<bool predicate>"` — a data assumption declared like `CREATE TABLE`.
Defines `name : TableRel Table_schema → Prop` as `RowsSatisfy p` (`∀ row ∈ t.rows, p row`), where `p`
is the `WHERE` predicate. A theorem lists it as an antecedent
(`theorem eq (t) (h : name t) : … := by sql_equiv`); the assumption is explicit, so it stays sound. -/
elab "HYPOTHESIS" name:ident ":" tbl:ident pred:str : command => do
  let t := tbl.getId.toString
  let sch := Lean.mkIdent (Name.mkSimple (t ++ "_schema"))
  -- Extract the `WHERE` predicate `p` from a parse of `SELECT * FROM T WHERE <pred>` (which elaborates
  -- to `fun r => restriction p r`), then emit the assumption as `fun row => RowsSatisfy p row`.
  Elab.Command.liftTermElabM do
    let schemaTy ← elabType (← `(List (Name × List (Name × SQLTypeProxy))))
    let schemaExpr ← elabTermEnsuringType (← `([$sch])) (some schemaTy)
    let schema ← unsafe evalExpr (List (Name × List (Name × SQLTypeProxy))) schemaTy
      (← instantiateMVars schemaExpr)
 
    let (e, _) ← parseSqlQuery schema s!"SELECT * FROM {t} WHERE {pred.getString}"
    let .lam _ relTy body _ := (← instantiateMVars e) | throwError "HYPOTHESIS: unexpected query shape"
    let (fn, args) := body.getAppFnArgs
    unless fn == ``LeanDatabase.restriction && args.size ≥ 5 do
      throwError "HYPOTHESIS: predicate did not produce a WHERE filter"
    let p := args[3]!
    let val ← withLocalDeclD `row relTy fun row => do
      mkLambdaFVars #[row] (← mkAppM ``LeanDatabase.RowsSatisfy #[p, row])
    let typ ← mkArrow relTy (.sort .zero)
    addDecl (Declaration.defnDecl {
      name := name.getId, levelParams := [], type := typ, value := val,
      hints := ReducibilityHints.abbrev, safety := DefinitionSafety.safe })
    -- Mark `@[reducible]` so `grind`/`simp`/`dsimp` unfold `name t` to the `∀`-fact and can use it;
    -- `addDecl` alone sets only the unfolding *hint*, not the attribute.
    setReducibilityStatus name.getId .reducible

end LeanDatabase
