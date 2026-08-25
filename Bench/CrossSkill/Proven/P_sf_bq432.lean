import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq432 — proven cross-skill equivalence(s)

Question: Please provide the food events data where both \"date_created\" and \"date_started\" are between January 1 and January 31, 2015, apply the following data cleansing steps: split reactions and outcomes fields into arrays by commas, handle special numeric patterns in the products_brand_name field (where a digit is followed by comma and another digit) by preserving those numeric patterns while replacing other ", " with " -- ", replace ", " with " -- " in products_industry_code, products_role, and products_industry_name fields, and calculate industry_code_length and brand_name_length as the array lengths after splitting.

Independently-written SQL variants proved equal for all table contents by `sql_equiv`; where
they differ by a `WHERE`/`SELECT` fact, that data assumption is an explicit `HYPOTHESIS` antecedent.
-/

namespace P_sf_bq432

CREATE TABLE FOOD_EVENTS («report_number» STRING, «reactions» STRING, «outcomes» STRING, «products_brand_name» STRING, «products_industry_code» STRING, «products_role» STRING, «products_industry_name» STRING, «date_created» STRING, «date_started» STRING, «consumer_gender» STRING, «consumer_age» FLOAT, «consumer_age_unit» STRING)

HYPOTHESIS hyp2_3_0 : FOOD_EVENTS "\"date_started\" <= '2015-01-31'"

theorem eq_2_3 (t : TableRel FOOD_EVENTS_schema) (h0 : hyp2_3_0 t) :
    (sql%([FOOD_EVENTS_schema]) "SELECT \"report_number\", SPLIT(\"reactions\", ', ') AS \"REACTIONS\", SPLIT(\"outcomes\", ', ') AS \"OUTCOMES\", REPLACE(\"products_brand_name\", ', ', ' -- ') AS \"PRODUCTS_BRAND_NAME\", REPLACE(\"products_industry_code\", ', ', ' -- ') AS \"PRODUCTS_INDUSTRY_CODE\", REPLACE(\"products_role\", ', ', ' -- ') AS \"PRODUCTS_ROLE\", REPLACE(\"products_industry_name\", ', ', ' -- ') AS \"PRODUCTS_INDUSTRY_NAME\", \"date_created\", \"date_started\", \"consumer_gender\", \"consumer_age\", \"consumer_age_unit\", ARRAY_LENGTH(SPLIT(\"products_industry_code\", ', '), 1) AS \"INDUSTRY_CODE_LENGTH\", ARRAY_LENGTH(SPLIT(\"products_brand_name\", ', '), 1) AS \"BRAND_NAME_LENGTH\" FROM \"FDA\".\"FDA_FOOD\".\"FOOD_EVENTS\" WHERE \"date_created\" >= '2015-01-01' AND \"date_created\" <= '2015-01-31' AND \"date_started\" >= '2015-01-01' AND \"date_started\" <= '2015-01-31'") t = (sql%([FOOD_EVENTS_schema]) "SELECT \"report_number\", SPLIT(\"reactions\", ', ') AS \"REACTIONS\", SPLIT(\"outcomes\", ', ') AS \"OUTCOMES\", REPLACE(\"products_brand_name\", ', ', ' -- ') AS \"PRODUCTS_BRAND_NAME\", REPLACE(\"products_industry_code\", ', ', ' -- ') AS \"PRODUCTS_INDUSTRY_CODE\", REPLACE(\"products_role\", ', ', ' -- ') AS \"PRODUCTS_ROLE\", REPLACE(\"products_industry_name\", ', ', ' -- ') AS \"PRODUCTS_INDUSTRY_NAME\", \"date_created\", \"date_started\", \"consumer_gender\", \"consumer_age\", \"consumer_age_unit\", ARRAY_LENGTH(SPLIT(\"products_industry_code\", ', '), 1) AS \"INDUSTRY_CODE_LENGTH\", ARRAY_LENGTH(SPLIT(\"products_brand_name\", ', '), 1) AS \"BRAND_NAME_LENGTH\" FROM \"FDA\".\"FDA_FOOD\".\"FOOD_EVENTS\" WHERE \"date_created\" >= '2015-01-01' AND \"date_created\" <= '2015-01-31' AND \"date_started\" >= '2015-01-01' AND \"date_started\" <= '2015-01-31' ORDER BY \"consumer_age\" ASC NULLS FIRST, \"reactions\" ASC") t := by sql_equiv

end P_sf_bq432
