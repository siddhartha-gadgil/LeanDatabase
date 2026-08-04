# Working conventions

## Commits
- **Bigger commits.** Batch related work into one meaningful commit — don't commit small isolated
  changes one at a time. Group a feature + its example + roadmap tick into a single commit.
- One **informal** subject line, no `TASK:`/`S1:`/prefix codes, no body/description.
- Keep the required `Co-Authored-By:` trailer.

## Comments
- Concise. One or two lines, only where the *why* isn't obvious from the code.
- Put longer rationale (soundness arguments, design notes) in module docstrings or `ROADMAP.md`,
  not inline.

## Soundness
`sql_equiv` must never prove a false equivalence. Prefer making an unsound claim a **type error**
(e.g. `AVG`/`CAST` are real `Rat`) or **unprovable** (opaque scalars) over silently equating things.
When a construct can't be modelled, **fail loudly** rather than approximate.

## Extending the parser
Each extension point (scalar / aggregate / clause / FROM form / dialect) has one home — see
`LeanDatabase/Parser/README.md`. Adding a scalar is one line: `scalar1 "SQRT" "sqrtOf"`.

## Build
`lake build` should stay green (all examples prove). Run it before committing.
