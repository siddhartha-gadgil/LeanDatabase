import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq232 — proven cross-skill equivalence(s)

Question: Could you provide the total number of 'Other Theft' incidents within the 'Theft and Handling' category for each year in the Westminster borough?

Independently-written SQL variants proved equal for all table contents by `sql_equiv`; where
they differ by a `WHERE`/`SELECT` fact, that data assumption is an explicit `HYPOTHESIS` antecedent.
-/

namespace P_sf_bq232

CREATE TABLE CRIME_BY_LSOA («lsoa_code» STRING, «borough» STRING, «major_category» STRING, «minor_category» STRING, «value» INT, «year» INT, «month» INT)

HYPOTHESIS hyp0_2_0 : CRIME_BY_LSOA "\"major_category\" = 'Theft and Handling'"
HYPOTHESIS hyp1_2_0 : CRIME_BY_LSOA "\"major_category\" = 'Theft and Handling'"

theorem eq_0_1 (t : TableRel CRIME_BY_LSOA_schema) :
    (sql%([CRIME_BY_LSOA_schema]) "SELECT \"year\", SUM(\"value\") AS YEAR_TOTAL FROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\" WHERE \"borough\" = 'Westminster' AND \"major_category\" = 'Theft and Handling' AND \"minor_category\" = 'Other Theft' GROUP BY \"year\" ORDER BY \"year\"") t = (sql%([CRIME_BY_LSOA_schema]) "SELECT \"year\" AS \"year\", SUM(\"value\") AS \"YEAR_TOTAL\" FROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\" WHERE \"borough\" = 'Westminster' AND \"major_category\" = 'Theft and Handling' AND \"minor_category\" = 'Other Theft' GROUP BY \"year\" ORDER BY \"year\"") t := by sql_equiv
theorem eq_0_2 (t : TableRel CRIME_BY_LSOA_schema) (h0 : hyp0_2_0 t) :
    (sql%([CRIME_BY_LSOA_schema]) "SELECT \"year\", SUM(\"value\") AS YEAR_TOTAL FROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\" WHERE \"borough\" = 'Westminster' AND \"major_category\" = 'Theft and Handling' AND \"minor_category\" = 'Other Theft' GROUP BY \"year\" ORDER BY \"year\"") t = (sql%([CRIME_BY_LSOA_schema]) "SELECT \"year\", SUM(\"value\") AS YEAR_TOTAL FROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\" WHERE \"borough\" = 'Westminster' AND \"minor_category\" = 'Other Theft' GROUP BY \"year\" ORDER BY \"year\"") t := by sql_equiv
theorem eq_1_2 (t : TableRel CRIME_BY_LSOA_schema) (h0 : hyp1_2_0 t) :
    (sql%([CRIME_BY_LSOA_schema]) "SELECT \"year\" AS \"year\", SUM(\"value\") AS \"YEAR_TOTAL\" FROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\" WHERE \"borough\" = 'Westminster' AND \"major_category\" = 'Theft and Handling' AND \"minor_category\" = 'Other Theft' GROUP BY \"year\" ORDER BY \"year\"") t = (sql%([CRIME_BY_LSOA_schema]) "SELECT \"year\", SUM(\"value\") AS YEAR_TOTAL FROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\" WHERE \"borough\" = 'Westminster' AND \"minor_category\" = 'Other Theft' GROUP BY \"year\" ORDER BY \"year\"") t := by sql_equiv

end P_sf_bq232
