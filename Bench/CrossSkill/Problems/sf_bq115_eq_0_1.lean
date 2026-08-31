import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq115_eq_0_1

CREATE TABLE MIDYEAR_POPULATION_AGESPECIFIC («country_code» STRING, «country_name» STRING, «year» INT, «sex» STRING, «population» INT, «age» INT)

theorem eq (t0 : TableRel MIDYEAR_POPULATION_AGESPECIFIC_schema) :
    (sql%([MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \"country_name\" AS OUTPUT FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" WHERE \"year\" = 2017 GROUP BY \"country_name\" ORDER BY CAST(SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 AS DOUBLE PRECISION) / SUM(\"population\") DESC LIMIT 1") t0
  = (sql%([MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \"country_name\" AS \"OUTPUT\" FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" WHERE \"year\" = 2017 GROUP BY \"country_name\" HAVING SUM(\"population\") > 0 ORDER BY CAST(SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 AS DOUBLE PRECISION) / SUM(\"population\") DESC LIMIT 1") t0
  := by first | sql_equiv | sorry

end N_sf_bq115_eq_0_1
