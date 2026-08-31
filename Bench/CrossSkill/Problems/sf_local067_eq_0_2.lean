import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local067_eq_0_2

CREATE TABLE COSTS («prod_id» INT, «time_id» STRING, «promo_id» INT, «channel_id» INT, «unit_cost» FLOAT, «unit_price» FLOAT)
CREATE TABLE CUSTOMERS («cust_id» INT, «cust_first_name» STRING, «cust_last_name» STRING, «cust_gender» STRING, «cust_year_of_birth» INT, «cust_marital_status» STRING, «cust_street_address» STRING, «cust_postal_code» STRING, «cust_city» STRING, «cust_city_id» INT, «cust_state_province» STRING, «cust_state_province_id» INT, «country_id» INT, «cust_main_phone_number» STRING, «cust_income_level» STRING, «cust_credit_limit» FLOAT, «cust_email» STRING, «cust_total» STRING, «cust_total_id» INT, «cust_src_id» STRING, «cust_eff_from» STRING, «cust_eff_to» STRING, «cust_valid» STRING)
CREATE TABLE SALES («prod_id» INT, «cust_id» INT, «time_id» STRING, «channel_id» INT, «promo_id» INT, «quantity_sold» INT, «amount_sold» FLOAT)

theorem eq (t0 : TableRel COSTS_schema) (t1 : TableRel CUSTOMERS_schema) (t2 : TableRel SALES_schema) :
    (sql%([COSTS_schema, CUSTOMERS_schema, SALES_schema]) "WITH customer_profits AS (SELECT cu.\"cust_id\", SUM(s.\"amount_sold\" - c.\"unit_cost\" * s.\"quantity_sold\") AS total_profit FROM \"COMPLEX_ORACLE\".\"COMPLEX_ORACLE\".\"SALES\" AS s JOIN \"COMPLEX_ORACLE\".\"COMPLEX_ORACLE\".\"COSTS\" AS c ON s.\"prod_id\" = c.\"prod_id\" AND s.\"time_id\" = c.\"time_id\" AND s.\"channel_id\" = c.\"channel_id\" AND s.\"promo_id\" = c.\"promo_id\" JOIN \"COMPLEX_ORACLE\".\"COMPLEX_ORACLE\".\"CUSTOMERS\" AS cu ON s.\"cust_id\" = cu.\"cust_id\" WHERE cu.\"country_id\" = 52770 AND s.\"time_id\" >= '2021-12-01' AND s.\"time_id\" < '2022-01-01' GROUP BY cu.\"cust_id\"), tiered AS (SELECT total_profit, NTILE(10) OVER (ORDER BY total_profit DESC) AS BUCKET FROM customer_profits) SELECT BUCKET, MAX(total_profit) AS MAX_PROFIT, MIN(total_profit) AS MIN_PROFIT FROM tiered GROUP BY BUCKET ORDER BY BUCKET") t0 t1 t2
  ~= (sql%([COSTS_schema, CUSTOMERS_schema, SALES_schema]) "WITH customer_profits AS (SELECT s.\"cust_id\", SUM(s.\"amount_sold\" - c.\"unit_cost\") AS profit FROM COMPLEX_ORACLE.COMPLEX_ORACLE.SALES AS s JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.COSTS AS c ON s.\"prod_id\" = c.\"prod_id\" AND s.\"time_id\" = c.\"time_id\" AND s.\"channel_id\" = c.\"channel_id\" AND s.\"promo_id\" = c.\"promo_id\" JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS AS cu ON s.\"cust_id\" = cu.\"cust_id\" JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES AS co ON cu.\"country_id\" = co.\"country_id\" JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES AS t ON s.\"time_id\" = t.\"time_id\" WHERE co.\"country_name\" = 'Italy' AND t.\"calendar_month_desc\" = '2021-12' GROUP BY s.\"cust_id\"), tiered AS (SELECT profit, NTILE(10) OVER (ORDER BY profit DESC) AS bucket FROM customer_profits) SELECT bucket AS \"BUCKET\", MAX(profit) AS \"MAX_PROFIT\", MIN(profit) AS \"MIN_PROFIT\" FROM tiered GROUP BY bucket ORDER BY bucket") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_local067_eq_0_2
