import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq285_eq_0_1

CREATE TABLE LOCATIONS («fdic_certificate_number» STRING, «institution_name» STRING, «branch_name» STRING, «branch_number» STRING, «main_office» BOOL, «branch_address» STRING, «branch_city» STRING, «zip_code» STRING, «branch_county» STRING, «county_fips_code» STRING, «state» STRING, «state_name» STRING, «institution_class» STRING, «cbsa_fips_code» STRING, «cbsa_name» STRING, «cbsa_division_flag» BOOL, «cbsa_division_fips_code» INT, «cbsa_division_name» STRING, «cbsa_metro_flag» BOOL, «cbsa_metro_fips_code» STRING, «cbsa_metro_name» STRING, «cbsa_micro_flag» BOOL, «csa_flag» BOOL, «csa_fips_code» STRING, «csa_name» STRING, «date_established» STRING, «fdic_uninum» STRING, «last_updated» STRING, «service_type» STRING, «branch_fdic_uninum» STRING)

theorem eq (t0 : TableRel LOCATIONS_schema) :
    (sql%([LOCATIONS_schema]) "SELECT \"zip_code\" AS OUTPUT FROM \"FDA\".\"FDIC_BANKS\".\"LOCATIONS\" WHERE \"state_name\" = 'Florida' GROUP BY \"zip_code\" ORDER BY COUNT(*) DESC LIMIT 1") t0
  = (sql%([LOCATIONS_schema]) "SELECT \"zip_code\" AS OUTPUT FROM \"FDA\".\"FDIC_BANKS\".\"LOCATIONS\" WHERE \"state_name\" = 'Florida' GROUP BY \"zip_code\" ORDER BY COUNT(DISTINCT \"fdic_certificate_number\") DESC LIMIT 1") t0
  := by first | sql_equiv | sorry

end N_sf_bq285_eq_0_1
