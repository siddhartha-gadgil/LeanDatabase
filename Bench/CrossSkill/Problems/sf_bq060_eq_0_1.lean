import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq060_eq_0_1

CREATE TABLE BIRTH_DEATH_GROWTH_RATES («country_code» STRING, «country_name» STRING, «year» INT, «crude_birth_rate» FLOAT, «crude_death_rate» FLOAT, «net_migration» FLOAT, «rate_natural_increase» FLOAT, «growth_rate» FLOAT)
CREATE TABLE COUNTRY_NAMES_AREA («country_code» STRING, «country_name» STRING, «country_area» FLOAT)

theorem eq (t0 : TableRel BIRTH_DEATH_GROWTH_RATES_schema) (t1 : TableRel COUNTRY_NAMES_AREA_schema) :
    (sql%([BIRTH_DEATH_GROWTH_RATES_schema, COUNTRY_NAMES_AREA_schema]) "SELECT b.\"country_name\", b.\"net_migration\" FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"BIRTH_DEATH_GROWTH_RATES\" AS b JOIN \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"COUNTRY_NAMES_AREA\" AS c ON b.\"country_code\" = c.\"country_code\" WHERE b.\"year\" = 2017 AND c.\"country_area\" > 500 ORDER BY b.\"net_migration\" DESC LIMIT 3") t0 t1
  = (sql%([BIRTH_DEATH_GROWTH_RATES_schema, COUNTRY_NAMES_AREA_schema]) "SELECT c.\"country_name\", b.\"net_migration\" FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"BIRTH_DEATH_GROWTH_RATES\" AS b JOIN \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"COUNTRY_NAMES_AREA\" AS c ON b.\"country_code\" = c.\"country_code\" WHERE b.\"year\" = 2017 AND c.\"country_area\" > 500 ORDER BY b.\"net_migration\" DESC LIMIT 3") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq060_eq_0_1
