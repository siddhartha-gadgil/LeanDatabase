import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq232 — proven cross-skill equivalence(s), hypothesis-conditioned

Question: Could you provide the total number of 'Other Theft' incidents within the 'Theft and Handling' category for each year in the Westminster borough?

Independently-written SQL variants proved equal for all table contents by `sql_equiv`.
Where the variants differ by a `WHERE` conjunct, that data assumption is stated as a
`HYPOTHESIS` antecedent (so the equivalence is explicit and sound).
-/

namespace P_sf_bq232

CREATE TABLE CRIME_BY_LSOA («lsoa_code» STRING, «borough» STRING, «major_category» STRING, «minor_category» STRING, «value» INT, «year» INT, «month» INT)

HYPOTHESIS h0 : CRIME_BY_LSOA "\"major_category\" = 'Theft and Handling'"

theorem eq_0_1 (t : TableRel CRIME_BY_LSOA_schema) :
    (sql%([CRIME_BY_LSOA_schema]) "SELECT\n    \"year\",\n    SUM(\"value\") AS YEAR_TOTAL\nFROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\"\nWHERE \"borough\" = 'Westminster'\n  AND \"major_category\" = 'Theft and Handling'\n  AND \"minor_category\" = 'Other Theft'\nGROUP BY \"year\"\nORDER BY \"year\";") t = (sql%([CRIME_BY_LSOA_schema]) "SELECT\n    \"year\" AS \"year\",\n    SUM(\"value\") AS \"YEAR_TOTAL\"\nFROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\"\nWHERE \"borough\" = 'Westminster'\n  AND \"major_category\" = 'Theft and Handling'\n  AND \"minor_category\" = 'Other Theft'\nGROUP BY \"year\"\nORDER BY \"year\";") t := by sql_equiv
theorem eq_0_2 (t : TableRel CRIME_BY_LSOA_schema) (a0 : h0 t) :
    (sql%([CRIME_BY_LSOA_schema]) "SELECT\n    \"year\",\n    SUM(\"value\") AS YEAR_TOTAL\nFROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\"\nWHERE \"borough\" = 'Westminster'\n  AND \"major_category\" = 'Theft and Handling'\n  AND \"minor_category\" = 'Other Theft'\nGROUP BY \"year\"\nORDER BY \"year\";") t = (sql%([CRIME_BY_LSOA_schema]) "SELECT\n    \"year\",\n    SUM(\"value\") AS YEAR_TOTAL\nFROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\"\nWHERE \"borough\" = 'Westminster'\n  AND \"minor_category\" = 'Other Theft'\nGROUP BY \"year\"\nORDER BY \"year\";") t := by sql_equiv
theorem eq_1_2 (t : TableRel CRIME_BY_LSOA_schema) (a0 : h0 t) :
    (sql%([CRIME_BY_LSOA_schema]) "SELECT\n    \"year\" AS \"year\",\n    SUM(\"value\") AS \"YEAR_TOTAL\"\nFROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\"\nWHERE \"borough\" = 'Westminster'\n  AND \"major_category\" = 'Theft and Handling'\n  AND \"minor_category\" = 'Other Theft'\nGROUP BY \"year\"\nORDER BY \"year\";") t = (sql%([CRIME_BY_LSOA_schema]) "SELECT\n    \"year\",\n    SUM(\"value\") AS YEAR_TOTAL\nFROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\"\nWHERE \"borough\" = 'Westminster'\n  AND \"minor_category\" = 'Other Theft'\nGROUP BY \"year\"\nORDER BY \"year\";") t := by sql_equiv

end P_sf_bq232
