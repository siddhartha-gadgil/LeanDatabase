import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq330_eq_0_3

CREATE TABLE LOCATIONS («fdic_certificate_number» STRING, «institution_name» STRING, «branch_name» STRING, «branch_number» STRING, «main_office» BOOL, «branch_address» STRING, «branch_city» STRING, «zip_code» STRING, «branch_county» STRING, «county_fips_code» STRING, «state» STRING, «state_name» STRING, «institution_class» STRING, «cbsa_fips_code» STRING, «cbsa_name» STRING, «cbsa_division_flag» BOOL, «cbsa_division_fips_code» INT, «cbsa_division_name» STRING, «cbsa_metro_flag» BOOL, «cbsa_metro_fips_code» STRING, «cbsa_metro_name» STRING, «cbsa_micro_flag» BOOL, «csa_flag» BOOL, «csa_fips_code» STRING, «csa_name» STRING, «date_established» STRING, «fdic_uninum» STRING, «last_updated» STRING, «service_type» STRING, «branch_fdic_uninum» STRING)
CREATE TABLE BLOCKGROUPS_08 («geo_id» STRING, «state_fips_code» STRING, «county_fips_code» STRING, «tract_ce» STRING, «blockgroup_ce» STRING, «lsad_name» STRING, «mtfcc_feature_class_code» STRING, «functional_status» STRING, «area_land_meters» INT, «area_water_meters» INT, «internal_point_lat» FLOAT, «internal_point_lon» FLOAT, «internal_point_geom» STRING, «blockgroup_geom» STRING)
CREATE TABLE ZIP_CODES («zip_code» STRING, «city» STRING, «county» STRING, «state_fips_code» STRING, «state_code» STRING, «state_name» STRING, «fips_class_code» STRING, «mtfcc_feature_class_code» STRING, «functional_status» STRING, «area_land_meters» FLOAT, «area_water_meters» FLOAT, «internal_point_lat» FLOAT, «internal_point_lon» FLOAT, «internal_point_geom» STRING, «zip_code_geom» STRING)

theorem eq (t0 : TableRel LOCATIONS_schema) (t1 : TableRel BLOCKGROUPS_08_schema) (t2 : TableRel ZIP_CODES_schema) :
    (sql%([LOCATIONS_schema, BLOCKGROUPS_08_schema, ZIP_CODES_schema]) "WITH zip_with_block_groups AS (SELECT DISTINCT z.\"zip_code\" FROM \"FDA\".\"GEO_US_BOUNDARIES\".\"ZIP_CODES\" AS z JOIN \"FDA\".\"GEO_CENSUS_BLOCKGROUPS\".\"BLOCKGROUPS_08\" AS b ON ST_INTERSECTS(CAST(z.\"zip_code_geom\" AS GEOGRAPHY), CAST(b.\"blockgroup_geom\" AS GEOGRAPHY)) WHERE z.\"state_code\" = 'CO'), bank_counts AS (SELECT \"zip_code\", CAST(COUNT(*) AS DOUBLE PRECISION) AS bank_count FROM \"FDA\".\"FDIC_BANKS\".\"LOCATIONS\" WHERE \"state_name\" = 'Colorado' GROUP BY \"zip_code\") SELECT bc.\"zip_code\" AS ZIP_CODE, bc.bank_count AS BANK_CONCENTRATION_PER_BLOCK_GROUP FROM bank_counts AS bc JOIN zip_with_block_groups AS zb ON bc.\"zip_code\" = zb.\"zip_code\" ORDER BY BANK_CONCENTRATION_PER_BLOCK_GROUP DESC LIMIT 1") t0 t1 t2
  ~= (sql%([LOCATIONS_schema, BLOCKGROUPS_08_schema, ZIP_CODES_schema]) "WITH bank_counts AS (SELECT \"zip_code\", COUNT(*) AS num_banks FROM \"FDA\".\"FDIC_BANKS\".\"LOCATIONS\" WHERE \"state\" = 'CO' GROUP BY \"zip_code\"), zip_bg AS (SELECT zc.\"zip_code\", COUNT(DISTINCT bg.\"geo_id\") AS num_block_groups FROM \"FDA\".\"GEO_US_BOUNDARIES\".\"ZIP_CODES\" AS zc JOIN \"FDA\".\"GEO_CENSUS_BLOCKGROUPS\".\"BLOCKGROUPS_08\" AS bg ON ST_WITHIN(CAST(zc.\"internal_point_geom\" AS GEOGRAPHY), CAST(bg.\"blockgroup_geom\" AS GEOGRAPHY)) WHERE zc.\"state_code\" = 'CO' GROUP BY zc.\"zip_code\") SELECT bc.\"zip_code\" AS ZIP_CODE, CAST(bc.num_banks * 1.0 AS DOUBLE PRECISION) / zbg.num_block_groups AS BANK_CONCENTRATION_PER_BLOCK_GROUP FROM bank_counts AS bc JOIN zip_bg AS zbg ON bc.\"zip_code\" = zbg.\"zip_code\" ORDER BY BANK_CONCENTRATION_PER_BLOCK_GROUP DESC LIMIT 1") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_bq330_eq_0_3
