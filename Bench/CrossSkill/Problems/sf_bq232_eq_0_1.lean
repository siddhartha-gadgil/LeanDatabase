import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq232_eq_0_1

CREATE TABLE CRIME_BY_LSOA («lsoa_code» STRING, «borough» STRING, «major_category» STRING, «minor_category» STRING, «value» INT, «year» INT, «month» INT)

theorem eq (t0 : TableRel CRIME_BY_LSOA_schema) :
    (sql%([CRIME_BY_LSOA_schema]) "SELECT \"year\", SUM(\"value\") AS YEAR_TOTAL FROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\" WHERE \"borough\" = 'Westminster' AND \"major_category\" = 'Theft and Handling' AND \"minor_category\" = 'Other Theft' GROUP BY \"year\" ORDER BY \"year\"") t0
  = (sql%([CRIME_BY_LSOA_schema]) "SELECT \"year\" AS \"year\", SUM(\"value\") AS \"YEAR_TOTAL\" FROM \"LONDON\".\"LONDON_CRIME\".\"CRIME_BY_LSOA\" WHERE \"borough\" = 'Westminster' AND \"major_category\" = 'Theft and Handling' AND \"minor_category\" = 'Other Theft' GROUP BY \"year\" ORDER BY \"year\"") t0
  := by first | sql_equiv | sorry

end N_sf_bq232_eq_0_1
