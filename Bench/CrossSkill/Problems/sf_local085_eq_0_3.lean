import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local085_eq_0_3

CREATE TABLE ORDERS («orderid» INT, «customerid» STRING, «employeeid» INT, «orderdate» STRING, «requireddate» STRING, «shippeddate» STRING, «shipvia» INT, «freight» FLOAT, «shipname» STRING, «shipaddress» STRING, «shipcity» STRING, «shipregion» STRING, «shippostalcode» STRING, «shipcountry» STRING)

theorem eq (t0 : TableRel ORDERS_schema) :
    (sql%([ORDERS_schema]) "SELECT \"employeeid\", SUM(CASE WHEN NOT \"shippeddate\" IS NULL AND \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS LATE_ORDER_COUNT, CAST(SUM(CASE WHEN NOT \"shippeddate\" IS NULL AND \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS LATE_ORDER_PERCENTAGE FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" GROUP BY \"employeeid\" HAVING COUNT(*) > 50 ORDER BY LATE_ORDER_PERCENTAGE DESC LIMIT 3") t0
  = (sql%([ORDERS_schema]) "SELECT \"employeeid\", SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) AS LATE_ORDER_COUNT, ROUND(CAST(CAST(SUM(CASE WHEN \"shippeddate\" >= \"requireddate\" THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 6) AS LATE_ORDER_PERCENTAGE FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" GROUP BY \"employeeid\" HAVING COUNT(*) > 50 ORDER BY LATE_ORDER_PERCENTAGE DESC LIMIT 3") t0
  := by first | sql_equiv | sorry

end N_sf_local085_eq_0_3
