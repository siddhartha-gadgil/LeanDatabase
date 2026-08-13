import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq074 — a proven cross-skill equivalence

Question: Count the number of counties that experienced an increase in unemployment from 2015 to 2018, using 5-year ACS data, and a decrease in dual-eligible enrollee counts between December 1, 2015, and December 1, 2018.

Two independently-written SQL answers to the same question, proved equivalent for *all*
table contents by `sql_equiv` (not just on one instance).
-/

namespace P_sf_bq074

CREATE TABLE COUNTY_2015_5YR («geo_id» STRING, «unemployed_pop» FLOAT)
CREATE TABLE COUNTY_2018_5YR («geo_id» STRING, «unemployed_pop» FLOAT)
CREATE TABLE FIPS («Year» STRING, «GeoFIPS» STRING, «GeoName» STRING, «Employer_contrib_pension_and_insurance» INT, «Employer_contrib_govt_and_social_insurance» INT, «Farm_proprietors_income» INT, «Nonfarm_proprietors_income» INT, «Farm_proprietors_employment» INT, «Income_maintenance_benefits» INT, «Nonfarm_proprietors_employment» INT, «Percapita_income_maintenance_benefits» INT, «Percapita_retirement_and_other» INT, «Percapita_unemployment_insurance_compensation» INT, «Proprietors_income» INT, «Retirement_and_other» INT, «Wages_and_salaries_supplement» INT, «Unemployment_insurance» INT, «Wages_and_salaries» INT, «Nonfarm_proprietors_income_avg» INT, «Wages_and_salaries_avg» INT, «Dividends_interest_rent» INT, «Earnings_by_place_of_work» INT, «Net_earnings_by_place_of_residence» INT, «Percapita_dividends_interest_rent» INT, «Percapita_net_earnings» INT, «Percapita_personal_current_transfer_receipts» INT, «Percapita_personal_income» INT, «Personal_current_transfer_receipts» INT, «Population» INT, «Proprietors_employment» INT, «Wage_and_salary_employment» INT, «Earnings_per_job_avg» INT, «Personal_income» INT, «Total_employment» INT)
CREATE TABLE DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM («Public_Total» INT, «Date» STRING, «FIPS» STRING)

/-- Variant A:  SELECT COUNT(*) AS OUTPUT FROM "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2015_5YR" a15 JOIN "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2018_5YR" a18 ON a15."geo_id" = a18."geo
    Variant B:  SELECT COUNT(*) AS OUTPUT FROM "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2015_5YR" acs15 JOIN "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2018_5YR" acs18 ON acs15."geo_id" = ac -/
theorem equivalent :
    sql%([COUNTY_2015_5YR_schema, COUNTY_2018_5YR_schema, FIPS_schema, DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM_schema]) "SELECT COUNT(*) AS OUTPUT\nFROM \"SDOH\".\"CENSUS_BUREAU_ACS\".\"COUNTY_2015_5YR\" a15\nJOIN \"SDOH\".\"CENSUS_BUREAU_ACS\".\"COUNTY_2018_5YR\" a18\n  ON a15.\"geo_id\" = a18.\"geo_id\"\nJOIN \"SDOH\".\"SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT\".\"DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM\" d15\n  ON a15.\"geo_id\" = d15.\"FIPS\" AND d15.\"Date\" = '2015-12-01'\nJOIN \"SDOH\".\"SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT\".\"DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM\" d18\n  ON a15.\"geo_id\" = d18.\"FIPS\" AND d18.\"Date\" = '2018-12-01'\nWHERE a18.\"unemployed_pop\" > a15.\"unemployed_pop\"\n  AND d18.\"Public_Total\" < d15.\"Public_Total\";"
      = sql%([COUNTY_2015_5YR_schema, COUNTY_2018_5YR_schema, FIPS_schema, DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM_schema]) "SELECT COUNT(*) AS OUTPUT\nFROM \"SDOH\".\"CENSUS_BUREAU_ACS\".\"COUNTY_2015_5YR\" acs15\nJOIN \"SDOH\".\"CENSUS_BUREAU_ACS\".\"COUNTY_2018_5YR\" acs18\n  ON acs15.\"geo_id\" = acs18.\"geo_id\"\nJOIN \"SDOH\".\"SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT\".\"DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM\" d15\n  ON acs15.\"geo_id\" = d15.\"FIPS\"\n  AND d15.\"Date\" = '2015-12-01'\nJOIN \"SDOH\".\"SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT\".\"DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM\" d18\n  ON acs15.\"geo_id\" = d18.\"FIPS\"\n  AND d18.\"Date\" = '2018-12-01'\nWHERE acs18.\"unemployed_pop\" > acs15.\"unemployed_pop\"\n  AND d18.\"Public_Total\" < d15.\"Public_Total\";" := by sql_equiv

end P_sf_bq074
