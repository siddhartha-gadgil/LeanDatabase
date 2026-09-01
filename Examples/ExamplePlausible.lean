import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
import LeanDatabase.SQLEquiv
open LeanDatabase Lean

/-!
# Example — counterexamples: finding them, and checking they are real

`sql_equiv` proves. When a pair is *not* an equivalence it used to only fail, and a failure never said
which case you were in. `sql_equiv` now starts with a counterexample search (`sql_disprove`), so a
non-equivalence stops immediately on a message naming the database — and since the search can never
close a goal, a proof is still a proof.

This file covers the three things worth pinning down:

1. `sql_equiv` reports a counterexample instead of failing, and still proves real equivalences;
2. the counterexamples are genuine — `decide` proves it, so the kernel rechecks them on every build;
3. they are *set* counterexamples. Our semantics are set semantics, so a pair differing only in row
   multiplicity is **not** a counterexample; the goals below are all `~=`, equality of row `Finset`s,
   which cannot be satisfied by a multiplicity difference.

The databases here are the ones `plausible` actually reported on the Literature benchmark.
-/

namespace ExamplePlausible

/-! ## 1. The tactic reports, rather than fails

Literature 8: `WHERE A = 5 AND C < 1` versus `WHERE A < 10`. -/

CREATE TABLE R («A» INT, «B» INT, «C» INT)

/--
error: these queries are not equivalent — `plausible` found a database where they differ:

===================
Found a counter-example!
t := [(0, 0, 0)]
first query: 0 row(s), second: 1; 0 only in the first, 1 only in the second
(2 shrinks)
-------------------
-/
#guard_msgs in
example (t : TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.int, SQLTypeProxy.int]) :
    (sql%([R_schema]) "SELECT X.B AS XB FROM R AS X WHERE X.A = 5 AND X.C < 1") t
  ~= (sql%([R_schema]) "SELECT X.B AS XB FROM R AS X WHERE X.A < 10") t := by
  sql_equiv

-- A real equivalence still proves: the two `WHERE` conjuncts commute.
example (t : TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.int, SQLTypeProxy.int]) :
    (sql%([R_schema]) "SELECT X.B AS XB FROM R AS X WHERE X.A = 5 AND X.C < 1") t
  ~= (sql%([R_schema]) "SELECT X.B AS XB FROM R AS X WHERE X.C < 1 AND X.A = 5") t := by
  sql_equiv

/-! ## 2. The counterexample is real -/

/-- The database `plausible` reported: `t := [(0, 0, 0)]`. -/
def r8 : TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.int, SQLTypeProxy.int] :=
  { labels := fun _ => "",
    rows := [TypedTupleOfList.cons _ (0 : Int)
              (TypedTupleOfList.cons _ (0 : Int)
                (TypedTupleOfList.cons _ (0 : Int) TypedTupleOfList.nil))].toFinset }

/-- info: 0 -/
#guard_msgs in
#eval ((sql%([R_schema]) "SELECT X.B AS XB FROM R AS X WHERE X.A = 5 AND X.C < 1") r8).rows.card

/-- info: 1 -/
#guard_msgs in
#eval ((sql%([R_schema]) "SELECT X.B AS XB FROM R AS X WHERE X.A < 10") r8).rows.card

theorem lit8_not_equivalent :
    ¬ ((sql%([R_schema]) "SELECT X.B AS XB FROM R AS X WHERE X.A = 5 AND X.C < 1") r8
     ~= (sql%([R_schema]) "SELECT X.B AS XB FROM R AS X WHERE X.A < 10") r8) := by
  decide

/-! ## 3. A *set* counterexample, on two rows

Literature 63: a global `MAX(CREDITS)` versus a per-department one. This is the case worth checking,
because its counterexample has two rows — if our verdicts were about bags, a difference in row
multiplicity could masquerade as one. It cannot: the results differ as sets, one department against
two. -/

CREATE TABLE COURSE («COURSE_ID» INT, «TITLE» INT, «DEPT_NAME» INT, «CREDITS» INT)
CREATE TABLE DEPARTMENT («DEPT_NAME» INT, «BUILDING» INT, «BUDGET» INT)

/-- An empty table, for the schemas the query never touches. -/
def emptyOf (l : List SQLTypeProxy) : TypedRelationOfList l :=
  { labels := fun _ => "", rows := ∅ }

/-- Two courses: department `0` with 0 credits, department `1` with 1 credit. The global maximum is
`1`; the per-department maxima are `0` and `1`. -/
def course63 : TypedRelationOfList
    [SQLTypeProxy.int, SQLTypeProxy.int, SQLTypeProxy.int, SQLTypeProxy.int] :=
  { labels := fun _ => "",
    rows := [ TypedTupleOfList.cons _ (0 : Int) (TypedTupleOfList.cons _ (0 : Int)
                (TypedTupleOfList.cons _ (0 : Int) (TypedTupleOfList.cons _ (0 : Int)
                  TypedTupleOfList.nil))),
              TypedTupleOfList.cons _ (0 : Int) (TypedTupleOfList.cons _ (0 : Int)
                (TypedTupleOfList.cons _ (1 : Int) (TypedTupleOfList.cons _ (1 : Int)
                  TypedTupleOfList.nil))) ].toFinset }

-- Only the top-credit department: `{1}`.
/-- info: 1 -/
#guard_msgs in
#eval ((sql%([COURSE_schema, DEPARTMENT_schema])
  "SELECT DISTINCT DEPT_NAME FROM COURSE WHERE CREDITS = (SELECT MAX(CREDITS) FROM COURSE)")
    course63 (emptyOf _)).rows.card

-- Every department, since each is its own group's maximum: `{0, 1}`.
/-- info: 2 -/
#guard_msgs in
#eval ((sql%([COURSE_schema, DEPARTMENT_schema])
  "SELECT DISTINCT DEPT_NAME FROM COURSE AS C, (SELECT MAX(CREDITS) AS MAX_CREDITS FROM COURSE GROUP BY DEPT_NAME) AS A WHERE C.CREDITS = A.MAX_CREDITS")
    course63 (emptyOf _)).rows.card

theorem lit63_not_equivalent :
    ¬ ((sql%([COURSE_schema, DEPARTMENT_schema])
          "SELECT DISTINCT DEPT_NAME FROM COURSE WHERE CREDITS = (SELECT MAX(CREDITS) FROM COURSE)")
            course63 (emptyOf _)
     ~= (sql%([COURSE_schema, DEPARTMENT_schema])
          "SELECT DISTINCT DEPT_NAME FROM COURSE AS C, (SELECT MAX(CREDITS) AS MAX_CREDITS FROM COURSE GROUP BY DEPT_NAME) AS A WHERE C.CREDITS = A.MAX_CREDITS")
            course63 (emptyOf _)) := by
  decide

end ExamplePlausible
