import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq137_eq_1_2

CREATE TABLE POPULATION_BY_ZIP_2010 («geo_id» STRING, «zipcode» STRING, «population» INT, «minimum_age» INT, «maximum_age» INT, «gender» STRING)
CREATE TABLE ZIPCODE_AREA («zipcode» STRING, «area_land_meters» INT, «area_water_meters» INT, «area_land_miles» FLOAT, «area_water_miles» FLOAT, «latitude» FLOAT, «longitude» FLOAT, «state_code» STRING, «state_name» STRING, «city» STRING, «county» STRING, «state_fips» STRING, «zipcode_geom» STRING)

theorem eq (t0 : TableRel POPULATION_BY_ZIP_2010_schema) (t1 : TableRel ZIPCODE_AREA_schema) :
    (sql%([POPULATION_BY_ZIP_2010_schema, ZIPCODE_AREA_schema]) "SELECT za.\"zipcode_geom\", za.\"area_land_meters\", za.\"area_water_meters\", za.\"latitude\", za.\"longitude\", za.\"state_code\", za.\"state_name\", za.\"city\", za.\"county\", SUM(p.\"population\") AS TOTAL_POPULATION FROM \"CENSUS_BUREAU_USA\".\"UTILITY_US\".\"ZIPCODE_AREA\" AS za JOIN \"CENSUS_BUREAU_USA\".\"CENSUS_BUREAU_USA\".\"POPULATION_BY_ZIP_2010\" AS p ON za.\"zipcode\" = p.\"zipcode\" WHERE ST_DWITHIN(CAST(za.\"zipcode_geom\" AS GEOGRAPHY), ST_POINT(-122.3321, 47.6062), 10000) AND p.\"gender\" IN ('male', 'female') AND p.\"minimum_age\" IS NULL AND p.\"maximum_age\" IS NULL GROUP BY za.\"zipcode_geom\", za.\"area_land_meters\", za.\"area_water_meters\", za.\"latitude\", za.\"longitude\", za.\"state_code\", za.\"state_name\", za.\"city\", za.\"county\"") t0 t1
  = (sql%([POPULATION_BY_ZIP_2010_schema, ZIPCODE_AREA_schema]) "SELECT za.\"zipcode_geom\", za.\"area_land_meters\", za.\"area_water_meters\", za.\"latitude\", za.\"longitude\", za.\"state_code\", za.\"state_name\", za.\"city\", za.\"county\", SUM(pop.\"population\") AS TOTAL_POPULATION FROM \"CENSUS_BUREAU_USA\".\"UTILITY_US\".\"ZIPCODE_AREA\" AS za JOIN \"CENSUS_BUREAU_USA\".\"CENSUS_BUREAU_USA\".\"POPULATION_BY_ZIP_2010\" AS pop ON za.\"zipcode\" = pop.\"zipcode\" WHERE pop.\"gender\" IN ('male', 'female') AND pop.\"minimum_age\" IS NULL AND pop.\"maximum_age\" IS NULL AND ST_DWITHIN(ST_GEOGRAPHYFROMWKT(za.\"zipcode_geom\"), ST_POINT(-122.3321, 47.6062), 10000) GROUP BY za.\"zipcode_geom\", za.\"area_land_meters\", za.\"area_water_meters\", za.\"latitude\", za.\"longitude\", za.\"state_code\", za.\"state_name\", za.\"city\", za.\"county\"") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq137_eq_1_2
