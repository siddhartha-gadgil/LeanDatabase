import LeanDatabase.TypedRelation
import LeanDatabase.Parser.Types

open Lean Elab Term Meta
open Lean
open Lean.Parser.Term

set_option linter.unusedVariables false


namespace LeanDatabase

declare_syntax_cat sql

syntax base_type := "INT" <|> "STRING" <|> "BOOL" <|> "FLOAT" <|> ("VARCHAR(" num ")")
-- A trailing `NULL` marks the column nullable (opt-in): its type becomes `Option _` and its proxy
-- `.nullable _`. Columns without it stay non-nullable, so existing schemas are unchanged.
syntax data_type := base_type (" NULL")?
syntax constraints := "PRIMARY" "KEY" <|> ("NOT""NULL") <|> ("UNIQUE")

syntax (name := createTableCmd) "CREATE" "TABLE" ident "(" (ident data_type),* ")" : command


syntax (name :=insertCmd) "INSERT" "INTO" ident "(" (ident),* ")" "VALUES" "(" (term),* ")" : command

syntax (name := selectCmd) "SELECT" sepBy(ident, ",") "FROM" ident "WHERE" term : command
syntax (name := selectTerm) "SELECT" sepBy(ident, ",") "FROM" ident "WHERE" term : term

open Lean Elab Command Term Meta


@[command_elab createTableCmd]
def elabCreateTableCmd : CommandElab := fun stx => do
  match stx with
  | `(command| CREATE TABLE $tname:ident ($[$idents:ident $data_types:data_type],*) ) =>

    let colNames := idents.map (fun id => quote id.getId.toString)
    let n := quote colNames.size

    -- Base `(leanType, proxy)` for a `base_type`, before applying the optional `NULL` wrapper.
    let baseInfo : TSyntax `LeanDatabase.base_type → CommandElabM (TSyntax `term × TSyntax `term) := fun
      | `(base_type| INT)        => return (← `(ℤ),      ← `((.int : SQLTypeProxy)))
      | `(base_type| STRING)     => return (← `(String), ← `((.string : SQLTypeProxy)))
      | `(base_type| BOOL)       => return (← `(Bool),   ← `((.bool : SQLTypeProxy)))
      | `(base_type| FLOAT)      => return (← `(ℚ),      ← `((.float : SQLTypeProxy)))
      | `(base_type| VARCHAR($_)) => return (← `(String), ← `((.string : SQLTypeProxy)))
      | _                        => return (← `(String), ← `((.string : SQLTypeProxy)))
    -- A `NULL` suffix wraps the type in `Option` and the proxy in `.nullable`.
    let typeProxy : Array (TSyntax `term × TSyntax `term) ← data_types.mapM fun
      | `(data_type| $b:base_type $[NULL%$isNull]?) => do
          let (t, p) ← baseInfo b
          if isNull.isSome then return (← `(Option $t), ← `((.nullable $p : SQLTypeProxy)))
          else return (t, p)
      | _ => return (← `(String), ← `((.string : SQLTypeProxy)))
    let typesList := typeProxy.map (·.1)
    -- `<table>_schema`: the `List (Name × SQLTypeProxy)` form the `parseSqlQuery` / `sql%` path consumes.
    let proxyList := typeProxy.map (·.2)
    let colPairs ← (idents.zip proxyList).mapM fun (id, p) => `(($(quote id.getId), $p))
    let schemaName := Lean.mkIdent (Name.mkSimple s!"{tname.getId}_schema")
    let schemaCmd ← `(def $schemaName : Lean.Name × List (Lean.Name × SQLTypeProxy) :=
      ($(quote tname.getId), [$colPairs,*]))

    let alts_types ← typesList.mapIdxM fun idx t => do
      let idxLit := Syntax.mkNumLit (toString idx)
      `(matchAltExpr| | $idxLit => $t)

    let alts_labels ← colNames.mapIdxM fun idx l => do
      let idxLit := Syntax.mkNumLit (toString idx)
      `(matchAltExpr| | $idxLit => $l)

    let labels ← `(fun (x: Fin $n) => match x with $alts_labels:matchAlt*)
    let alts_tc ← typesList.mapIdxM fun idx _ => do
      let idxLit := Syntax.mkNumLit (toString idx)
      `(matchAltExpr| | $idxLit => inferInstance)

    let typesDefName := Lean.mkIdent (Name.mkSimple s!"{tname.getId}_types")
    let typesDefCmd ← `(abbrev $typesDefName : Fin $n → Type := fun x => match x with $alts_types:matchAlt*)

    let cmd ← `(def $tname : LeanDatabase.TypedRelation $typesDefName := { labels := $labels, rows := ∅ })
    let instDecCmd ← `(instance : (i : Fin $n) → DecidableEq ($typesDefName i) :=
      fun x => match x with $alts_tc:matchAlt*)
    let instOrdCmd ← `(instance : (i : Fin $n) → LinearOrder ($typesDefName i) :=
      fun x => match x with $alts_tc:matchAlt*)

    elabCommand typesDefCmd
    elabCommand instDecCmd
    elabCommand instOrdCmd
    elabCommand cmd
    elabCommand schemaCmd

  | _ => throwUnsupportedSyntax


/-incomplete and incorrect-/
@[command_elab selectCmd]
def elabSelectCmd : CommandElab := fun stx =>
  match stx with
  | `(command| SELECT $[$cols],* FROM $table WHERE $cond) => do
    liftTermElabM do
      let tableExpr ← elabTerm table none
      let tableType ← inferType tableExpr
      logInfo s!"Table Type: {←ppExpr <| tableType}"

      let args := tableType.getAppArgs
      let types := args.getD 1 (mkStrLit "")
      logInfo s!"types:{← ppExpr <| types}"
      let typesArrExpr ← mkAppM ``Array.ofFn #[types]

      let labels ← mkProjection tableExpr `labels
      logInfo s!"Labels:{← ppExpr <| (← whnf labels)}"

      let labels_elab ← inferType labels
      logInfo s!"LabelType:{labels_elab}"

      let labelsArrExpr ← mkAppM ``Array.ofFn #[labels]
      logInfo s!"LabelsArray:{← ppExpr <| (← reduce labelsArrExpr)}"

      let labelsArr : Array String ← unsafe evalExpr (Array String) (← mkAppM ``Array #[mkConst ``String ]) (labelsArrExpr)
      logInfo s!"LabelsArray:{labelsArr}"

      let rows ← mkProjection tableExpr `rows
      logInfo s!"Rows:{← ppExpr <| rows}"

      let rowsType ← inferType rows
      logInfo s!"RowsType:{← ppExpr <| rowsType}"

      logInfo s!"ColumnNames:{cols}"
      let n := cols.size
      let nExpr := mkNatLit n
      logInfo s!"n:{nExpr}"
      let colsArr := cols.map (fun c => c.getId.toString)
      logInfo s!"ColsArr:{colsArr}"
      let indexArr := colsArr.map (fun c => labelsArr.findIdx (.==c))
      logInfo s!"indexArr:{indexArr}"
      let labelsNewArr ← mkListLit (mkConst ``String) (indexArr.map (fun n => mkStrLit labelsArr[n]!)).toList
      logInfo s!"{← ppExpr <| labelsNewArr}"
      --let typesNewArr ← mkListLit (mkConst ``String) (indexArr.map (fun n => mkStrLit typesArr[n]!)).toList
      let finType ← mkAppM ``Fin #[nExpr]

      let labelsNewExpr ← withLocalDecl `i .default finType fun i => do
        let body ← mkAppM ``List.get #[labelsNewArr, i]
        mkLambdaFVars #[i] body
      logInfo s!"LambdaExpr:{← ppExpr <| labelsNewExpr}"

      --let typesNewExpr ← withLocalDecl `i .default finType fun i => do
        --let body ← mkAppM ``List.get #[typesNewArr, i]
        --mkLambdaFVars #[i] body
      --logInfo s!"LambdaExpr:{← ppExpr <| typesNewExpr}"

      match tableType.getAppFn with
      | Expr.const structName .. =>
        let env ← getEnv
        if isStructure env structName then
          logInfo s!"{getStructureFields env structName}"
        else
          throwError "Type {structName} is not a structure"
      | _ => throwError "Nah Nah"
  | _ => throwError "Invalid SELECT syntax"


-- Testing the syntax

CREATE TABLE Products (product_id INT, product_name STRING, price INT, STOCK_SIZE INT)
#check Products
