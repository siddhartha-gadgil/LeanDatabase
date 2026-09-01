import Plausible

/-!
# Literal mining — sampling the values the query actually talks about

Random sampling almost never disproves a query pair whose predicates mention specific values. A
filter `WHERE X.YX = 'HELLO'` is false on every random string; `WHERE Y.SIZE > 100000` is false on
every small random integer. The standard property-testing answer is to *mine the constants out of the
property under test* and feed them back to the generators, which is what this module does: before the
search runs, the driver fills a pool with every integer and string literal appearing in the pair's
SQL, and the samplers draw from it half the time.

The pool is a process-global `IO.Ref` read from pure generator code, so the reader is `implemented_by`
an unsafe accessor whose *logical* value is the empty pool. That is sound for our purpose in the way
that matters: the pool only decides which databases get *tried*. Whether a database is a
counterexample is settled afterwards by `Decidable`, and `Plausible.TestResult.failure` carries the
`¬p` proof, so no amount of lying about the pool can produce a wrong verdict.
-/

namespace LeanDatabase.Plausible

/-- Integer and string literals mined from the query pair currently under test. -/
initialize constantPool : IO.Ref (Array Int × Array String) ← IO.mkRef (#[], #[])

@[inline] private unsafe def minedConstantsUnsafe : Unit → Array Int × Array String :=
  fun _ =>
    match (unsafeBaseIO (EIO.toBaseIO constantPool.get) : Except IO.Error (Array Int × Array String)) with
    | .ok pool => pool
    | .error _ => (#[], #[])

/-- The mined literals. Logically empty — see the module docstring for why that is fine. -/
@[implemented_by minedConstantsUnsafe]
def minedConstants : Unit → Array Int × Array String := fun _ => (#[], #[])

/-- Every integer and single-quoted string literal in a SQL string. -/
def mineLiterals (sql : String) : Array Int × Array String := Id.run do
  let cs := sql.toList
  let mut ints : Array Int := #[]
  let mut strs : Array String := #[]
  let mut i := 0
  while h : i < cs.length do
    let c := cs[i]
    if c == '\'' then
      -- A quoted literal: take everything up to the closing quote.
      let rest := cs.drop (i + 1)
      let lit := rest.takeWhile (· != '\'')
      strs := strs.push (String.ofList lit)
      i := i + lit.length + 2
    else if c.isDigit then
      let digits := (cs.drop i).takeWhile Char.isDigit
      let n := (String.ofList digits).toNat!
      -- Neighbours of a threshold matter as much as the threshold itself (`> 100000`).
      ints := ints.push (Int.ofNat n) |>.push (Int.ofNat n - 1) |>.push (Int.ofNat n + 1)
      i := i + digits.length
    else
      i := i + 1
  return (ints, strs)

/-- Load the pool from a pair's two queries. Called by the search before testing. -/
def setPoolFrom (first second : String) : IO Unit := do
  let (i1, s1) := mineLiterals first
  let (i2, s2) := mineLiterals second
  constantPool.set (i1 ++ i2, s1 ++ s2)

open _root_.Plausible

/-- Draw from the mined pool, falling back to `g` when the pool is empty. Mixing rather than replacing
matters: the interesting database usually needs *one* value from the query and others that are merely
small and distinct. -/
def withMined {α : Type} [Inhabited α] (pool : Array α) (g : Gen α) : Gen α :=
  match h : pool.size with
  | 0 => g
  | n + 1 =>
    -- Half the draws come from the pool, so unrelated columns still vary.
    Gen.frequency g [(1, g), (1, do
      let ⟨i, _⟩ ← Gen.chooseNatLt 0 (n + 1) (Nat.succ_pos n)
      return pool[i]!)]

end LeanDatabase.Plausible
