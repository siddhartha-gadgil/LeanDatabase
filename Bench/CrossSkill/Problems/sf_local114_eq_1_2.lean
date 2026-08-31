import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local114_eq_1_2

CREATE TABLE WEB_ORDERS («id» INT, «account_id» INT, «occurred_at» STRING, «standard_qty» INT, «gloss_qty» INT, «poster_qty» INT, «total» INT, «standard_amt_usd» FLOAT, «gloss_amt_usd» FLOAT, «poster_amt_usd» FLOAT, «total_amt_usd» FLOAT)
CREATE TABLE WEB_SALES_REPS («id» INT, «name» STRING, «region_id» INT)
CREATE TABLE WEB_ACCOUNTS («id» INT, «name» STRING, «website» STRING, «lat» FLOAT, «long» FLOAT, «primary_poc» STRING, «sales_rep_id» INT)
CREATE TABLE WEB_REGION («id» INT, «name» STRING)

theorem eq (t0 : TableRel WEB_ORDERS_schema) (t1 : TableRel WEB_SALES_REPS_schema) (t2 : TableRel WEB_ACCOUNTS_schema) (t3 : TableRel WEB_REGION_schema) :
    (sql%([WEB_ORDERS_schema, WEB_SALES_REPS_schema, WEB_ACCOUNTS_schema, WEB_REGION_schema]) "WITH rep_sales AS (SELECT r.\"name\" AS region_name, sr.\"name\" AS rep_name, COUNT(o.\"id\") AS num_orders, COALESCE(SUM(o.\"total_amt_usd\"), 0) AS total_sales FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"WEB_REGION\" AS r JOIN \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"WEB_SALES_REPS\" AS sr ON sr.\"region_id\" = r.\"id\" JOIN \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"WEB_ACCOUNTS\" AS a ON a.\"sales_rep_id\" = sr.\"id\" JOIN \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"WEB_ORDERS\" AS o ON o.\"account_id\" = a.\"id\" GROUP BY r.\"name\", sr.\"name\"), region_totals AS (SELECT region_name, SUM(num_orders) AS region_orders, SUM(total_sales) AS region_total_sales FROM rep_sales GROUP BY region_name), ranked_reps AS (SELECT region_name, rep_name, total_sales AS rep_total_sales, RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS rnk FROM rep_sales) SELECT rt.region_name, rt.region_orders, rt.region_total_sales, rr.rep_name AS top_rep_name, rr.rep_total_sales AS top_rep_total_sales FROM region_totals AS rt JOIN ranked_reps AS rr ON rt.region_name = rr.region_name AND rr.rnk = 1 ORDER BY rt.region_name, rr.rep_name") t0 t1 t2 t3
  ~= (sql%([WEB_ORDERS_schema, WEB_SALES_REPS_schema, WEB_ACCOUNTS_schema, WEB_REGION_schema]) "WITH region_orders AS (SELECT r.\"name\" AS REGION_NAME, COUNT(o.\"id\") AS TOTAL_REGION_ORDERS, SUM(o.\"total_amt_usd\") AS TOTAL_REGION_SALES FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"WEB_REGION\" AS r JOIN \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"WEB_SALES_REPS\" AS sr ON sr.\"region_id\" = r.\"id\" JOIN \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"WEB_ACCOUNTS\" AS a ON a.\"sales_rep_id\" = sr.\"id\" JOIN \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"WEB_ORDERS\" AS o ON o.\"account_id\" = a.\"id\" GROUP BY r.\"name\"), rep_sales AS (SELECT r.\"name\" AS REGION_NAME, sr.\"name\" AS SALES_REP_NAME, SUM(o.\"total_amt_usd\") AS REP_SALES FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"WEB_REGION\" AS r JOIN \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"WEB_SALES_REPS\" AS sr ON sr.\"region_id\" = r.\"id\" JOIN \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"WEB_ACCOUNTS\" AS a ON a.\"sales_rep_id\" = sr.\"id\" JOIN \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"WEB_ORDERS\" AS o ON o.\"account_id\" = a.\"id\" GROUP BY r.\"name\", sr.\"name\"), top_rep AS (SELECT REGION_NAME, SALES_REP_NAME AS TOP_SALES_REP_NAME, REP_SALES AS TOP_SALES_REP_SALES, ROW_NUMBER() OVER (PARTITION BY REGION_NAME ORDER BY REP_SALES DESC) AS rn FROM rep_sales) SELECT ro.REGION_NAME, ro.TOTAL_REGION_ORDERS, ro.TOTAL_REGION_SALES, tr.TOP_SALES_REP_NAME, tr.TOP_SALES_REP_SALES FROM region_orders AS ro JOIN top_rep AS tr ON ro.REGION_NAME = tr.REGION_NAME AND tr.rn = 1 ORDER BY ro.REGION_NAME") t0 t1 t2 t3
  := by first | sql_equiv | sorry

end N_sf_local114_eq_1_2
