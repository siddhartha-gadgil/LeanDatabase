# Representing SQL in Lean

* Schema gives type of TypedRelation.
  * Here a schema is a list of pairs Name and SQL-type.
* An actual Database is a `TypedRelation`.

## Overall Context

* We have a collection of typed-relations: variables representing this.
* A database is obtained as lambda wrt the collection of type-relation variables.
* Properties such as equivalence are ∀ wrt the collection of type-relation variables.

## TypedTuple context

* Given a `TypedRelation` we can introduce variables for labels of the typed-relation.
* These are used to filter and map on TypedTuples.

## Context with column variables

* Given schema and names, we introduce `let` variables for the columns.
* __TODO:__ Preprocess schema to have full names if not already full names.
* __TODO:__ Use only variables in context.
* __TODO:__ Preprocess query replace short names by full names.

## Product

* Everything already has full names, so no need of `L` and `R`.
* For queries `SELECT * FROM p1, p2 WHERE q` we simply construct the product from the context variables for `p1` and `p2` (we need to map schema names to corresponging variables) and then use the columns of this.

## Selection

* If we have `SELECT c1, (x1 AS n) FROM p1, p2 WHERE q` we should get a typedrelation.
* We get labels for the output from the syntax.
* By elaboration we get expressions for the output.
* We fold these.

## GROUP BY

* The grouping columns are just like selection.
* We then introduce variables for:
  * Columns in the group-by.
  * Aggregates of other columns - if they appear in the syntax.
* Now elaborate `HAVING` and filter again.
* Also elaborate the selection.

## Missing

* Subtables
* Null values and hence `LEFT JOIN`.
