import Lean

/-!
# `sql_mem` — the membership-law simp set

A dedicated simp set for the operator membership laws (`LeanDatabase/Membership.lean`), kept out of
the global one so it only fires where `sql_equiv` asks for it. Lean requires an attribute to be
*registered in its own module*, hence this file.
-/

register_simp_attr sql_mem
