import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq288 — crossskill equivalence(s)

Question: What is the total number of all banking institutions in the state that has the highest sum of assets from banks established between January 1, 1900, and December 31, 2000, with institution names starting with 'Bank'?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq288

CREATE TABLE INSTITUTIONS («fdic_certificate_number» STRING, «institution_name» STRING, «state_name» STRING, «fdic_id» STRING, «docket» STRING, «active» BOOL, «address» STRING, «total_assets» INT, «bank_charter_class» STRING, «change_code_1» STRING, «change_code_2» STRING, «change_code_3» STRING, «change_code_4» STRING, «change_code_5» STRING, «change_code_6» STRING, «change_code_7» STRING, «change_code_8» STRING, «change_code_9» STRING, «change_code_10» STRING, «change_code_11» STRING, «change_code_12» STRING, «change_code_13» STRING, «change_code_14» STRING, «change_code_15» STRING, «occ_charter» STRING, «chartering_agency» STRING, «conservatorship» BOOL, «city» STRING, «category_code» STRING, «county_fips_code» STRING, «county_name» STRING, «established_date» STRING, «last_updated» STRING, «effective_date» STRING, «end_effective_date» STRING, «denovo_institute» BOOL, «total_deposits» INT, «equity_capital» INT, «fdic_geo_region» STRING, «fdic_supervisory_region» STRING, «fdic_supervisory_region_code» STRING, «fed_reserve_district» STRING, «fed_reserve_district_id» STRING, «fed_reserve_unique_id» STRING, «federal_charter» BOOL, «fdic_field_office» STRING, «iba» BOOL, «inactive_flag» BOOL, «insurance_fund_membership» STRING, «secondary_insurance_fund» STRING, «deposit_insurance_date» STRING, «credit_card_institution» BOOL, «bank_insurance_fund_member» BOOL, «insured_commercial_bank» BOOL, «deposit_insurance_fund_member» BOOL, «fdic_insured» BOOL, «saif_insured» BOOL, «insured_savings_institute» BOOL, «new_cert_number» STRING, «oakar_institute» BOOL, «ots_region» STRING, «last_structural_change» STRING, «qbp_region» STRING, «regulator» STRING, «report_date» STRING, «reporting_period_end_date» STRING, «state_chartered» BOOL, «return_on_assets» FLOAT, «roa_quarterly» FLOAT, «roa_pretax» FLOAT, «row_pretax_quarterly» FLOAT, «return_on_equity» FLOAT, «roe_quarterly» FLOAT, «run_date» STRING, «sasser_institute» BOOL, «law_sasser» BOOL, «state» STRING, «state_fips_code» STRING, «trade_name_1» STRING, «trade_name_2» STRING, «trade_name_3» STRING, «trade_name_4» STRING, «trade_name_5» STRING, «trade_name_6» STRING, «zip_code» STRING, «occ_district» STRING, «ultimate_cert_number» STRING, «cfpb_supervisory_flag» BOOL, «cfpb_supervisory_start_date» STRING, «cfpb_supervisory_end_date» STRING, «offices_count» INT, «parent_fdic_cert» STRING, «parent_parcert» STRING, «high_holder_city» STRING, «total_domestic_deposits» INT, «ffiec_call_report_filer» BOOL, «holding_company_flag» BOOL, «ag_lending_flag» BOOL, «ownership_type» STRING, «top_holder» STRING, «net_income» INT, «quarterly_net_income» INT, «office_count_domestic» INT, «office_count_foreign» INT, «office_count_us_territories» INT, «rssd_id» STRING, «holding_company_state» STRING, «subchap_s_indicator» BOOL, «trust_powers_status» STRING, «asset_concentration_hierarchy» STRING, «primary_specialization» STRING, «csa_name» STRING, «csa_fips_code» STRING, «csa_indicator» BOOL, «cbsa_name» STRING, «cbsa_fips_code» STRING, «cbsa_metro_flag» BOOL, «cbsa_micro_flag» BOOL, «cbsa_division_name» STRING, «cbsa_division_fips_code» STRING, «cbsa_division_flag» BOOL)

HYPOTHESIS hyp0_1_0 : INSTITUTIONS "\"institution_name\" LIKE 'Bank%'"
HYPOTHESIS hyp0_1_1 : INSTITUTIONS "\"established_date\" >= '1900-01-01'"
HYPOTHESIS hyp0_1_2 : INSTITUTIONS "\"established_date\" <= '2000-12-31'"
theorem eq_0_1 (t : TableRel INSTITUTIONS_schema) (h0 : hyp0_1_0 t) (h1 : hyp0_1_1 t) (h2 : hyp0_1_2 t) :
    (sql%([INSTITUTIONS_schema]) "WITH filtered_banks AS (\n    SELECT \"state_name\", SUM(\"total_assets\") AS sum_assets\n    FROM \"FDA\".\"FDIC_BANKS\".\"INSTITUTIONS\"\n    WHERE \"institution_name\" LIKE 'Bank%'\n      AND \"established_date\" >= '1900-01-01'\n      AND \"established_date\" <= '2000-12-31'\n    GROUP BY \"state_name\"\n    ORDER BY sum_assets DESC NULLS LAST\n    LIMIT 1\n)\nSELECT COUNT(\"institution_name\") AS \"COUNT(\"\"INSTITUTION_NAME\"\")\"\nFROM \"FDA\".\"FDIC_BANKS\".\"INSTITUTIONS\"\nWHERE \"state_name\" = (SELECT \"state_name\" FROM filtered_banks);") t ~= (sql%([INSTITUTIONS_schema]) "SELECT COUNT(\"institution_name\") AS \"COUNT(\"\"INSTITUTION_NAME\"\")\"\nFROM \"FDA\".\"FDIC_BANKS\".\"INSTITUTIONS\"\nWHERE \"state_name\" = (\n    SELECT \"state_name\"\n    FROM \"FDA\".\"FDIC_BANKS\".\"INSTITUTIONS\"\n    WHERE \"institution_name\" LIKE 'Bank%'\n      AND \"established_date\" BETWEEN '1900-01-01' AND '2000-12-31'\n    GROUP BY \"state_name\"\n    ORDER BY SUM(\"total_assets\") DESC NULLS LAST\n    LIMIT 1\n);") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : INSTITUTIONS "\"institution_name\" LIKE 'Bank%'"
HYPOTHESIS hyp0_2_1 : INSTITUTIONS "\"established_date\" >= '1900-01-01'"
HYPOTHESIS hyp0_2_2 : INSTITUTIONS "\"established_date\" <= '2000-12-31'"
theorem eq_0_2 (t : TableRel INSTITUTIONS_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) (h2 : hyp0_2_2 t) :
    (sql%([INSTITUTIONS_schema]) "WITH filtered_banks AS (\n    SELECT \"state_name\", SUM(\"total_assets\") AS sum_assets\n    FROM \"FDA\".\"FDIC_BANKS\".\"INSTITUTIONS\"\n    WHERE \"institution_name\" LIKE 'Bank%'\n      AND \"established_date\" >= '1900-01-01'\n      AND \"established_date\" <= '2000-12-31'\n    GROUP BY \"state_name\"\n    ORDER BY sum_assets DESC NULLS LAST\n    LIMIT 1\n)\nSELECT COUNT(\"institution_name\") AS \"COUNT(\"\"INSTITUTION_NAME\"\")\"\nFROM \"FDA\".\"FDIC_BANKS\".\"INSTITUTIONS\"\nWHERE \"state_name\" = (SELECT \"state_name\" FROM filtered_banks);") t ~= (sql%([INSTITUTIONS_schema]) "SELECT COUNT(\"institution_name\")\nFROM \"FDA\".\"FDIC_BANKS\".\"INSTITUTIONS\"\nWHERE \"state_name\" = (\n    SELECT \"state_name\"\n    FROM \"FDA\".\"FDIC_BANKS\".\"INSTITUTIONS\"\n    WHERE \"institution_name\" LIKE 'Bank%'\n      AND \"established_date\" BETWEEN '1900-01-01' AND '2000-12-31'\n    GROUP BY \"state_name\"\n    ORDER BY SUM(\"total_assets\") DESC NULLS LAST\n    LIMIT 1\n);") t := by
  first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([INSTITUTIONS_schema]) "SELECT COUNT(\"institution_name\") AS \"COUNT(\"\"INSTITUTION_NAME\"\")\"\nFROM \"FDA\".\"FDIC_BANKS\".\"INSTITUTIONS\"\nWHERE \"state_name\" = (\n    SELECT \"state_name\"\n    FROM \"FDA\".\"FDIC_BANKS\".\"INSTITUTIONS\"\n    WHERE \"institution_name\" LIKE 'Bank%'\n      AND \"established_date\" BETWEEN '1900-01-01' AND '2000-12-31'\n    GROUP BY \"state_name\"\n    ORDER BY SUM(\"total_assets\") DESC NULLS LAST\n    LIMIT 1\n);") t ~= (sql%([INSTITUTIONS_schema]) "SELECT COUNT(\"institution_name\")\nFROM \"FDA\".\"FDIC_BANKS\".\"INSTITUTIONS\"\nWHERE \"state_name\" = (\n    SELECT \"state_name\"\n    FROM \"FDA\".\"FDIC_BANKS\".\"INSTITUTIONS\"\n    WHERE \"institution_name\" LIKE 'Bank%'\n      AND \"established_date\" BETWEEN '1900-01-01' AND '2000-12-31'\n    GROUP BY \"state_name\"\n    ORDER BY SUM(\"total_assets\") DESC NULLS LAST\n    LIMIT 1\n);") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq288
