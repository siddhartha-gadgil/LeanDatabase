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
    sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \n  \"country_name\" AS OUTPUT\nFROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\"\nWHERE \"year\" = 2017\nGROUP BY \"country_name\"\nORDER BY SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 / SUM(\"population\") DESC\nLIMIT 1;" = sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \"country_name\" AS \"OUTPUT\"\nFROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\"\nWHERE \"year\" = 2017\nGROUP BY \"country_name\"\nHAVING SUM(\"population\") > 0\nORDER BY SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 / SUM(\"population\") DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

theorem eq_0_2 : ∀ t,
    (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \n  \"country_name\" AS OUTPUT\nFROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\"\nWHERE \"year\" = 2017\nGROUP BY \"country_name\"\nORDER BY SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 / SUM(\"population\") DESC\nLIMIT 1;") t ~= (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "WITH under25 AS (\n    SELECT\n        \"country_code\",\n        \"country_name\",\n        SUM(\"population\") AS pop_under_25\n    FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\"\n    WHERE \"year\" = 2017\n      AND \"age\" < 25\n    GROUP BY \"country_code\", \"country_name\"\n),\ntotal AS (\n    SELECT\n        \"country_code\",\n        \"midyear_population\" AS total_pop\n    FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION\"\n    WHERE \"year\" = 2017\n)\nSELECT\n    u.\"country_name\" AS \"OUTPUT\"\nFROM total t\nJOIN under25 u ON t.\"country_code\" = u.\"country_code\"\nWHERE t.total_pop > 0\nORDER BY (u.pop_under_25 / t.total_pop) DESC\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

-- eq_0_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_3 : ∀ t,
    (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \n  \"country_name\" AS OUTPUT\nFROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\"\nWHERE \"year\" = 2017\nGROUP BY \"country_name\"\nORDER BY SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 / SUM(\"population\") DESC\nLIMIT 1;") t ~= (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT\n    a.\"country_name\" AS country_name\nFROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" a\nJOIN \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION\" m\n    ON a.\"country_code\" = m.\"country_code\" AND a.\"year\" = m.\"year\"\nWHERE a.\"year\" = 2017\n    AND a.\"age\" < 25\nGROUP BY a.\"country_name\", m.\"midyear_population\"\nORDER BY SUM(a.\"population\") / m.\"midyear_population\" DESC\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \"country_name\" AS \"OUTPUT\"\nFROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\"\nWHERE \"year\" = 2017\nGROUP BY \"country_name\"\nHAVING SUM(\"population\") > 0\nORDER BY SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 / SUM(\"population\") DESC\nLIMIT 1;") t ~= (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "WITH under25 AS (\n    SELECT\n        \"country_code\",\n        \"country_name\",\n        SUM(\"population\") AS pop_under_25\n    FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\"\n    WHERE \"year\" = 2017\n      AND \"age\" < 25\n    GROUP BY \"country_code\", \"country_name\"\n),\ntotal AS (\n    SELECT\n        \"country_code\",\n        \"midyear_population\" AS total_pop\n    FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION\"\n    WHERE \"year\" = 2017\n)\nSELECT\n    u.\"country_name\" AS \"OUTPUT\"\nFROM total t\nJOIN under25 u ON t.\"country_code\" = u.\"country_code\"\nWHERE t.total_pop > 0\nORDER BY (u.pop_under_25 / t.total_pop) DESC\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

-- eq_1_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_1_3 : ∀ t,
    (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT \"country_name\" AS \"OUTPUT\"\nFROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\"\nWHERE \"year\" = 2017\nGROUP BY \"country_name\"\nHAVING SUM(\"population\") > 0\nORDER BY SUM(CASE WHEN \"age\" < 25 THEN \"population\" ELSE 0 END) * 1.0 / SUM(\"population\") DESC\nLIMIT 1;") t ~= (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT\n    a.\"country_name\" AS country_name\nFROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" a\nJOIN \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION\" m\n    ON a.\"country_code\" = m.\"country_code\" AND a.\"year\" = m.\"year\"\nWHERE a.\"year\" = 2017\n    AND a.\"age\" < 25\nGROUP BY a.\"country_name\", m.\"midyear_population\"\nORDER BY SUM(a.\"population\") / m.\"midyear_population\" DESC\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

-- eq_2_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_2_3 : ∀ t,
    (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "WITH under25 AS (\n    SELECT\n        \"country_code\",\n        \"country_name\",\n        SUM(\"population\") AS pop_under_25\n    FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\"\n    WHERE \"year\" = 2017\n      AND \"age\" < 25\n    GROUP BY \"country_code\", \"country_name\"\n),\ntotal AS (\n    SELECT\n        \"country_code\",\n        \"midyear_population\" AS total_pop\n    FROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION\"\n    WHERE \"year\" = 2017\n)\nSELECT\n    u.\"country_name\" AS \"OUTPUT\"\nFROM total t\nJOIN under25 u ON t.\"country_code\" = u.\"country_code\"\nWHERE t.total_pop > 0\nORDER BY (u.pop_under_25 / t.total_pop) DESC\nLIMIT 1;") t ~= (sql%([MIDYEAR_POPULATION_schema, MIDYEAR_POPULATION_AGESPECIFIC_schema]) "SELECT\n    a.\"country_name\" AS country_name\nFROM \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION_AGESPECIFIC\" a\nJOIN \"CENSUS_BUREAU_INTERNATIONAL\".\"CENSUS_BUREAU_INTERNATIONAL\".\"MIDYEAR_POPULATION\" m\n    ON a.\"country_code\" = m.\"country_code\" AND a.\"year\" = m.\"year\"\nWHERE a.\"year\" = 2017\n    AND a.\"age\" < 25\nGROUP BY a.\"country_name\", m.\"midyear_population\"\nORDER BY SUM(a.\"population\") / m.\"midyear_population\" DESC\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq115
