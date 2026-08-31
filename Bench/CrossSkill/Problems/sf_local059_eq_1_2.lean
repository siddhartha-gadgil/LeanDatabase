import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local059_eq_1_2

CREATE TABLE HARDWARE_DIM_PRODUCT («product_code» STRING, «division» STRING, «segment» STRING, «category» STRING, «product» STRING, «variant» STRING)
CREATE TABLE HARDWARE_FACT_SALES_MONTHLY («date» STRING, «product_code» STRING, «customer_code» INT, «sold_quantity» INT, «fiscal_year» INT)

theorem eq (t0 : TableRel HARDWARE_DIM_PRODUCT_schema) (t1 : TableRel HARDWARE_FACT_SALES_MONTHLY_schema) :
    (sql%([HARDWARE_DIM_PRODUCT_schema, HARDWARE_FACT_SALES_MONTHLY_schema]) "WITH product_sales AS (SELECT p.\"division\", p.\"product_code\", SUM(s.\"sold_quantity\") AS total_qty FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"HARDWARE_FACT_SALES_MONTHLY\" AS s JOIN \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"HARDWARE_DIM_PRODUCT\" AS p ON s.\"product_code\" = p.\"product_code\" WHERE LEFT(s.\"date\", 4) = '2021' GROUP BY p.\"division\", p.\"product_code\"), ranked AS (SELECT \"division\", \"product_code\", total_qty, ROW_NUMBER() OVER (PARTITION BY \"division\" ORDER BY total_qty DESC) AS rn FROM product_sales) SELECT \"division\", AVG(total_qty) AS AVG_TOP3_SOLD_QUANTITY FROM ranked WHERE rn <= 3 GROUP BY \"division\" ORDER BY \"division\"") t0 t1
  ~= (sql%([HARDWARE_DIM_PRODUCT_schema, HARDWARE_FACT_SALES_MONTHLY_schema]) "WITH product_sales AS (SELECT p.\"division\", s.\"product_code\", SUM(s.\"sold_quantity\") AS total_sold_quantity FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"HARDWARE_FACT_SALES_MONTHLY\" AS s JOIN \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"HARDWARE_DIM_PRODUCT\" AS p ON s.\"product_code\" = p.\"product_code\" WHERE EXTRACT(YEAR FROM CAST(TO_TIMESTAMP(s.\"date\", 'YYYY-MM-DD') AS DATE)) = 2021 GROUP BY p.\"division\", s.\"product_code\"), ranked AS (SELECT \"division\", \"product_code\", total_sold_quantity, ROW_NUMBER() OVER (PARTITION BY \"division\" ORDER BY total_sold_quantity DESC) AS rn FROM product_sales) SELECT \"division\" AS \"DIVISION\", AVG(total_sold_quantity) AS \"AVG_TOP3_SOLD_QUANTITY\" FROM ranked WHERE rn <= 3 GROUP BY \"division\" ORDER BY \"division\"") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local059_eq_1_2
