import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq137 — crossskill equivalence(s)

Question: Please find all zip code areas located within 10 kilometers of the coordinates (-122.3321, 47.6062) by joining the 2010 census population data (summing only male and female populations with no age constraints) and the zip code area information, and return each area’s polygon, land and water area in meters, latitude and longitude, state code, state name, city, county, and total population.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq137

CREATE TABLE POPULATION_BY_ZIP_2010 («geo_id» STRING, «zipcode» STRING, «population» INT, «minimum_age» INT, «maximum_age» INT, «gender» STRING)
CREATE TABLE ZIPCODE_AREA («zipcode» STRING, «area_land_meters» INT, «area_water_meters» INT, «area_land_miles» FLOAT, «area_water_miles» FLOAT, «latitude» FLOAT, «longitude» FLOAT, «state_code» STRING, «state_name» STRING, «city» STRING, «county» STRING, «state_fips» STRING, «zipcode_geom» STRING)

theorem eq_0_1 :
    sql%([POPULATION_BY_ZIP_2010_schema, ZIPCODE_AREA_schema]) "SELECT\n  za.\"zipcode_geom\",\n  za.\"area_land_meters\",\n  za.\"area_water_meters\",\n  za.\"latitude\",\n  za.\"longitude\",\n  za.\"state_code\",\n  za.\"state_name\",\n  za.\"city\",\n  za.\"county\",\n  SUM(p.\"population\") AS TOTAL_POPULATION\nFROM \"CENSUS_BUREAU_USA\".\"UTILITY_US\".\"ZIPCODE_AREA\" za\nJOIN \"CENSUS_BUREAU_USA\".\"CENSUS_BUREAU_USA\".\"POPULATION_BY_ZIP_2010\" p\n  ON za.\"zipcode\" = p.\"zipcode\"\nWHERE p.\"gender\" IN ('male', 'female')\n  AND p.\"minimum_age\" IS NULL\n  AND p.\"maximum_age\" IS NULL\n  AND ST_DWITHIN(\n    TO_GEOGRAPHY(za.\"zipcode_geom\"),\n    ST_MAKEPOINT(-122.3321, 47.6062),\n    10000\n  )\nGROUP BY\n  za.\"zipcode_geom\",\n  za.\"area_land_meters\",\n  za.\"area_water_meters\",\n  za.\"latitude\",\n  za.\"longitude\",\n  za.\"state_code\",\n  za.\"state_name\",\n  za.\"city\",\n  za.\"county\"" = sql%([POPULATION_BY_ZIP_2010_schema, ZIPCODE_AREA_schema]) "SELECT\n    za.\"zipcode_geom\",\n    za.\"area_land_meters\",\n    za.\"area_water_meters\",\n    za.\"latitude\",\n    za.\"longitude\",\n    za.\"state_code\",\n    za.\"state_name\",\n    za.\"city\",\n    za.\"county\",\n    SUM(p.\"population\") AS TOTAL_POPULATION\nFROM \"CENSUS_BUREAU_USA\".\"UTILITY_US\".\"ZIPCODE_AREA\" za\nJOIN \"CENSUS_BUREAU_USA\".\"CENSUS_BUREAU_USA\".\"POPULATION_BY_ZIP_2010\" p\n    ON za.\"zipcode\" = p.\"zipcode\"\nWHERE ST_DWITHIN(\n    TO_GEOGRAPHY(za.\"zipcode_geom\"),\n    ST_MAKEPOINT(-122.3321, 47.6062),\n    10000\n)\nAND p.\"gender\" IN ('male', 'female')\nAND p.\"minimum_age\" IS NULL\nAND p.\"maximum_age\" IS NULL\nGROUP BY\n    za.\"zipcode_geom\",\n    za.\"area_land_meters\",\n    za.\"area_water_meters\",\n    za.\"latitude\",\n    za.\"longitude\",\n    za.\"state_code\",\n    za.\"state_name\",\n    za.\"city\",\n    za.\"county\";" := by
  first | sql_equiv | sorry

-- eq_0_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_2 :
    sql%([POPULATION_BY_ZIP_2010_schema, ZIPCODE_AREA_schema]) "SELECT\n  za.\"zipcode_geom\",\n  za.\"area_land_meters\",\n  za.\"area_water_meters\",\n  za.\"latitude\",\n  za.\"longitude\",\n  za.\"state_code\",\n  za.\"state_name\",\n  za.\"city\",\n  za.\"county\",\n  SUM(p.\"population\") AS TOTAL_POPULATION\nFROM \"CENSUS_BUREAU_USA\".\"UTILITY_US\".\"ZIPCODE_AREA\" za\nJOIN \"CENSUS_BUREAU_USA\".\"CENSUS_BUREAU_USA\".\"POPULATION_BY_ZIP_2010\" p\n  ON za.\"zipcode\" = p.\"zipcode\"\nWHERE p.\"gender\" IN ('male', 'female')\n  AND p.\"minimum_age\" IS NULL\n  AND p.\"maximum_age\" IS NULL\n  AND ST_DWITHIN(\n    TO_GEOGRAPHY(za.\"zipcode_geom\"),\n    ST_MAKEPOINT(-122.3321, 47.6062),\n    10000\n  )\nGROUP BY\n  za.\"zipcode_geom\",\n  za.\"area_land_meters\",\n  za.\"area_water_meters\",\n  za.\"latitude\",\n  za.\"longitude\",\n  za.\"state_code\",\n  za.\"state_name\",\n  za.\"city\",\n  za.\"county\"" = sql%([POPULATION_BY_ZIP_2010_schema, ZIPCODE_AREA_schema]) "SELECT \n  za.\"zipcode_geom\",\n  za.\"area_land_meters\",\n  za.\"area_water_meters\",\n  za.\"latitude\",\n  za.\"longitude\",\n  za.\"state_code\",\n  za.\"state_name\",\n  za.\"city\",\n  za.\"county\",\n  SUM(pop.\"population\") AS TOTAL_POPULATION\nFROM \"CENSUS_BUREAU_USA\".\"UTILITY_US\".\"ZIPCODE_AREA\" za\nJOIN \"CENSUS_BUREAU_USA\".\"CENSUS_BUREAU_USA\".\"POPULATION_BY_ZIP_2010\" pop\n  ON za.\"zipcode\" = pop.\"zipcode\"\nWHERE pop.\"gender\" IN ('male', 'female')\n  AND pop.\"minimum_age\" IS NULL\n  AND pop.\"maximum_age\" IS NULL\n  AND ST_DWITHIN(\n    ST_GEOGRAPHYFROMWKT(za.\"zipcode_geom\"),\n    ST_MAKEPOINT(-122.3321, 47.6062),\n    10000\n  )\nGROUP BY \n  za.\"zipcode_geom\",\n  za.\"area_land_meters\",\n  za.\"area_water_meters\",\n  za.\"latitude\",\n  za.\"longitude\",\n  za.\"state_code\",\n  za.\"state_name\",\n  za.\"city\",\n  za.\"county\";" := by
  first | sql_equiv | sorry

-- eq_1_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_1_2 :
    sql%([POPULATION_BY_ZIP_2010_schema, ZIPCODE_AREA_schema]) "SELECT\n    za.\"zipcode_geom\",\n    za.\"area_land_meters\",\n    za.\"area_water_meters\",\n    za.\"latitude\",\n    za.\"longitude\",\n    za.\"state_code\",\n    za.\"state_name\",\n    za.\"city\",\n    za.\"county\",\n    SUM(p.\"population\") AS TOTAL_POPULATION\nFROM \"CENSUS_BUREAU_USA\".\"UTILITY_US\".\"ZIPCODE_AREA\" za\nJOIN \"CENSUS_BUREAU_USA\".\"CENSUS_BUREAU_USA\".\"POPULATION_BY_ZIP_2010\" p\n    ON za.\"zipcode\" = p.\"zipcode\"\nWHERE ST_DWITHIN(\n    TO_GEOGRAPHY(za.\"zipcode_geom\"),\n    ST_MAKEPOINT(-122.3321, 47.6062),\n    10000\n)\nAND p.\"gender\" IN ('male', 'female')\nAND p.\"minimum_age\" IS NULL\nAND p.\"maximum_age\" IS NULL\nGROUP BY\n    za.\"zipcode_geom\",\n    za.\"area_land_meters\",\n    za.\"area_water_meters\",\n    za.\"latitude\",\n    za.\"longitude\",\n    za.\"state_code\",\n    za.\"state_name\",\n    za.\"city\",\n    za.\"county\";" = sql%([POPULATION_BY_ZIP_2010_schema, ZIPCODE_AREA_schema]) "SELECT \n  za.\"zipcode_geom\",\n  za.\"area_land_meters\",\n  za.\"area_water_meters\",\n  za.\"latitude\",\n  za.\"longitude\",\n  za.\"state_code\",\n  za.\"state_name\",\n  za.\"city\",\n  za.\"county\",\n  SUM(pop.\"population\") AS TOTAL_POPULATION\nFROM \"CENSUS_BUREAU_USA\".\"UTILITY_US\".\"ZIPCODE_AREA\" za\nJOIN \"CENSUS_BUREAU_USA\".\"CENSUS_BUREAU_USA\".\"POPULATION_BY_ZIP_2010\" pop\n  ON za.\"zipcode\" = pop.\"zipcode\"\nWHERE pop.\"gender\" IN ('male', 'female')\n  AND pop.\"minimum_age\" IS NULL\n  AND pop.\"maximum_age\" IS NULL\n  AND ST_DWITHIN(\n    ST_GEOGRAPHYFROMWKT(za.\"zipcode_geom\"),\n    ST_MAKEPOINT(-122.3321, 47.6062),\n    10000\n  )\nGROUP BY \n  za.\"zipcode_geom\",\n  za.\"area_land_meters\",\n  za.\"area_water_meters\",\n  za.\"latitude\",\n  za.\"longitude\",\n  za.\"state_code\",\n  za.\"state_name\",\n  za.\"city\",\n  za.\"county\";" := by
  first | sql_equiv | sorry

end Bench_sf_bq137
