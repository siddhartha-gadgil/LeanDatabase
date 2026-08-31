import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local197_eq_1_2

CREATE TABLE PAYMENT («payment_id» INT, «customer_id» INT, «staff_id» INT, «rental_id» FLOAT, «amount» FLOAT, «payment_date» STRING, «last_update» STRING)

theorem eq (t0 : TableRel PAYMENT_schema) :
    (sql%([PAYMENT_schema]) "WITH top10 AS (SELECT \"customer_id\" FROM \"SQLITE_SAKILA\".\"SQLITE_SAKILA\".\"PAYMENT\" GROUP BY \"customer_id\" ORDER BY SUM(\"amount\") DESC LIMIT 10), monthly AS (SELECT p.\"customer_id\", SUBSTRING(p.\"payment_date\" FROM 6 FOR 2) AS month, SUM(p.\"amount\") AS monthly_amount FROM \"SQLITE_SAKILA\".\"SQLITE_SAKILA\".\"PAYMENT\" AS p JOIN top10 AS t ON p.\"customer_id\" = t.\"customer_id\" GROUP BY p.\"customer_id\", SUBSTRING(p.\"payment_date\" FROM 6 FOR 2)), with_lag AS (SELECT *, LAG(monthly_amount) OVER (PARTITION BY \"customer_id\" ORDER BY month) AS prev_amount FROM monthly) SELECT month, ROUND(MAX(ABS(monthly_amount - prev_amount)), 2) AS max_diff FROM with_lag WHERE NOT prev_amount IS NULL GROUP BY month ORDER BY max_diff DESC LIMIT 1") t0
  = (sql%([PAYMENT_schema]) "WITH top_customers AS (SELECT \"customer_id\" FROM \"SQLITE_SAKILA\".\"SQLITE_SAKILA\".\"PAYMENT\" GROUP BY \"customer_id\" ORDER BY SUM(\"amount\") DESC LIMIT 10), monthly_payments AS (SELECT p.\"customer_id\", LPAD(CAST(EXTRACT(MONTH FROM TO_TIMESTAMP(p.\"payment_date\")) AS INT), 2, '0') AS pay_month, SUM(p.\"amount\") AS monthly_total FROM \"SQLITE_SAKILA\".\"SQLITE_SAKILA\".\"PAYMENT\" AS p JOIN top_customers AS tc ON p.\"customer_id\" = tc.\"customer_id\" GROUP BY p.\"customer_id\", pay_month), with_lag AS (SELECT \"customer_id\", pay_month, monthly_total, LAG(monthly_total) OVER (PARTITION BY \"customer_id\" ORDER BY pay_month) AS prev_monthly_total FROM monthly_payments), diffs AS (SELECT pay_month, monthly_total - prev_monthly_total AS diff FROM with_lag WHERE NOT prev_monthly_total IS NULL) SELECT pay_month AS \"month\", ROUND(MAX(diff), 2) AS \"max_diff\" FROM diffs GROUP BY pay_month ORDER BY \"max_diff\" DESC LIMIT 1") t0
  := by first | sql_equiv | sorry

end N_sf_local197_eq_1_2
