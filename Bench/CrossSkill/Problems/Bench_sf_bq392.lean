import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq392 — crossskill equivalence(s)

Question: What are the top 3 dates in October 2009 with the highest average temperature for station number 723758, in the format YYYY-MM-DD?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq392

CREATE TABLE GSOD2009 («stn» STRING, «wban» STRING, «year» STRING, «mo» STRING, «da» STRING, «temp» FLOAT, «count_temp» INT, «dewp» FLOAT, «count_dewp» INT, «slp» FLOAT, «count_slp» INT, «stp» FLOAT, «count_stp» INT, «visib» FLOAT, «count_visib» INT, «wdsp» STRING, «count_wdsp» STRING, «mxpsd» STRING, «gust» FLOAT, «max» FLOAT, «flag_max» STRING, «min» FLOAT, «flag_min» STRING, «prcp» FLOAT, «flag_prcp» STRING, «sndp» FLOAT, «fog» STRING, «rain_drizzle» STRING, «snow_ice_pellets» STRING, «hail» STRING, «thunder» STRING, «tornado_funnel_cloud» STRING)

HYPOTHESIS hyp0_1_0 : GSOD2009 "\"year\" || '-' || \"mo\" || '-' || \"da\" = \"year\" || '-' || LPAD(\"mo\", 2, '0') || '-' || LPAD(\"da\", 2, '0')"
theorem eq_0_1 (t : TableRel GSOD2009_schema) (h0 : hyp0_1_0 t) :
    (sql%([GSOD2009_schema]) "SELECT\n    \"year\" || '-' || \"mo\" || '-' || \"da\" AS DATES\nFROM \"NOAA_GSOD\".\"NOAA_GSOD\".\"GSOD2009\"\nWHERE \"stn\" = '723758'\n  AND \"mo\" = '10'\n  AND \"temp\" != 9999.9\nORDER BY \"temp\" DESC\nLIMIT 3;") t = (sql%([GSOD2009_schema]) "SELECT\n  \"year\" || '-' || LPAD(\"mo\", 2, '0') || '-' || LPAD(\"da\", 2, '0') AS DATES\nFROM \"NOAA_GSOD\".\"NOAA_GSOD\".\"GSOD2009\"\nWHERE \"stn\" = '723758'\n  AND \"mo\" = '10'\n  AND \"temp\" != 9999.9\nORDER BY \"temp\" DESC\nLIMIT 3;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : GSOD2009 "\"temp\" != 9999.9"
theorem eq_0_2 (t : TableRel GSOD2009_schema) (h0 : hyp0_2_0 t) :
    (sql%([GSOD2009_schema]) "SELECT\n    \"year\" || '-' || \"mo\" || '-' || \"da\" AS DATES\nFROM \"NOAA_GSOD\".\"NOAA_GSOD\".\"GSOD2009\"\nWHERE \"stn\" = '723758'\n  AND \"mo\" = '10'\n  AND \"temp\" != 9999.9\nORDER BY \"temp\" DESC\nLIMIT 3;") t = (sql%([GSOD2009_schema]) "SELECT \n  \"year\" || '-' || \"mo\" || '-' || \"da\" AS \"DATES\"\nFROM \"NOAA_GSOD\".\"NOAA_GSOD\".\"GSOD2009\"\nWHERE \"stn\" = '723758' \n  AND \"mo\" = '10'\nORDER BY \"temp\" DESC\nLIMIT 3;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_3_0 : GSOD2009 "\"temp\" != 9999.9"
HYPOTHESIS hyp0_3_1 : GSOD2009 "\"year\" || '-' || \"mo\" || '-' || \"da\" = \"year\" || '-' || LPAD(\"mo\", 2, '0') || '-' || LPAD(\"da\", 2, '0')"
theorem eq_0_3 (t : TableRel GSOD2009_schema) (h0 : hyp0_3_0 t) (h1 : hyp0_3_1 t) :
    (sql%([GSOD2009_schema]) "SELECT\n    \"year\" || '-' || \"mo\" || '-' || \"da\" AS DATES\nFROM \"NOAA_GSOD\".\"NOAA_GSOD\".\"GSOD2009\"\nWHERE \"stn\" = '723758'\n  AND \"mo\" = '10'\n  AND \"temp\" != 9999.9\nORDER BY \"temp\" DESC\nLIMIT 3;") t = (sql%([GSOD2009_schema]) "SELECT\n    \"year\" || '-' || LPAD(\"mo\", 2, '0') || '-' || LPAD(\"da\", 2, '0') AS \"DATES\"\nFROM \"NOAA_GSOD\".\"NOAA_GSOD\".\"GSOD2009\"\nWHERE \"stn\" = '723758'\n  AND \"mo\" = '10'\nORDER BY \"temp\" DESC\nLIMIT 3;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : GSOD2009 "\"temp\" != 9999.9"
HYPOTHESIS hyp1_2_1 : GSOD2009 "\"year\" || '-' || LPAD(\"mo\", 2, '0') || '-' || LPAD(\"da\", 2, '0') = \"year\" || '-' || \"mo\" || '-' || \"da\""
theorem eq_1_2 (t : TableRel GSOD2009_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) :
    (sql%([GSOD2009_schema]) "SELECT\n  \"year\" || '-' || LPAD(\"mo\", 2, '0') || '-' || LPAD(\"da\", 2, '0') AS DATES\nFROM \"NOAA_GSOD\".\"NOAA_GSOD\".\"GSOD2009\"\nWHERE \"stn\" = '723758'\n  AND \"mo\" = '10'\n  AND \"temp\" != 9999.9\nORDER BY \"temp\" DESC\nLIMIT 3;") t = (sql%([GSOD2009_schema]) "SELECT \n  \"year\" || '-' || \"mo\" || '-' || \"da\" AS \"DATES\"\nFROM \"NOAA_GSOD\".\"NOAA_GSOD\".\"GSOD2009\"\nWHERE \"stn\" = '723758' \n  AND \"mo\" = '10'\nORDER BY \"temp\" DESC\nLIMIT 3;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : GSOD2009 "\"temp\" != 9999.9"
theorem eq_1_3 (t : TableRel GSOD2009_schema) (h0 : hyp1_3_0 t) :
    (sql%([GSOD2009_schema]) "SELECT\n  \"year\" || '-' || LPAD(\"mo\", 2, '0') || '-' || LPAD(\"da\", 2, '0') AS DATES\nFROM \"NOAA_GSOD\".\"NOAA_GSOD\".\"GSOD2009\"\nWHERE \"stn\" = '723758'\n  AND \"mo\" = '10'\n  AND \"temp\" != 9999.9\nORDER BY \"temp\" DESC\nLIMIT 3;") t = (sql%([GSOD2009_schema]) "SELECT\n    \"year\" || '-' || LPAD(\"mo\", 2, '0') || '-' || LPAD(\"da\", 2, '0') AS \"DATES\"\nFROM \"NOAA_GSOD\".\"NOAA_GSOD\".\"GSOD2009\"\nWHERE \"stn\" = '723758'\n  AND \"mo\" = '10'\nORDER BY \"temp\" DESC\nLIMIT 3;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : GSOD2009 "\"year\" || '-' || \"mo\" || '-' || \"da\" = \"year\" || '-' || LPAD(\"mo\", 2, '0') || '-' || LPAD(\"da\", 2, '0')"
theorem eq_2_3 (t : TableRel GSOD2009_schema) (h0 : hyp2_3_0 t) :
    (sql%([GSOD2009_schema]) "SELECT \n  \"year\" || '-' || \"mo\" || '-' || \"da\" AS \"DATES\"\nFROM \"NOAA_GSOD\".\"NOAA_GSOD\".\"GSOD2009\"\nWHERE \"stn\" = '723758' \n  AND \"mo\" = '10'\nORDER BY \"temp\" DESC\nLIMIT 3;") t = (sql%([GSOD2009_schema]) "SELECT\n    \"year\" || '-' || LPAD(\"mo\", 2, '0') || '-' || LPAD(\"da\", 2, '0') AS \"DATES\"\nFROM \"NOAA_GSOD\".\"NOAA_GSOD\".\"GSOD2009\"\nWHERE \"stn\" = '723758'\n  AND \"mo\" = '10'\nORDER BY \"temp\" DESC\nLIMIT 3;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq392
