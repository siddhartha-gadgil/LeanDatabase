import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq232 — crossskill equivalence(s)

Question: Could you provide the total number of 'Other Theft' incidents within the 'Theft and Handling' category for each year in the Westminster borough?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq232

CREATE TABLE CRIME_BY_LSOA («lsoa_code» STRING, «borough» STRING, «major_category» STRING, «minor_category» STRING, «value» INT, «year» INT, «month» INT)

theorem eq_0_1 :
    sql%([CRIME_BY_LSOA_schema]) "SELECT\n    \"year\",\n    SUM(\"value\") AS YEAR_TOTAL\nFROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\"\nWHERE \"borough\" = 'Westminster'\n  AND \"major_category\" = 'Theft and Handling'\n  AND \"minor_category\" = 'Other Theft'\nGROUP BY \"year\"\nORDER BY \"year\";" = sql%([CRIME_BY_LSOA_schema]) "SELECT\n    \"year\" AS \"year\",\n    SUM(\"value\") AS \"YEAR_TOTAL\"\nFROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\"\nWHERE \"borough\" = 'Westminster'\n  AND \"major_category\" = 'Theft and Handling'\n  AND \"minor_category\" = 'Other Theft'\nGROUP BY \"year\"\nORDER BY \"year\";" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : CRIME_BY_LSOA "\"major_category\" = 'Theft and Handling'"
theorem eq_0_2 (t : TableRel CRIME_BY_LSOA_schema) (h0 : hyp0_2_0 t) :
    (sql%([CRIME_BY_LSOA_schema]) "SELECT\n    \"year\",\n    SUM(\"value\") AS YEAR_TOTAL\nFROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\"\nWHERE \"borough\" = 'Westminster'\n  AND \"major_category\" = 'Theft and Handling'\n  AND \"minor_category\" = 'Other Theft'\nGROUP BY \"year\"\nORDER BY \"year\";") t = (sql%([CRIME_BY_LSOA_schema]) "SELECT\n    \"year\",\n    SUM(\"value\") AS YEAR_TOTAL\nFROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\"\nWHERE \"borough\" = 'Westminster'\n  AND \"minor_category\" = 'Other Theft'\nGROUP BY \"year\"\nORDER BY \"year\";") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : CRIME_BY_LSOA "\"major_category\" = 'Theft and Handling'"
theorem eq_1_2 (t : TableRel CRIME_BY_LSOA_schema) (h0 : hyp1_2_0 t) :
    (sql%([CRIME_BY_LSOA_schema]) "SELECT\n    \"year\" AS \"year\",\n    SUM(\"value\") AS \"YEAR_TOTAL\"\nFROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\"\nWHERE \"borough\" = 'Westminster'\n  AND \"major_category\" = 'Theft and Handling'\n  AND \"minor_category\" = 'Other Theft'\nGROUP BY \"year\"\nORDER BY \"year\";") t = (sql%([CRIME_BY_LSOA_schema]) "SELECT\n    \"year\",\n    SUM(\"value\") AS YEAR_TOTAL\nFROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\"\nWHERE \"borough\" = 'Westminster'\n  AND \"minor_category\" = 'Other Theft'\nGROUP BY \"year\"\nORDER BY \"year\";") t := by
  first | sql_equiv | sorry

end Bench_sf_bq232
