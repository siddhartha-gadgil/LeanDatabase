import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq399 — crossskill equivalence(s)

Question: Which high-income country had the highest average crude birth rate respectively in each region, and what are their corresponding average birth rate, during the 1980s?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq399

CREATE TABLE COUNTRY_SUMMARY («country_code» STRING, «short_name» STRING, «table_name» STRING, «long_name» STRING, «two_alpha_code» STRING, «currency_unit» STRING, «special_notes» STRING, «region» STRING, «income_group» STRING, «wb_2_code» STRING, «national_accounts_base_year» STRING, «national_accounts_reference_year» STRING, «sna_price_valuation» STRING, «lending_category» STRING, «other_groups» STRING, «system_of_national_accounts» STRING, «alternative_conversion_factor» STRING, «ppp_survey_year» STRING, «balance_of_payments_manual_in_use» STRING, «external_debt_reporting_status» STRING, «system_of_trade» STRING, «government_accounting_concept» STRING, «imf_data_dissemination_standard» STRING, «latest_population_census» STRING, «latest_household_survey» STRING, «source_of_most_recent_income_and_expenditure_data» STRING, «vital_registration_complete» STRING, «latest_agricultural_census» STRING, «latest_industrial_data» INT, «latest_trade_data» INT)
CREATE TABLE INDICATORS_DATA («country_name» STRING, «country_code» STRING, «indicator_name» STRING, «indicator_code» STRING, «value» FLOAT, «year» INT)

-- eq_0_1: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_1 : ∀ t,
    (sql%([COUNTRY_SUMMARY_schema, INDICATORS_DATA_schema]) "WITH country_avg AS (\n  SELECT \n    cs.\"region\" AS region,\n    i.\"country_name\" AS COUNTRY,\n    AVG(i.\"value\") AS AVG_BIRTH_RATE\n  FROM \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"COUNTRY_SUMMARY\" cs\n  JOIN \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"INDICATORS_DATA\" i\n    ON cs.\"country_code\" = i.\"country_code\"\n  WHERE cs.\"income_group\" = 'High income'\n    AND i.\"indicator_code\" = 'SP.DYN.CBRT.IN'\n    AND i.\"year\" BETWEEN 1980 AND 1989\n    AND cs.\"region\" IS NOT NULL \n    AND cs.\"region\" != 'None'\n  GROUP BY cs.\"region\", i.\"country_name\"\n),\nranked AS (\n  SELECT \n    region,\n    COUNTRY,\n    AVG_BIRTH_RATE,\n    ROW_NUMBER() OVER (PARTITION BY region ORDER BY AVG_BIRTH_RATE DESC) AS rn\n  FROM country_avg\n)\nSELECT \n  region,\n  COUNTRY,\n  AVG_BIRTH_RATE\nFROM ranked\nWHERE rn = 1\nORDER BY region;") t ~= (sql%([COUNTRY_SUMMARY_schema, INDICATORS_DATA_schema]) "WITH ranked AS (\n  SELECT \n    c.\"region\" AS region,\n    d.\"country_name\" AS COUNTRY,\n    AVG(d.\"value\") AS AVG_BIRTH_RATE,\n    ROW_NUMBER() OVER (PARTITION BY c.\"region\" ORDER BY AVG(d.\"value\") DESC) AS rn\n  FROM \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"INDICATORS_DATA\" d\n  JOIN \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"COUNTRY_SUMMARY\" c\n    ON d.\"country_code\" = c.\"country_code\"\n  WHERE c.\"income_group\" = 'High income'\n    AND d.\"indicator_code\" = 'SP.DYN.CBRT.IN'\n    AND d.\"year\" BETWEEN 1980 AND 1989\n  GROUP BY c.\"region\", d.\"country_name\"\n)\nSELECT REGION, COUNTRY, AVG_BIRTH_RATE\nFROM ranked\nWHERE rn = 1\nORDER BY REGION;") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq399
