/-!
# SQL surface-syntax normalization (custom string handlers)

Pure `String`→`String` rewrites that massage sqlglot's PostgreSQL output into what the `sql_query`
grammar accepts: comment stripping, quoted-identifier/​literal conversion, `::`→`CAST`, VARIANT path
access, alias wrapping, and `LATERAL FLATTEN`/`UNNEST` canonicalization. Extracted from `Query.lean`.
-/

open Lean

namespace LeanDatabase

-- A `"…"` quoted **identifier** → a Lean guillemet identifier `«…»`, which is immune to keyword
-- collisions (a column named `"YEAR"`/`"END"`/`"COUNT"` won't hit the function/keyword token). The
-- resulting `Name` is the same as the bare form, so it still matches the (case-folded) schema. Dots
-- between quoted parts (`"A"."B"`) sit outside the quotes, so the main loop copies them → `«A».«B»`.
private def unquoteIdent : List Char → String → String × List Char
  | [], acc => (acc.push '»', [])
  | '"' :: rest, acc => (acc.push '»', rest)
  | c :: rest, acc => unquoteIdent rest (acc.push c)

private def convSingleQuoted : List Char → String → String × List Char
  | [], acc => (acc.push '"', [])
  | '\'' :: '\'' :: rest, acc => convSingleQuoted rest (acc.push '\'')   -- SQL `''` = escaped quote
  | '\'' :: rest, acc => (acc.push '"', rest)
  | '"' :: rest, acc => convSingleQuoted rest ((acc.push '\\').push '"') -- escape inner `"`
  -- SQL backslashes are literal; escape them so the emitted Lean string literal is valid (a regex
  -- like `'stackoverflow\.com'` would otherwise produce the invalid Lean escape `\.`).
  | '\\' :: rest, acc => convSingleQuoted rest ((acc.push '\\').push '\\')
  | c :: rest, acc => convSingleQuoted rest (acc.push c)

private partial def normalizeGo : List Char → String → String
  | [], acc => acc
  | '"' :: rest, acc => let (acc, rest) := unquoteIdent rest (acc.push '«'); normalizeGo rest acc
  | '\'' :: rest, acc => let (acc, rest) := convSingleQuoted rest (acc.push '"'); normalizeGo rest acc
  | c :: rest, acc => normalizeGo rest (acc.push c)

-- `::` cast rewriting (C3): `X::TYPE` → `CAST(X AS TYPE)`, reusing the sound CAST elaborator. Output
-- is built as a *reversed* char list so the operand (already emitted) can be popped off its front.
private def dropSp : List Char → List Char
  | ' ' :: r => dropSp r
  | l => l
private def isOpChar (c : Char) : Bool :=
  c.isAlphanum || c == '_' || c == '.' || c == '"' || c == '«' || c == '»'
-- pop a plain operand (ident/dotted/number/quoted) off the reversed output
private def takeRunBack : List Char → List Char → (List Char × List Char)
  | c :: rest, acc => if isOpChar c then takeRunBack rest (c :: acc) else (acc, c :: rest)
  | [], acc => (acc, [])
-- pop a balanced `(…)` group off the reversed output (head is the closing `)`)
private def takeBalancedBack : List Char → Nat → List Char → (List Char × List Char)
  | c :: rest, depth, acc =>
      let acc := c :: acc
      let depth := if c == ')' then depth + 1 else if c == '(' then depth - 1 else depth
      if c == '(' && depth == 0 then (acc, rest) else takeBalancedBack rest depth acc
  | [], _, acc => (acc, [])
-- extend an operand leftward over a preceding function name (`SUM(x)` not just `(x)`)
private def takeFuncName : List Char → List Char → (List Char × List Char)
  | c :: rest, acc => if c.isAlphanum || c == '_' then takeFuncName rest (c :: acc) else (acc, c :: rest)
  | [], acc => (acc, [])
-- Pop the operand ending at the head of the reversed output `out`: a balanced `(…)` call (with its
-- function name) if it ends in `)`, else a plain column run. Shared by `castGo`/`pathGo`.
private def popOperand (out : List Char) : List Char × List Char :=
  match out with
  | ')' :: _ => let (p, rem) := takeBalancedBack out 0 []; takeFuncName rem p
  | _ => takeRunBack out []
-- read a bare type word, then discard an optional `(size)` the cast grammar doesn't take
private def takeTypeWord : List Char → List Char → (String × List Char)
  | c :: rest, acc => if c.isAlphanum || c == '_' then takeTypeWord rest (acc ++ [c]) else (String.ofList acc, c :: rest)
  | [], acc => (String.ofList acc, [])
private partial def dropParenSize : List Char → List Char
  | '(' :: rest => (rest.dropWhile (· != ')')).drop 1
  | l => l
private partial def castGo : List Char → List Char → List Char
  | [], out => out
  | ':' :: ':' :: rest, out =>
      let out := dropSp out
      let (operand, out') := popOperand out
      let (ty, rest2) := takeTypeWord (dropSp rest) []
      let emit := "CAST(" ++ String.ofList operand ++ " AS " ++ ty ++ ")"
      castGo (dropParenSize (dropSp rest2)) (emit.toList.reverse ++ out')
  | c :: rest, out => castGo rest (c :: out)

-- Strip SQL comments (`-- …` to end of line, `/* … */`), skipping over string literals so a `--` or
-- `/*` inside a string is preserved. Runs first, before any other normalization.
private partial def dropBlockComment : List Char → List Char
  | '*' :: '/' :: rest => rest
  | _ :: rest => dropBlockComment rest
  | [] => []
-- Case-insensitive prefix match; returns the remaining chars after `kw` on success.
private def ciPrefix : List Char → List Char → Option (List Char)
  | [], rest => some rest
  | k :: ks, c :: cs => if k == c.toLower then ciPrefix ks cs else none
  | _ :: _, [] => none

-- At a word boundary, `INNER JOIN` → ` JOIN` (the redundant qualifier reuses the plain-`JOIN` grammar).
private def dropInnerKW : List Char → Option (List Char)
  | l =>
    match ciPrefix ['i','n','n','e','r'] l with
    | some (w :: after) =>
        if w == ' ' || w == '\n' || w == '\t' then
          match ciPrefix ['j','o','i','n'] ((w :: after).dropWhile fun c => c == ' ' || c == '\n' || c == '\t') with
          | some _ => some (' ' :: (w :: after).dropWhile fun c => c == ' ' || c == '\n' || c == '\t')
          | none => none
        else none
    | _ => none

mutual
private partial def stripComments : List Char → String → String
  | [], acc => acc
  | '-' :: '-' :: rest, acc => stripComments (rest.dropWhile (· != '\n')) acc
  | '/' :: '*' :: rest, acc => stripComments (dropBlockComment rest) acc
  | '\'' :: rest, acc => copyQuotedFwd '\'' rest (acc.push '\'')
  | '"' :: rest, acc => copyQuotedFwd '"' rest (acc.push '"')
  | c :: rest, acc =>
      let boundary := acc.isEmpty || !(acc.back.isAlphanum || acc.back == '_')
      match (if boundary && (c == 'I' || c == 'i') then dropInnerKW (c :: rest) else none) with
      | some rest' => stripComments rest' acc
      | none => stripComments rest (acc.push c)
private partial def copyQuotedFwd (q : Char) : List Char → String → String
  | c :: rest, acc => if c == q then stripComments rest (acc.push c) else copyQuotedFwd q rest (acc.push c)
  | [], acc => acc
end

-- `AS <keyword>` alias support: keywords like `YEAR`/`MONTH`/`DATE`/`COUNT` are reserved tokens, so a
-- column/table alias that reuses one won't parse. Guillemet-wrap it (`AS «YEAR»`). A cast type
-- (`CAST(x AS DATE)`) is left alone — it is always followed by `)`/`(`, which the rule excludes.
private def isWordChar (c : Char) : Bool := c.isAlphanum || c == '_'

private def ciTake : List Char → List Char → List Char → Option (List Char × List Char)
  | [], rest, acc => some (acc.reverse, rest)
  | k :: ks, c :: cs, acc => if k == c.toLower then ciTake ks cs (c :: acc) else none
  | _ :: _, [], _ => none

-- Longest-first so `dayofweek`/`timestamp` win over their `day`/`time` prefixes. Includes reserved
-- function/window keywords (`RANK`, `ROW_NUMBER`, …) that queries also use as `AS` aliases.
private def aliasKWList : List (List Char) :=
  ["dayofweek","row_number","dense_rank","timestamp","quarter","second","minute","month","count","week","hour","year","date","time","rank","day"].map (·.toList)

private def tryAliasKW : List (List Char) → List Char → Option (List Char × List Char)
  | [], _ => none
  | kw :: rest, l =>
    match ciTake kw l [] with
    | some (orig, rem) =>
        match rem with
        | c :: _ => if isWordChar c then tryAliasKW rest l else some (orig, rem)
        | []     => some (orig, rem)
    | none => tryAliasKW rest l

-- On seeing `AS`, if a collision keyword follows (not a cast type), return the matched keyword chars
-- and the remainder after it; else none.
private def matchAsAlias (l : List Char) : Option (List Char × List Char) :=
  match ciTake ['a','s'] l [] with
  | some (_, sp :: r1) =>
      if sp == ' ' || sp == '\n' || sp == '\t' then
        let r1 := (sp :: r1).dropWhile fun c => c == ' ' || c == '\n' || c == '\t'
        match tryAliasKW aliasKWList r1 with
        | some (kw, r2) =>
            match r2.dropWhile (fun c => c == ' ' || c == '\n' || c == '\t') with
            | c :: _ => if c == '(' || c == ')' then none else some (kw, r2)
            | []     => some (kw, r2)
        | none => none
      else none
  | _ => none

-- Copy a quoted run (up to and including the closing `q`) verbatim.
private def copyQuotedRun (q : Char) : List Char → String → String × List Char
  | c :: rest, acc => if c == q then (acc.push c, rest) else copyQuotedRun q rest (acc.push c)
  | [], acc => (acc, [])

-- `LEFT(`/`RIGHT(` (the string functions) collide with the `LEFT`/`RIGHT` JOIN keywords, which breaks
-- join chains (an `ON` term greedily tries `LEFT(…)` as an application). Rename the *function* form to
-- a distinct token so `LEFT`/`RIGHT` are join-only. Only fires when a `(` follows.
private def matchFnRename (l : List Char) : Option (String × List Char) :=
  let tryKW (kw : List Char) (repl : String) : Option (String × List Char) :=
    match ciTake kw l [] with
    | some (_, rem) =>
        match rem.dropWhile (fun c => c == ' ' || c == '\n' || c == '\t') with
        | '(' :: _ => some (repl, rem)
        | _ => none
    | none => none
  (tryKW ['l','e','f','t'] "LEFTSTR").orElse fun _ => tryKW ['r','i','g','h','t'] "RIGHTSTR"

private partial def wrapAliasGo : List Char → String → String
  | [], acc => acc
  | '\'' :: rest, acc => let (s, r) := copyQuotedRun '\'' rest (String.singleton '\''); wrapAliasGo r (acc ++ s)
  | '"'  :: rest, acc => let (s, r) := copyQuotedRun '"'  rest (String.singleton '"');  wrapAliasGo r (acc ++ s)
  | c :: rest, acc =>
      let boundary := acc.isEmpty || !(isWordChar acc.back)
      let fn := if boundary && (c == 'l' || c == 'L' || c == 'r' || c == 'R') then matchFnRename (c :: rest) else none
      match fn with
      | some (repl, rest') => wrapAliasGo rest' (acc ++ repl)
      | none =>
        match (if boundary && (c == 'a' || c == 'A') then matchAsAlias (c :: rest) else none) with
        | some (kw, rest') => wrapAliasGo rest' (acc ++ "AS «" ++ String.ofList kw ++ "»")
        | none => wrapAliasGo rest (acc.push c)

-- Semi-structured path access `v:key` / `v['key']` → `VARIANTGET(v, 'key')`, at the string level so
-- `:` doesn't clash with Lean's type ascription. Runs before quote/`::` normalization.
private def takeToChar (q : Char) : List Char → String → String × List Char
  | c :: rest, acc => if c == q then (acc, rest) else takeToChar q rest (acc.push c)
  | [], acc => (acc, [])
private def takeKeyWord : List Char → String → String × List Char
  | c :: rest, acc =>
      if c.isAlphanum || c == '_' || c == '.' then takeKeyWord rest (acc.push c) else (acc, c :: rest)
  | [], acc => (acc, [])
private def readKey : List Char → String × List Char
  | '"' :: rest => takeToChar '"' rest ""
  | '\'' :: rest => takeToChar '\'' rest ""
  | l => takeKeyWord l ""
private def copyStrTo (q : Char) : List Char → List Char → List Char × List Char
  | c :: rest, out => if c == q then (c :: out, rest) else copyStrTo q rest (c :: out)
  | [], out => (out, [])
private partial def pathGo : List Char → List Char → List Char
  | [], out => out
  | '\'' :: rest, out => let (out, rest) := copyStrTo '\'' rest ('\'' :: out); pathGo rest out
  | '"' :: rest, out => let (out, rest) := copyStrTo '"' rest ('"' :: out); pathGo rest out
  | ':' :: ':' :: rest, out => pathGo rest (':' :: ':' :: out)          -- leave `::` for castGo
  | ':' :: rest, out =>
      let out := dropSp out
      let (operand, out') := popOperand out
      let (key, rest') := readKey (dropSp rest)
      let emit := "VARIANTGET(" ++ String.ofList operand ++ ", '" ++ key ++ "')"
      pathGo rest' (emit.toList.reverse ++ out')
  | '[' :: rest, out =>
      -- `operand['key']` access only — a *quoted* key must follow, so array literals `[1,2]` are left
      -- alone.
      match out, dropSp rest with
      | h :: _, (q :: _) =>
        if (isOpChar h || h == ')') && (q == '\'' || q == '"') then
          let (operand, out') := popOperand out
          let (key, rest0) := readKey (dropSp rest)
          let rest' := (rest0.dropWhile (· != ']')).drop 1
          let emit := "VARIANTGET(" ++ String.ofList operand ++ ", '" ++ key ++ "')"
          pathGo rest' (emit.toList.reverse ++ out')
        else pathGo rest ('[' :: out)
      | _, _ => pathGo rest ('[' :: out)
  | c :: rest, out => pathGo rest (c :: out)

/-! ## `LATERAL FLATTEN` canonicalization

sqlglot renders Snowflake `LATERAL FLATTEN` as `LATERAL UNNEST(input => e) AS h(SEQ, …)` (with
`input =>`/no-`input`, `UNNEST`/`FLATTEN`, `AS`/bare-alias variants). Fold every spelling to the
single token `LATERALFLATTEN(e)` (keeping the trailing `[AS] alias (cols)` for the grammar), so one
FROM production and one operator handle them all. -/
private def dropWsF : List Char → List Char
  | c :: r => if c == ' ' || c == '\n' || c == '\t' then dropWsF r else c :: r
  | [] => []
-- Case-insensitive keyword match at a *word boundary* (next char is non-word or end).
private def ciWord (kw : List Char) (l : List Char) : Option (List Char) :=
  match ciPrefix kw l with
  | some (c :: r) => if isWordChar c then none else some (c :: r)
  | some []       => some []
  | none          => none
-- At a `LATERAL` token, match `LATERAL (UNNEST|FLATTEN) ( [input =>]` and return the chars right
-- after the `(` (and after any `input =>`). `none` if it isn't a FLATTEN/UNNEST lateral.
private def tryLateral (l : List Char) : Option (List Char) :=
  match ciWord ['l','a','t','e','r','a','l'] l with
  | none => none
  | some r1 =>
    let r2 := dropWsF r1
    match (ciWord ['u','n','n','e','s','t'] r2).orElse (fun _ => ciWord ['f','l','a','t','t','e','n'] r2) with
    | none => none
    | some r3 =>
      match dropWsF r3 with
      | '(' :: r5 =>
        let r6 := dropWsF r5
        match ciWord ['i','n','p','u','t'] r6 with
        | some rIn => match dropWsF rIn with
                      | '=' :: '>' :: r'' => some (dropWsF r'')
                      | _ => some r6
        | none => some r6
      | _ => none
private partial def flattenGo : List Char → String → String
  | [], acc => acc
  | '\'' :: rest, acc => let (s, r) := copyQuotedRun '\'' rest (String.singleton '\''); flattenGo r (acc ++ s)
  | '"'  :: rest, acc => let (s, r) := copyQuotedRun '"'  rest (String.singleton '"');  flattenGo r (acc ++ s)
  | c :: rest, acc =>
      let boundary := acc.isEmpty || !(isWordChar acc.back)
      match (if boundary && (c == 'l' || c == 'L') then tryLateral (c :: rest) else none) with
      | some rest' => flattenGo rest' (acc ++ "LATERALFLATTEN(")
      | none => flattenGo rest (acc.push c)

/-- Normalize SQL surface syntax to what the grammar accepts (C3): path access `v:key`/`v['key']` →
`VARIANTGET`, `'…'` strings → `"…"`, double-quoted **identifiers** → bare idents, `X::TYPE` → `CAST`. -/
def normalizeSqlLiterals (s : String) : String :=
  let s := stripComments s.toList ""
  -- Quantified subquery comparisons: `x <> ALL (subq)` ≡ `x NOT IN (subq)`, `x = ANY/SOME (subq)` ≡
  -- `x IN (subq)` (the equivalences that hold for any subquery). sqlglot emits the keywords uppercase.
  let s := s.replace " <> ALL (" " NOT IN ("
  let s := s.replace " = ANY (" " IN ("
  let s := s.replace " = SOME (" " IN ("
  -- `[LEFT|CROSS|INNER] JOIN LATERAL UNNEST(…)` → the comma-lateral the `LATERALFLATTEN` grammar
  -- accepts; and drop UNNEST's trailing named args (`, OUTER => TRUE/FALSE`) that follow the input.
  let s := s.replace "LEFT JOIN LATERAL" ", LATERAL"
  let s := s.replace "CROSS JOIN LATERAL" ", LATERAL"
  let s := s.replace "INNER JOIN LATERAL" ", LATERAL"
  let s := s.replace "JOIN LATERAL" ", LATERAL"
  let s := s.replace ", OUTER => TRUE" ""
  let s := s.replace ", OUTER => FALSE" ""
  let s := flattenGo s.toList ""
  let s := wrapAliasGo s.toList ""
  let s := String.ofList (pathGo s.toList []).reverse
  String.ofList (castGo (normalizeGo s.toList "").toList []).reverse

end LeanDatabase
