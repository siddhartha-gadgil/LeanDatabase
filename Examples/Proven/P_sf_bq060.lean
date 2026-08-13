import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq060 — a proven cross-skill equivalence

Question: Which top 3 countries had the highest net migration in 2017 among those with an area greater than 500 square kilometers? And what are their migration rates?

Two independently-written SQL answers to the same question, proved equivalent for *all*
table contents by `sql_equiv` (not just on one instance).
-/

namespace P_sf_bq060

CREATE TABLE BIRTH_DEATH_GROWTH_RATES («country_code» STRING, «country_name» STRING, «year» INT, «net_migration» FLOAT)
CREATE TABLE COUNTRY_NAMES_AREA («country_code» STRING, «country_name» STRING, «country_area» FLOAT)

/-- Variant A:  SELECT b."country_name", b."net_migration" FROM "CENSUS_BUREAU_INTERNATIONAL"."CENSUS_BUREAU_INTERNATIONAL"."BIRTH_DEATH_GROWTH_RATES" b JOIN "CENSUS_BUREAU_INT
    Variant B:  SELECT b."country_name" AS "country_name", b."net_migration" AS "net_migration" FROM "CENSUS_BUREAU_INTERNATIONAL"."CENSUS_BUREAU_INTERNATIONAL"."BIRTH_DEATH_GR -/
theorem equivalent :
    sql%([BIRTH_DEATH_GROWTH_RATES_schema, COUNTRY_NAMES_AREA_schema]) "SELECT\n    b.\"country_name\",\n    b.\"net_migration\"\nFROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"BIRTH_DEATH_GROWTH_RATES\" b\nJOIN \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"COUNTRY_NAMES_AREA\" c\n    ON b.\"country_code\" = c.\"country_code\"\nWHERE b.\"year\" = 2017\n    AND c.\"country_area\" > 500\nORDER BY b.\"net_migration\" DESC\nLIMIT 3;"
      = sql%([BIRTH_DEATH_GROWTH_RATES_schema, COUNTRY_NAMES_AREA_schema]) "SELECT\n    b.\"country_name\" AS \"country_name\",\n    b.\"net_migration\" AS \"net_migration\"\nFROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"BIRTH_DEATH_GROWTH_RATES\" b\nJOIN \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"COUNTRY_NAMES_AREA\" a\n    ON b.\"country_code\" = a.\"country_code\"\nWHERE b.\"year\" = 2017\n    AND a.\"country_area\" > 500\nORDER BY b.\"net_migration\" DESC\nLIMIT 3;" := by sql_equiv

end P_sf_bq060
