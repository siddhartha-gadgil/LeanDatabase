import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_local085 — proven cross-skill equivalence(s)

Question: Among employees who have more than 50 total orders, which three have the highest percentage of late orders, where an order is considered late if the shipped date is on or after its required date? Please list each employee's ID, the number of late orders, and the corresponding late-order percentage.

Independently-written SQL variants proved equal for all table contents by `sql_equiv`; where
they differ by a `WHERE`/`SELECT` expression, that data fact is an explicit `HYPOTHESIS` antecedent.
-/

namespace P_sf_local085

CREATE TABLE ORDERS («orderid» INT, «customerid» STRING, «employeeid» INT, «orderdate» STRING, «requireddate» STRING, «shippeddate» STRING, «shipvia» INT, «freight» FLOAT, «shipname» STRING, «shipaddress» STRING, «shipcity» STRING, «shipregion» STRING, «shippostalcode» STRING, «shipcountry» STRING)

theorem eq_0_1 (t : TableRel ORDERS_schema) :
    (sql%([ORDERS_schema]) "SELECT\n  \"employeeid\",\n  SUM(CASE WHEN \"shippeddate\" IS NOT NULL AND \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS LATE_ORDER_COUNT,\n  SUM(CASE WHEN \"shippeddate\" IS NOT NULL AND \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS LATE_ORDER_PERCENTAGE\nFROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\"\nGROUP BY \"employeeid\"\nHAVING COUNT(*) > 50\nORDER BY LATE_ORDER_PERCENTAGE DESC\nLIMIT 3;") t = (sql%([ORDERS_schema]) "SELECT\n    \"employeeid\",\n    SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS LATE_ORDER_COUNT,\n    100.0 * SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) / COUNT(*) AS LATE_ORDER_PERCENTAGE\nFROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\"\nGROUP BY \"employeeid\"\nHAVING COUNT(*) > 50\nORDER BY LATE_ORDER_PERCENTAGE DESC\nLIMIT 3;") t := by sql_equiv

end P_sf_local085
