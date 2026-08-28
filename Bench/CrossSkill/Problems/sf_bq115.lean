import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq115 — crossskill equivalence(s)

Question: Which country has the highest percentage of population under the age of 25 in 2017?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq115

CREATE TABLE MIDYEAR_POPULATION («country_code» STRING, «country_name» STRING, «year» INT, «midyear_population» INT)
CREATE TABLE MIDYEAR_POPULATION_AGESPECIFIC («country_code» STRING, «country_name» STRING, «year» INT, «sex» STRING, «population» INT, «age» INT)

theorem eq_0_1 :
    sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \"country_name\" AS OUTPUT FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" WHERE \"year\" = 2017 GROUP BY \"country_name\" ORDER BY CAST(SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 AS DOUBLE PRECISION) / SUM(\"population\") DESC LIMIT 1" = sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \"country_name\" AS \"OUTPUT\" FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" WHERE \"year\" = 2017 GROUP BY \"country_name\" HAVING SUM(\"population\") > 0 ORDER BY CAST(SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 AS DOUBLE PRECISION) / SUM(\"population\") DESC LIMIT 1" := by
  first | sql_equiv | sorry

theorem eq_0_2 : ∀ t,
    (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \"country_name\" AS OUTPUT FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" WHERE \"year\" = 2017 GROUP BY \"country_name\" ORDER BY CAST(SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 AS DOUBLE PRECISION) / SUM(\"population\") DESC LIMIT 1") t ~= (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "WITH under25 AS (SELECT \"country_code\", \"country_name\", SUM(\"population\") AS pop_under_25 FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" WHERE \"year\" = 2017 AND \"age\" < 25 GROUP BY \"country_code\", \"country_name\"), total AS (SELECT \"country_code\", \"midyear_population\" AS total_pop FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION\" WHERE \"year\" = 2017) SELECT u.\"country_name\" AS \"OUTPUT\" FROM total AS t JOIN under25 AS u ON t.\"country_code\" = u.\"country_code\" WHERE t.total_pop > 0 ORDER BY (CAST(u.pop_under_25 AS DOUBLE PRECISION) / t.total_pop) DESC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

-- eq_0_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_3 : ∀ t,
    (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \"country_name\" AS OUTPUT FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" WHERE \"year\" = 2017 GROUP BY \"country_name\" ORDER BY CAST(SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 AS DOUBLE PRECISION) / SUM(\"population\") DESC LIMIT 1") t ~= (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT a.\"country_name\" AS country_name FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" AS a JOIN \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION\" AS m ON a.\"country_code\" = m.\"country_code\" AND a.\"year\" = m.\"year\" WHERE a.\"year\" = 2017 AND a.\"age\" < 25 GROUP BY a.\"country_name\", m.\"midyear_population\" ORDER BY CAST(SUM(a.\"population\") AS DOUBLE PRECISION) / m.\"midyear_population\" DESC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \"country_name\" AS \"OUTPUT\" FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" WHERE \"year\" = 2017 GROUP BY \"country_name\" HAVING SUM(\"population\") > 0 ORDER BY CAST(SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 AS DOUBLE PRECISION) / SUM(\"population\") DESC LIMIT 1") t ~= (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "WITH under25 AS (SELECT \"country_code\", \"country_name\", SUM(\"population\") AS pop_under_25 FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" WHERE \"year\" = 2017 AND \"age\" < 25 GROUP BY \"country_code\", \"country_name\"), total AS (SELECT \"country_code\", \"midyear_population\" AS total_pop FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION\" WHERE \"year\" = 2017) SELECT u.\"country_name\" AS \"OUTPUT\" FROM total AS t JOIN under25 AS u ON t.\"country_code\" = u.\"country_code\" WHERE t.total_pop > 0 ORDER BY (CAST(u.pop_under_25 AS DOUBLE PRECISION) / t.total_pop) DESC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

-- eq_1_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_1_3 : ∀ t,
    (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \"country_name\" AS \"OUTPUT\" FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" WHERE \"year\" = 2017 GROUP BY \"country_name\" HAVING SUM(\"population\") > 0 ORDER BY CAST(SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 AS DOUBLE PRECISION) / SUM(\"population\") DESC LIMIT 1") t ~= (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT a.\"country_name\" AS country_name FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" AS a JOIN \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION\" AS m ON a.\"country_code\" = m.\"country_code\" AND a.\"year\" = m.\"year\" WHERE a.\"year\" = 2017 AND a.\"age\" < 25 GROUP BY a.\"country_name\", m.\"midyear_population\" ORDER BY CAST(SUM(a.\"population\") AS DOUBLE PRECISION) / m.\"midyear_population\" DESC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

-- eq_2_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_2_3 : ∀ t,
    (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "WITH under25 AS (SELECT \"country_code\", \"country_name\", SUM(\"population\") AS pop_under_25 FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" WHERE \"year\" = 2017 AND \"age\" < 25 GROUP BY \"country_code\", \"country_name\"), total AS (SELECT \"country_code\", \"midyear_population\" AS total_pop FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION\" WHERE \"year\" = 2017) SELECT u.\"country_name\" AS \"OUTPUT\" FROM total AS t JOIN under25 AS u ON t.\"country_code\" = u.\"country_code\" WHERE t.total_pop > 0 ORDER BY (CAST(u.pop_under_25 AS DOUBLE PRECISION) / t.total_pop) DESC LIMIT 1") t ~= (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT a.\"country_name\" AS country_name FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" AS a JOIN \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION\" AS m ON a.\"country_code\" = m.\"country_code\" AND a.\"year\" = m.\"year\" WHERE a.\"year\" = 2017 AND a.\"age\" < 25 GROUP BY a.\"country_name\", m.\"midyear_population\" ORDER BY CAST(SUM(a.\"population\") AS DOUBLE PRECISION) / m.\"midyear_population\" DESC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq115
