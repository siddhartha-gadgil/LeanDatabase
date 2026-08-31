import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq328_eq_1_2

CREATE TABLE COUNTRY_SUMMARY («country_code» STRING, «short_name» STRING, «table_name» STRING, «long_name» STRING, «two_alpha_code» STRING, «currency_unit» STRING, «special_notes» STRING, «region» STRING, «income_group» STRING, «wb_2_code» STRING, «national_accounts_base_year» STRING, «national_accounts_reference_year» STRING, «sna_price_valuation» STRING, «lending_category» STRING, «other_groups» STRING, «system_of_national_accounts» STRING, «alternative_conversion_factor» STRING, «ppp_survey_year» STRING, «balance_of_payments_manual_in_use» STRING, «external_debt_reporting_status» STRING, «system_of_trade» STRING, «government_accounting_concept» STRING, «imf_data_dissemination_standard» STRING, «latest_population_census» STRING, «latest_household_survey» STRING, «source_of_most_recent_income_and_expenditure_data» STRING, «vital_registration_complete» STRING, «latest_agricultural_census» STRING, «latest_industrial_data» INT, «latest_trade_data» INT)
CREATE TABLE INDICATORS_DATA («country_name» STRING, «country_code» STRING, «indicator_name» STRING, «indicator_code» STRING, «value» FLOAT, «year» INT)

theorem eq (t0 : TableRel COUNTRY_SUMMARY_schema) (t1 : TableRel INDICATORS_DATA_schema) :
    (sql%([COUNTRY_SUMMARY_schema, INDICATORS_DATA_schema]) "SELECT cs.\"region\" AS \"region\" FROM \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"INDICATORS_DATA\" AS id JOIN \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"COUNTRY_SUMMARY\" AS cs ON id.\"country_code\" = cs.\"country_code\" WHERE id.\"indicator_name\" = 'GDP (constant 2015 US$)' AND NOT cs.\"region\" IS NULL AND cs.\"region\" <> '' GROUP BY cs.\"region\" ORDER BY PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY id.\"value\") DESC LIMIT 1") t0 t1
  = (sql%([COUNTRY_SUMMARY_schema, INDICATORS_DATA_schema]) "SELECT cs.\"region\" FROM \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"INDICATORS_DATA\" AS id JOIN \"WORLD_BANK\".\"WORLD_BANK_WDI\".\"COUNTRY_SUMMARY\" AS cs ON id.\"country_code\" = cs.\"country_code\" WHERE id.\"indicator_code\" = 'NY.GDP.MKTP.KD' AND NOT id.\"value\" IS NULL AND NOT cs.\"region\" IS NULL AND cs.\"region\" <> '' GROUP BY cs.\"region\" ORDER BY PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY id.\"value\") DESC LIMIT 1") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq328_eq_1_2
