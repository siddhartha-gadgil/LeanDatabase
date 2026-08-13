import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq232 — a proven cross-skill equivalence

Question: Could you provide the total number of 'Other Theft' incidents within the 'Theft and Handling' category for each year in the Westminster borough?

Two independently-written SQL answers to the same question, proved equivalent for *all*
table contents by `sql_equiv` (not just on one instance).
-/

namespace P_sf_bq232

CREATE TABLE CRIME_BY_LSOA («borough» STRING, «major_category» STRING, «minor_category» STRING, «value» INT, «year» INT)

/-- Variant A:  SELECT "year", SUM("value") AS YEAR_TOTAL FROM "LONDON"."LONDON_CRIME"."CRIME_BY_LSOA" WHERE "borough" = 'Westminster' AND "major_category" = 'Theft and Handlin
    Variant B:  SELECT "year" AS "year", SUM("value") AS "YEAR_TOTAL" FROM "LONDON"."LONDON_CRIME"."CRIME_BY_LSOA" WHERE "borough" = 'Westminster' AND "major_category" = 'Theft -/
theorem equivalent :
    sql%([CRIME_BY_LSOA_schema]) "SELECT\n    \"year\",\n    SUM(\"value\") AS YEAR_TOTAL\nFROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\"\nWHERE \"borough\" = 'Westminster'\n  AND \"major_category\" = 'Theft and Handling'\n  AND \"minor_category\" = 'Other Theft'\nGROUP BY \"year\"\nORDER BY \"year\";"
      = sql%([CRIME_BY_LSOA_schema]) "SELECT\n    \"year\" AS \"year\",\n    SUM(\"value\") AS \"YEAR_TOTAL\"\nFROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\"\nWHERE \"borough\" = 'Westminster'\n  AND \"major_category\" = 'Theft and Handling'\n  AND \"minor_category\" = 'Other Theft'\nGROUP BY \"year\"\nORDER BY \"year\";" := by sql_equiv

end P_sf_bq232
