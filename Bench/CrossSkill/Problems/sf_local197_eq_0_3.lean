import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local197_eq_0_3

CREATE TABLE PAYMENT («payment_id» INT, «customer_id» INT, «staff_id» INT, «rental_id» FLOAT, «amount» FLOAT, «payment_date» STRING, «last_update» STRING)

theorem eq (t0 : TableRel PAYMENT_schema) :
    (sql%([PAYMENT_schema]) "WITH top10_customers AS (SELECT \"customer_id\" FROM \"SQLITE_SAKILA\".\"SQLITE_SAKILA\".\"PAYMENT\" GROUP BY \"customer_id\" ORDER BY SUM(\"amount\") DESC LIMIT 10), monthly_payments AS (SELECT p.\"customer_id\", DATE_TRUNC('MONTH', TRY_TO_TIMESTAMP(p.\"payment_date\")) AS payment_month, SUM(p.\"amount\") AS monthly_total FROM \"SQLITE_SAKILA\".\"SQLITE_SAKILA\".\"PAYMENT\" AS p JOIN top10_customers AS t ON p.\"customer_id\" = t.\"customer_id\" GROUP BY p.\"customer_id\", payment_month), with_diff AS (SELECT \"customer_id\", payment_month, monthly_total, monthly_total - LAG(monthly_total) OVER (PARTITION BY \"customer_id\" ORDER BY payment_month) AS diff FROM monthly_payments) SELECT TO_CHAR(payment_month, 'MM') AS month, ROUND(ABS(diff), 2) AS max_diff FROM with_diff WHERE NOT diff IS NULL ORDER BY ABS(diff) DESC LIMIT 1") t0
  ~= (sql%([PAYMENT_schema]) "WITH top10 AS (SELECT \"customer_id\", SUM(\"amount\") AS total FROM \"SQLITE_SAKILA\".\"SQLITE_SAKILA\".\"PAYMENT\" GROUP BY \"customer_id\" ORDER BY total DESC LIMIT 10), monthly AS (SELECT p.\"customer_id\", SUBSTRING(CAST(p.\"payment_date\" AS VARCHAR) FROM 6 FOR 2) AS month, SUM(p.\"amount\") AS monthly_total FROM \"SQLITE_SAKILA\".\"SQLITE_SAKILA\".\"PAYMENT\" AS p JOIN top10 AS t ON p.\"customer_id\" = t.\"customer_id\" GROUP BY p.\"customer_id\", SUBSTRING(CAST(p.\"payment_date\" AS VARCHAR) FROM 6 FOR 2)), diffs AS (SELECT \"customer_id\", month, monthly_total, monthly_total - LAG(monthly_total) OVER (PARTITION BY \"customer_id\" ORDER BY month) AS diff FROM monthly) SELECT month, ROUND(MAX(ABS(diff)), 2) AS max_diff FROM diffs WHERE NOT diff IS NULL GROUP BY month ORDER BY max_diff DESC LIMIT 1") t0
  := by first | sql_equiv | sorry

end N_sf_local197_eq_0_3
