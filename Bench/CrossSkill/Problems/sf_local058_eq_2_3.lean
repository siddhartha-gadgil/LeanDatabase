import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local058_eq_2_3

CREATE TABLE HARDWARE_DIM_PRODUCT («product_code» STRING, «division» STRING, «segment» STRING, «category» STRING, «product» STRING, «variant» STRING)
CREATE TABLE HARDWARE_FACT_SALES_MONTHLY («date» STRING, «product_code» STRING, «customer_code» INT, «sold_quantity» INT, «fiscal_year» INT)

theorem eq (t0 : TableRel HARDWARE_DIM_PRODUCT_schema) (t1 : TableRel HARDWARE_FACT_SALES_MONTHLY_schema) :
    (sql%([HARDWARE_DIM_PRODUCT_schema, HARDWARE_FACT_SALES_MONTHLY_schema]) "WITH product_counts AS (SELECT p.\"segment\", f.\"fiscal_year\", COUNT(DISTINCT f.\"product_code\") AS product_count FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"HARDWARE_FACT_SALES_MONTHLY\" AS f JOIN \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"HARDWARE_DIM_PRODUCT\" AS p ON f.\"product_code\" = p.\"product_code\" WHERE f.\"fiscal_year\" IN (2020, 2021) GROUP BY p.\"segment\", f.\"fiscal_year\"), pivoted AS (SELECT \"segment\", MAX(CASE WHEN \"fiscal_year\" = 2020 THEN product_count END) AS product_count_2020, MAX(CASE WHEN \"fiscal_year\" = 2021 THEN product_count END) AS product_count_2021 FROM product_counts GROUP BY \"segment\") SELECT \"segment\", product_count_2020 AS \"PRODUCT_COUNT_2020\" FROM pivoted ORDER BY (CAST((product_count_2021 - product_count_2020) * 100.0 AS DOUBLE PRECISION) / product_count_2020) DESC") t0 t1
  ~= (sql%([HARDWARE_DIM_PRODUCT_schema, HARDWARE_FACT_SALES_MONTHLY_schema]) "WITH product_counts AS (SELECT p.\"segment\", COUNT(DISTINCT CASE WHEN f.\"fiscal_year\" = 2020 THEN f.\"product_code\" END) AS unique_products_2020, COUNT(DISTINCT CASE WHEN f.\"fiscal_year\" = 2021 THEN f.\"product_code\" END) AS unique_products_2021 FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"HARDWARE_FACT_SALES_MONTHLY\" AS f JOIN \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"HARDWARE_DIM_PRODUCT\" AS p ON f.\"product_code\" = p.\"product_code\" WHERE f.\"fiscal_year\" IN (2020, 2021) GROUP BY p.\"segment\") SELECT \"segment\", unique_products_2020 FROM product_counts ORDER BY (CAST((unique_products_2021 - unique_products_2020) * 100.0 AS DOUBLE PRECISION) / unique_products_2020) DESC") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local058_eq_2_3
