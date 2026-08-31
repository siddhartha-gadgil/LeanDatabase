import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq172_eq_1_3

CREATE TABLE PART_D_PRESCRIBER_2014 («npi» STRING, «nppes_provider_last_org_name» STRING, «nppes_provider_first_name» STRING, «nppes_provider_city» STRING, «nppes_provider_state» STRING, «specialty_description» STRING, «description_flag» STRING, «drug_name» STRING, «generic_name» STRING, «bene_count» INT, «total_claim_count» INT, «total_day_supply» INT, «total_drug_cost» FLOAT, «bene_count_ge65» INT, «bene_count_ge65_suppress_flag» STRING, «total_claim_count_ge65» INT, «ge65_suppress_flag» STRING, «total_day_supply_ge65» INT, «total_drug_cost_ge65» FLOAT, «total_30_day_fill_count» FLOAT, «total_30_day_fill_count_ge65» FLOAT)

theorem eq (t0 : TableRel PART_D_PRESCRIBER_2014_schema) :
    (sql%([PART_D_PRESCRIBER_2014_schema]) "/* Step 1: Find the drug with the highest total prescriptions in NY */ /* Step 2: For that drug, find top 5 states by total claim count */ WITH ny_top_drug AS (SELECT \"drug_name\" FROM \"CMS_DATA\".\"CMS_MEDICARE\".\"PART_D_PRESCRIBER_2014\" WHERE \"nppes_provider_state\" = 'NY' GROUP BY \"drug_name\" ORDER BY SUM(\"total_claim_count\") DESC LIMIT 1) SELECT \"nppes_provider_state\" AS STATE, SUM(\"total_claim_count\") AS TOTAL_CLAIM_COUNT, SUM(\"total_drug_cost\") AS TOTAL_DRUG_COST FROM \"CMS_DATA\".\"CMS_MEDICARE\".\"PART_D_PRESCRIBER_2014\" AS p JOIN ny_top_drug AS t ON p.\"drug_name\" = t.\"drug_name\" GROUP BY \"nppes_provider_state\" ORDER BY TOTAL_CLAIM_COUNT DESC LIMIT 5") t0
  = (sql%([PART_D_PRESCRIBER_2014_schema]) "WITH top_drug_in_ny AS (SELECT \"drug_name\" FROM \"CMS_DATA\".\"CMS_MEDICARE\".\"PART_D_PRESCRIBER_2014\" WHERE \"nppes_provider_state\" = 'NY' GROUP BY \"drug_name\" ORDER BY SUM(\"total_claim_count\") DESC LIMIT 1) SELECT \"nppes_provider_state\" AS STATE, SUM(\"total_claim_count\") AS TOTAL_CLAIM_COUNT, SUM(\"total_drug_cost\") AS TOTAL_DRUG_COST FROM \"CMS_DATA\".\"CMS_MEDICARE\".\"PART_D_PRESCRIBER_2014\" WHERE \"drug_name\" = (SELECT \"drug_name\" FROM top_drug_in_ny) GROUP BY \"nppes_provider_state\" ORDER BY TOTAL_CLAIM_COUNT DESC LIMIT 5") t0
  := by first | sql_equiv | sorry

end N_sf_bq172_eq_1_3
