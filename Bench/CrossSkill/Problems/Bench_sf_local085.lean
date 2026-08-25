import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_local085 — crossskill equivalence(s)

Question: Among employees who have more than 50 total orders, which three have the highest percentage of late orders, where an order is considered late if the shipped date is on or after its required date? Please list each employee's ID, the number of late orders, and the corresponding late-order percentage.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_local085

CREATE TABLE ORDERS («orderid» INT, «customerid» STRING, «employeeid» INT, «orderdate» STRING, «requireddate» STRING, «shippeddate» STRING, «shipvia» INT, «freight» FLOAT, «shipname» STRING, «shipaddress» STRING, «shipcity» STRING, «shipregion» STRING, «shippostalcode» STRING, «shipcountry» STRING)

theorem eq_0_1 :
    sql%([ORDERS_schema]) "SELECT \"employeeid\", SUM(CASE WHEN NOT \"shippeddate\" IS NULL AND \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS LATE_ORDER_COUNT, CAST(SUM(CASE WHEN NOT \"shippeddate\" IS NULL AND \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS LATE_ORDER_PERCENTAGE FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" GROUP BY \"employeeid\" HAVING COUNT(*) > 50 ORDER BY LATE_ORDER_PERCENTAGE DESC LIMIT 3" = sql%([ORDERS_schema]) "SELECT \"employeeid\", SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS LATE_ORDER_COUNT, CAST(100.0 * SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS DOUBLE PRECISION) / COUNT(*) AS LATE_ORDER_PERCENTAGE FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" GROUP BY \"employeeid\" HAVING COUNT(*) > 50 ORDER BY LATE_ORDER_PERCENTAGE DESC LIMIT 3" := by
  first | sql_equiv | sorry

theorem eq_0_2 :
    sql%([ORDERS_schema]) "SELECT \"employeeid\", SUM(CASE WHEN NOT \"shippeddate\" IS NULL AND \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS LATE_ORDER_COUNT, CAST(SUM(CASE WHEN NOT \"shippeddate\" IS NULL AND \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS LATE_ORDER_PERCENTAGE FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" GROUP BY \"employeeid\" HAVING COUNT(*) > 50 ORDER BY LATE_ORDER_PERCENTAGE DESC LIMIT 3" = sql%([ORDERS_schema]) "SELECT \"employeeid\", SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS \"LATE_ORDER_COUNT\", ROUND(CAST(CAST(SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 2) AS \"LATE_ORDER_PERCENTAGE\" FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" GROUP BY \"employeeid\" HAVING COUNT(*) > 50 ORDER BY \"LATE_ORDER_PERCENTAGE\" DESC LIMIT 3" := by
  first | sql_equiv | sorry

theorem eq_0_3 :
    sql%([ORDERS_schema]) "SELECT \"employeeid\", SUM(CASE WHEN NOT \"shippeddate\" IS NULL AND \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS LATE_ORDER_COUNT, CAST(SUM(CASE WHEN NOT \"shippeddate\" IS NULL AND \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS LATE_ORDER_PERCENTAGE FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" GROUP BY \"employeeid\" HAVING COUNT(*) > 50 ORDER BY LATE_ORDER_PERCENTAGE DESC LIMIT 3" = sql%([ORDERS_schema]) "SELECT \"employeeid\", SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS LATE_ORDER_COUNT, ROUND(CAST(CAST(SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 6) AS LATE_ORDER_PERCENTAGE FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" GROUP BY \"employeeid\" HAVING COUNT(*) > 50 ORDER BY LATE_ORDER_PERCENTAGE DESC LIMIT 3" := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([ORDERS_schema]) "SELECT \"employeeid\", SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS LATE_ORDER_COUNT, CAST(100.0 * SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS DOUBLE PRECISION) / COUNT(*) AS LATE_ORDER_PERCENTAGE FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" GROUP BY \"employeeid\" HAVING COUNT(*) > 50 ORDER BY LATE_ORDER_PERCENTAGE DESC LIMIT 3" = sql%([ORDERS_schema]) "SELECT \"employeeid\", SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS \"LATE_ORDER_COUNT\", ROUND(CAST(CAST(SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 2) AS \"LATE_ORDER_PERCENTAGE\" FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" GROUP BY \"employeeid\" HAVING COUNT(*) > 50 ORDER BY \"LATE_ORDER_PERCENTAGE\" DESC LIMIT 3" := by
  first | sql_equiv | sorry

theorem eq_1_3 :
    sql%([ORDERS_schema]) "SELECT \"employeeid\", SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS LATE_ORDER_COUNT, CAST(100.0 * SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS DOUBLE PRECISION) / COUNT(*) AS LATE_ORDER_PERCENTAGE FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" GROUP BY \"employeeid\" HAVING COUNT(*) > 50 ORDER BY LATE_ORDER_PERCENTAGE DESC LIMIT 3" = sql%([ORDERS_schema]) "SELECT \"employeeid\", SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS LATE_ORDER_COUNT, ROUND(CAST(CAST(SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 6) AS LATE_ORDER_PERCENTAGE FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" GROUP BY \"employeeid\" HAVING COUNT(*) > 50 ORDER BY LATE_ORDER_PERCENTAGE DESC LIMIT 3" := by
  first | sql_equiv | sorry

theorem eq_2_3 :
    sql%([ORDERS_schema]) "SELECT \"employeeid\", SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS \"LATE_ORDER_COUNT\", ROUND(CAST(CAST(SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 2) AS \"LATE_ORDER_PERCENTAGE\" FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" GROUP BY \"employeeid\" HAVING COUNT(*) > 50 ORDER BY \"LATE_ORDER_PERCENTAGE\" DESC LIMIT 3" = sql%([ORDERS_schema]) "SELECT \"employeeid\", SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS LATE_ORDER_COUNT, ROUND(CAST(CAST(SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 6) AS LATE_ORDER_PERCENTAGE FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" GROUP BY \"employeeid\" HAVING COUNT(*) > 50 ORDER BY LATE_ORDER_PERCENTAGE DESC LIMIT 3" := by
  first | sql_equiv | sorry

end Bench_sf_local085
