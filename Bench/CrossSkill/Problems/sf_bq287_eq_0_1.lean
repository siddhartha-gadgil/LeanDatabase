import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq287_eq_0_1

CREATE TABLE LOCATIONS («fdic_certificate_number» STRING, «institution_name» STRING, «branch_name» STRING, «branch_number» STRING, «main_office» BOOL, «branch_address» STRING, «branch_city» STRING, «zip_code» STRING, «branch_county» STRING, «county_fips_code» STRING, «state» STRING, «state_name» STRING, «institution_class» STRING, «cbsa_fips_code» STRING, «cbsa_name» STRING, «cbsa_division_flag» BOOL, «cbsa_division_fips_code» INT, «cbsa_division_name» STRING, «cbsa_metro_flag» BOOL, «cbsa_metro_fips_code» STRING, «cbsa_metro_name» STRING, «cbsa_micro_flag» BOOL, «csa_flag» BOOL, «csa_fips_code» STRING, «csa_name» STRING, «date_established» STRING, «fdic_uninum» STRING, «last_updated» STRING, «service_type» STRING, «branch_fdic_uninum» STRING)
CREATE TABLE ZIP_CODES («zip_code» STRING, «city» STRING, «county» STRING, «state_fips_code» STRING, «state_code» STRING, «state_name» STRING, «fips_class_code» STRING, «mtfcc_feature_class_code» STRING, «functional_status» STRING, «area_land_meters» FLOAT, «area_water_meters» FLOAT, «internal_point_lat» FLOAT, «internal_point_lon» FLOAT, «internal_point_geom» STRING, «zip_code_geom» STRING)

theorem eq (t0 : TableRel LOCATIONS_schema) (t1 : TableRel ZIP_CODES_schema) :
    (sql%([LOCATIONS_schema, ZIP_CODES_schema]) "WITH utah_zips AS (SELECT \"zip_code\" FROM \"FDA\".\"GEO_US_BOUNDARIES\".\"ZIP_CODES\" WHERE \"state_code\" = 'UT'), bank_counts AS (SELECT uz.\"zip_code\", COUNT(loc.\"zip_code\") AS bank_location_count FROM utah_zips AS uz LEFT JOIN \"FDA\".\"FDIC_BANKS\".\"LOCATIONS\" AS loc ON uz.\"zip_code\" = loc.\"zip_code\" GROUP BY uz.\"zip_code\"), fewest_bank_zip AS (SELECT \"zip_code\" FROM bank_counts ORDER BY bank_location_count ASC, \"zip_code\" ASC LIMIT 1) SELECT CAST(acs.\"employed_pop\" AS DOUBLE PRECISION) / acs.\"pop_16_over\" AS EMPLOYMENT_RATE FROM fewest_bank_zip AS fbz JOIN \"CENSUS_BUREAU_ACS_2\".\"CENSUS_BUREAU_ACS\".\"ZIP_CODES_2017_5YR\" AS acs ON fbz.\"zip_code\" = acs.\"geo_id\"") t0 t1
  ~= (sql%([LOCATIONS_schema, ZIP_CODES_schema]) "WITH utah_zip_bank_counts AS (SELECT z.\"zip_code\", COUNT(l.\"zip_code\") AS num_locations FROM \"FDA\".\"GEO_US_BOUNDARIES\".\"ZIP_CODES\" AS z LEFT JOIN \"FDA\".\"FDIC_BANKS\".\"LOCATIONS\" AS l ON z.\"zip_code\" = l.\"zip_code\" WHERE z.\"state_code\" = 'UT' GROUP BY z.\"zip_code\"), min_location_zip AS (SELECT \"zip_code\" FROM utah_zip_bank_counts WHERE num_locations = (SELECT MIN(num_locations) FROM utah_zip_bank_counts) ORDER BY \"zip_code\" ASC LIMIT 1) SELECT CAST(a.\"employed_pop\" AS DOUBLE PRECISION) / NULLIF(a.\"pop_16_over\", 0) AS EMPLOYMENT_RATE FROM min_location_zip AS m JOIN \"CENSUS_BUREAU_ACS_2\".\"CENSUS_BUREAU_ACS\".\"ZIP_CODES_2017_5YR\" AS a ON m.\"zip_code\" = a.\"geo_id\"") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq287_eq_0_1
