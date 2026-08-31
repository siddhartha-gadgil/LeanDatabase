import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local074_eq_2_3

CREATE TABLE CUSTOMER_TRANSACTIONS («customer_id» INT, «txn_date» STRING, «txn_type» STRING, «txn_amount» INT)

theorem eq (t0 : TableRel CUSTOMER_TRANSACTIONS_schema) :
    (sql%([CUSTOMER_TRANSACTIONS_schema]) "WITH months AS (SELECT DATE_TRUNC('MONTH', CAST(\"txn_date\" AS DATE)) AS month_start FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"CUSTOMER_TRANSACTIONS\" GROUP BY 1), customers AS (SELECT DISTINCT \"customer_id\" FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"CUSTOMER_TRANSACTIONS\"), customer_months AS (SELECT c.\"customer_id\", m.month_start FROM customers AS c CROSS JOIN months AS m), monthly_activity AS (SELECT \"customer_id\", DATE_TRUNC('MONTH', CAST(\"txn_date\" AS DATE)) AS month_start, SUM(CASE WHEN \"txn_type\" = 'deposit' THEN \"txn_amount\" ELSE -\"txn_amount\" END) AS balance_activity FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"CUSTOMER_TRANSACTIONS\" GROUP BY 1, 2), combined AS (SELECT cm.\"customer_id\", cm.month_start, COALESCE(ma.balance_activity, 0) AS balance_activity FROM customer_months AS cm LEFT JOIN monthly_activity AS ma ON cm.\"customer_id\" = ma.\"customer_id\" AND cm.month_start = ma.month_start) SELECT \"customer_id\", month_start AS \"GENERATED_MONTH\", balance_activity AS \"BALANCE_ACTIVITY\", SUM(balance_activity) OVER (PARTITION BY \"customer_id\" ORDER BY month_start ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS \"MONTH_END_BALANCE\" FROM combined ORDER BY \"customer_id\", month_start") t0
  ~= (sql%([CUSTOMER_TRANSACTIONS_schema]) "WITH months AS (SELECT CAST('2020-01-01' AS DATE) AS generated_month UNION ALL SELECT CAST('2020-02-01' AS DATE) UNION ALL SELECT CAST('2020-03-01' AS DATE) UNION ALL SELECT CAST('2020-04-01' AS DATE)), customers AS (SELECT DISTINCT \"customer_id\" FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"CUSTOMER_TRANSACTIONS\"), customer_months AS (SELECT c.\"customer_id\", m.generated_month FROM customers AS c CROSS JOIN months AS m), monthly_activity AS (SELECT \"customer_id\", CAST(DATE_TRUNC('MONTH', CAST(\"txn_date\" AS DATE)) AS DATE) AS txn_month, SUM(CASE WHEN \"txn_type\" = 'deposit' THEN \"txn_amount\" ELSE -\"txn_amount\" END) AS balance_activity FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"CUSTOMER_TRANSACTIONS\" GROUP BY \"customer_id\", CAST(DATE_TRUNC('MONTH', CAST(\"txn_date\" AS DATE)) AS DATE)) SELECT cm.\"customer_id\", cm.generated_month AS GENERATED_MONTH, COALESCE(ma.balance_activity, 0) AS BALANCE_ACTIVITY, SUM(COALESCE(ma.balance_activity, 0)) OVER (PARTITION BY cm.\"customer_id\" ORDER BY cm.generated_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS MONTH_END_BALANCE FROM customer_months AS cm LEFT JOIN monthly_activity AS ma ON cm.\"customer_id\" = ma.\"customer_id\" AND cm.generated_month = ma.txn_month ORDER BY cm.\"customer_id\", cm.generated_month") t0
  := by first | sql_equiv | sorry

end N_sf_local074_eq_2_3
