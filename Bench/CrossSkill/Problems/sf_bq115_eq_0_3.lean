import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq115_eq_0_3

CREATE TABLE MIDYEAR_POPULATION_AGESPECIFIC («country_code» STRING, «country_name» STRING, «year» INT, «sex» STRING, «population» INT, «age» INT)

theorem eq (t0 : TableRel MIDYEAR_POPULATION_AGESPECIFIC_schema) :
    (sql%([MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \"country_name\" AS OUTPUT FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" WHERE \"year\" = 2017 GROUP BY \"country_name\" ORDER BY CAST(SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 AS DOUBLE PRECISION) / SUM(\"population\") DESC LIMIT 1") t0
  ~= (sql%([MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT a.\"country_name\" AS country_name FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" AS a JOIN \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION\" AS m ON a.\"country_code\" = m.\"country_code\" AND a.\"year\" = m.\"year\" WHERE a.\"year\" = 2017 AND a.\"age\" < 25 GROUP BY a.\"country_name\", m.\"midyear_population\" ORDER BY CAST(SUM(a.\"population\") AS DOUBLE PRECISION) / m.\"midyear_population\" DESC LIMIT 1") t0
  := by first | sql_equiv | sorry

end N_sf_bq115_eq_0_3
