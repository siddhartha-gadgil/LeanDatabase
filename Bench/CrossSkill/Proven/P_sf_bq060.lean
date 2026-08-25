import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq060 — proven cross-skill equivalence(s)

Question: Which top 3 countries had the highest net migration in 2017 among those with an area greater than 500 square kilometers? And what are their migration rates?

Independently-written SQL variants proved equal for all table contents by `sql_equiv`; where
they differ by a `WHERE`/`SELECT` fact, that data assumption is an explicit `HYPOTHESIS` antecedent.
-/

namespace P_sf_bq060

CREATE TABLE BIRTH_DEATH_GROWTH_RATES («country_code» STRING, «country_name» STRING, «year» INT, «crude_birth_rate» FLOAT, «crude_death_rate» FLOAT, «net_migration» FLOAT, «rate_natural_increase» FLOAT, «growth_rate» FLOAT)
CREATE TABLE COUNTRY_NAMES_AREA («country_code» STRING, «country_name» STRING, «country_area» FLOAT)

theorem eq_0_2 :
    sql%([BIRTH_DEATH_GROWTH_RATES_schema, COUNTRY_NAMES_AREA_schema]) "SELECT b.\"country_name\", b.\"net_migration\" FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"BIRTH_DEATH_GROWTH_RATES\" AS b JOIN \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"COUNTRY_NAMES_AREA\" AS c ON b.\"country_code\" = c.\"country_code\" WHERE b.\"year\" = 2017 AND c.\"country_area\" > 500 ORDER BY b.\"net_migration\" DESC LIMIT 3" = sql%([BIRTH_DEATH_GROWTH_RATES_schema, COUNTRY_NAMES_AREA_schema]) "SELECT b.\"country_name\" AS \"country_name\", b.\"net_migration\" AS \"net_migration\" FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"BIRTH_DEATH_GROWTH_RATES\" AS b JOIN \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"COUNTRY_NAMES_AREA\" AS a ON b.\"country_code\" = a.\"country_code\" WHERE b.\"year\" = 2017 AND a.\"country_area\" > 500 ORDER BY b.\"net_migration\" DESC LIMIT 3" := by sql_equiv

end P_sf_bq060
