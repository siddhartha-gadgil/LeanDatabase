import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq218_eq_0_1

CREATE TABLE SALES («invoice_and_item_number» STRING, «date» STRING, «store_number» STRING, «store_name» STRING, «address» STRING, «city» STRING, «zip_code» STRING, «store_location» STRING, «county_number» STRING, «county» STRING, «category» STRING, «category_name» STRING, «vendor_number» STRING, «vendor_name» STRING, «item_number» STRING, «item_description» STRING, «pack» INT, «bottle_volume_ml» INT, «state_bottle_cost» FLOAT, «state_bottle_retail» FLOAT, «bottles_sold» INT, «sale_dollars» FLOAT, «volume_sold_liters» FLOAT, «volume_sold_gallons» FLOAT)

theorem eq (t0 : TableRel SALES_schema) :
    (sql%([SALES_schema]) "WITH yearly_revenue AS (SELECT \"item_number\", \"item_description\", EXTRACT(YEAR FROM \"date\") AS sale_year, SUM(\"sale_dollars\") AS total_revenue FROM \"IOWA_LIQUOR_SALES\".\"IOWA_LIQUOR_SALES\".\"SALES\" WHERE EXTRACT(YEAR FROM \"date\") IN (2022, 2023) GROUP BY \"item_number\", \"item_description\", sale_year), item_revenue AS (SELECT \"item_number\", ANY_VALUE(\"item_description\") AS ITEM_DESCRIPTION, SUM(CASE WHEN sale_year = 2022 THEN total_revenue ELSE 0 END) AS REVENUE_2022, SUM(CASE WHEN sale_year = 2023 THEN total_revenue ELSE 0 END) AS REVENUE_2023 FROM yearly_revenue GROUP BY \"item_number\") SELECT \"item_number\", ITEM_DESCRIPTION, REVENUE_2022, REVENUE_2023, CAST((REVENUE_2023 - REVENUE_2022) AS DOUBLE PRECISION) / REVENUE_2022 * 100 AS YOY_GROWTH_PCT FROM item_revenue WHERE REVENUE_2022 > 0 AND REVENUE_2023 > 0 ORDER BY YOY_GROWTH_PCT DESC LIMIT 5") t0
  ~= (sql%([SALES_schema]) "SELECT \"item_number\", MAX(\"item_description\") AS ITEM_DESCRIPTION, SUM(CASE WHEN EXTRACT(YEAR FROM \"date\") = 2022 THEN \"sale_dollars\" ELSE 0 END) AS REVENUE_2022, SUM(CASE WHEN EXTRACT(YEAR FROM \"date\") = 2023 THEN \"sale_dollars\" ELSE 0 END) AS REVENUE_2023, CAST((SUM(CASE WHEN EXTRACT(YEAR FROM \"date\") = 2023 THEN \"sale_dollars\" ELSE 0 END) - SUM(CASE WHEN EXTRACT(YEAR FROM \"date\") = 2022 THEN \"sale_dollars\" ELSE 0 END)) AS DOUBLE PRECISION) / NULLIF(SUM(CASE WHEN EXTRACT(YEAR FROM \"date\") = 2022 THEN \"sale_dollars\" ELSE 0 END), 0) * 100 AS YOY_GROWTH_PCT FROM \"IOWA_LIQUOR_SALES\".\"IOWA_LIQUOR_SALES\".\"SALES\" WHERE EXTRACT(YEAR FROM \"date\") IN (2022, 2023) GROUP BY \"item_number\" HAVING SUM(CASE WHEN EXTRACT(YEAR FROM \"date\") = 2022 THEN \"sale_dollars\" ELSE 0 END) > 0 AND SUM(CASE WHEN EXTRACT(YEAR FROM \"date\") = 2023 THEN \"sale_dollars\" ELSE 0 END) > 0 ORDER BY YOY_GROWTH_PCT DESC LIMIT 5") t0
  := by first | sql_equiv | sorry

end N_sf_bq218_eq_0_1
