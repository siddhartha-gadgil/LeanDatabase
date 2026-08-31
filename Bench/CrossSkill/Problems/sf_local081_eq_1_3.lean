import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local081_eq_1_3

CREATE TABLE CUSTOMERGROUPTHRESHOLD («groupname» STRING, «rangebottom» INT, «rangetop» FLOAT)
CREATE TABLE ORDERS («orderid» INT, «customerid» STRING, «employeeid» INT, «orderdate» STRING, «requireddate» STRING, «shippeddate» STRING, «shipvia» INT, «freight» FLOAT, «shipname» STRING, «shipaddress» STRING, «shipcity» STRING, «shipregion» STRING, «shippostalcode» STRING, «shipcountry» STRING)
CREATE TABLE ORDER_DETAILS («orderid» INT, «productid» INT, «unitprice» FLOAT, «quantity» INT, «discount» FLOAT)

theorem eq (t0 : TableRel CUSTOMERGROUPTHRESHOLD_schema) (t1 : TableRel ORDERS_schema) (t2 : TableRel ORDER_DETAILS_schema) :
    (sql%([CUSTOMERGROUPTHRESHOLD_schema, ORDERS_schema, ORDER_DETAILS_schema]) "WITH customer_spending AS (SELECT o.\"customerid\", SUM(od.\"unitprice\" * od.\"quantity\") AS total_spending FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" AS o JOIN \"NORTHWIND\".\"NORTHWIND\".\"ORDER_DETAILS\" AS od ON o.\"orderid\" = od.\"orderid\" WHERE EXTRACT(YEAR FROM CAST(o.\"orderdate\" AS DATE)) = 1998 GROUP BY o.\"customerid\"), total_customers AS (SELECT COUNT(*) AS total_count FROM customer_spending), grouped AS (SELECT cgt.\"groupname\" AS \"group\", COUNT(cs.\"customerid\") AS total_customer FROM customer_spending AS cs JOIN \"NORTHWIND\".\"NORTHWIND\".\"CUSTOMERGROUPTHRESHOLD\" AS cgt ON cs.total_spending BETWEEN cgt.\"rangebottom\" AND cgt.\"rangetop\" GROUP BY cgt.\"groupname\") SELECT g.\"group\", g.total_customer, CAST(CAST(g.total_customer * 100.0 AS DOUBLE PRECISION) / tc.total_count AS DECIMAL(18, 6)) AS percentage FROM grouped AS g CROSS JOIN total_customers AS tc ORDER BY g.total_customer DESC") t0 t1 t2
  ~= (sql%([CUSTOMERGROUPTHRESHOLD_schema, ORDERS_schema, ORDER_DETAILS_schema]) "WITH customer_spending AS (SELECT o.\"customerid\", SUM(od.\"unitprice\" * od.\"quantity\") AS total_spent FROM \"NORTHWIND\".\"NORTHWIND\".\"ORDERS\" AS o JOIN \"NORTHWIND\".\"NORTHWIND\".\"ORDER_DETAILS\" AS od ON o.\"orderid\" = od.\"orderid\" WHERE EXTRACT(YEAR FROM CAST(TO_TIMESTAMP(o.\"orderdate\", 'YYYY-MM-DD') AS DATE)) = 1998 GROUP BY o.\"customerid\"), customer_groups AS (SELECT cs.\"customerid\", cgt.\"groupname\" AS \"group\" FROM customer_spending AS cs JOIN \"NORTHWIND\".\"NORTHWIND\".\"CUSTOMERGROUPTHRESHOLD\" AS cgt ON cs.total_spent >= cgt.\"rangebottom\" AND cs.total_spent < cgt.\"rangetop\"), total_count AS (SELECT COUNT(*) AS total FROM customer_groups) SELECT cg.\"group\", COUNT(*) AS \"total_customer\", CAST(COUNT(*) * 100.0 AS DOUBLE PRECISION) / tc.total AS \"percentage\" FROM customer_groups AS cg CROSS JOIN total_count AS tc GROUP BY cg.\"group\", tc.total ORDER BY \"total_customer\" DESC") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_local081_eq_1_3
