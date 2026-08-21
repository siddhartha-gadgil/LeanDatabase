import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq328 — crossskill equivalence(s)

Question: Which region has the highest median GDP (constant 2015 US$) value?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq328

CREATE TABLE COUNTRY_SUMMARY («country_code» STRING, «short_name» STRING, «table_name» STRING, «long_name» STRING, «two_alpha_code» STRING, «currency_unit» STRING, «special_notes» STRING, «region» STRING, «income_group» STRING, «wb_2_code» STRING, «national_accounts_base_year» STRING, «national_accounts_reference_year» STRING, «sna_price_valuation» STRING, «lending_category» STRING, «other_groups» STRING, «system_of_national_accounts» STRING, «alternative_conversion_factor» STRING, «ppp_survey_year» STRING, «balance_of_payments_manual_in_use» STRING, «external_debt_reporting_status» STRING, «system_of_trade» STRING, «government_accounting_concept» STRING, «imf_data_dissemination_standard» STRING, «latest_population_census» STRING, «latest_household_survey» STRING, «source_of_most_recent_income_and_expenditure_data» STRING, «vital_registration_complete» STRING, «latest_agricultural_census» STRING, «latest_industrial_data» INT, «latest_trade_data» INT)
CREATE TABLE INDICATORS_DATA («country_name» STRING, «country_code» STRING, «indicator_name» STRING, «indicator_code» STRING, «value» FLOAT, «year» INT)

-- eq_0_1: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_1 :
    sql%([COUNTRY_SUMMARY_schema, INDICATORS_DATA_schema]) "SELECT c.\"region\"\nFROM \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"INDICATORS_DATA\" i\nJOIN \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"COUNTRY_SUMMARY\" c\n  ON i.\"country_code\" = c.\"country_code\"\nWHERE i.\"indicator_code\" = 'NY.GDP.MKTP.KD'\n  AND c.\"region\" IS NOT NULL AND c.\"region\" != ''\nGROUP BY c.\"region\"\nORDER BY MEDIAN(i.\"value\") DESC\nLIMIT 1;" = sql%([COUNTRY_SUMMARY_schema, INDICATORS_DATA_schema]) "SELECT cs.\"region\" AS \"region\"\nFROM \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"INDICATORS_DATA\" id\nJOIN \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"COUNTRY_SUMMARY\" cs\n  ON id.\"country_code\" = cs.\"country_code\"\nWHERE id.\"indicator_name\" = 'GDP (constant 2015 US$)'\n  AND cs.\"region\" IS NOT NULL\n  AND cs.\"region\" != ''\nGROUP BY cs.\"region\"\nORDER BY MEDIAN(id.\"value\") DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

-- eq_0_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_2 :
    sql%([COUNTRY_SUMMARY_schema, INDICATORS_DATA_schema]) "SELECT c.\"region\"\nFROM \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"INDICATORS_DATA\" i\nJOIN \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"COUNTRY_SUMMARY\" c\n  ON i.\"country_code\" = c.\"country_code\"\nWHERE i.\"indicator_code\" = 'NY.GDP.MKTP.KD'\n  AND c.\"region\" IS NOT NULL AND c.\"region\" != ''\nGROUP BY c.\"region\"\nORDER BY MEDIAN(i.\"value\") DESC\nLIMIT 1;" = sql%([COUNTRY_SUMMARY_schema, INDICATORS_DATA_schema]) "SELECT\n    cs.\"region\"\nFROM \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"INDICATORS_DATA\" id\nJOIN \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"COUNTRY_SUMMARY\" cs\n    ON id.\"country_code\" = cs.\"country_code\"\nWHERE id.\"indicator_code\" = 'NY.GDP.MKTP.KD'\n  AND id.\"value\" IS NOT NULL\n  AND cs.\"region\" IS NOT NULL\n  AND cs.\"region\" != ''\nGROUP BY cs.\"region\"\nORDER BY MEDIAN(id.\"value\") DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([COUNTRY_SUMMARY_schema, INDICATORS_DATA_schema]) "SELECT cs.\"region\" AS \"region\"\nFROM \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"INDICATORS_DATA\" id\nJOIN \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"COUNTRY_SUMMARY\" cs\n  ON id.\"country_code\" = cs.\"country_code\"\nWHERE id.\"indicator_name\" = 'GDP (constant 2015 US$)'\n  AND cs.\"region\" IS NOT NULL\n  AND cs.\"region\" != ''\nGROUP BY cs.\"region\"\nORDER BY MEDIAN(id.\"value\") DESC\nLIMIT 1;" = sql%([COUNTRY_SUMMARY_schema, INDICATORS_DATA_schema]) "SELECT\n    cs.\"region\"\nFROM \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"INDICATORS_DATA\" id\nJOIN \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"COUNTRY_SUMMARY\" cs\n    ON id.\"country_code\" = cs.\"country_code\"\nWHERE id.\"indicator_code\" = 'NY.GDP.MKTP.KD'\n  AND id.\"value\" IS NOT NULL\n  AND cs.\"region\" IS NOT NULL\n  AND cs.\"region\" != ''\nGROUP BY cs.\"region\"\nORDER BY MEDIAN(id.\"value\") DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

end Bench_sf_bq328
