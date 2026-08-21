import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq406 — crossskill equivalence(s)

Question: Please calculate the growth rates for Asians, Black people, Latinx people, Native Americans, White people, US women, US men, global women, and global men from 2014 to 2024 concerning the overall workforce.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq406

CREATE TABLE DAR_NON_INTERSECTIONAL_REPRESENTATION («workforce» STRING, «report_year» INT, «race_asian» FLOAT, «race_black» FLOAT, «race_hispanic_latinx» FLOAT, «race_native_american» FLOAT, «race_white» FLOAT, «gender_us_women» FLOAT, «gender_us_men» FLOAT, «gender_global_women» FLOAT, «gender_global_men» FLOAT)

HYPOTHESIS hyp0_1_0 : DAR_NON_INTERSECTIONAL_REPRESENTATION "\"report_year\" = 2024) y2024"
theorem eq_0_1 (t : TableRel DAR_NON_INTERSECTIONAL_REPRESENTATION_schema) (h0 : hyp0_1_0 t) :
    (sql%([DAR_NON_INTERSECTIONAL_REPRESENTATION_schema]) "WITH y2014 AS (\n  SELECT\n    \"race_asian\",\n    \"race_black\",\n    \"race_hispanic_latinx\",\n    \"race_native_american\",\n    \"race_white\",\n    \"gender_us_women\",\n    \"gender_us_men\",\n    \"gender_global_women\",\n    \"gender_global_men\"\n  FROM \"GOOGLE_DEI\".\"GOOGLE_DEI\".\"DAR_NON_INTERSECTIONAL_REPRESENTATION\"\n  WHERE \"workforce\" = 'overall' AND \"report_year\" = 2014\n),\ny2024 AS (\n  SELECT\n    \"race_asian\",\n    \"race_black\",\n    \"race_hispanic_latinx\",\n    \"race_native_american\",\n    \"race_white\",\n    \"gender_us_women\",\n    \"gender_us_men\",\n    \"gender_global_women\",\n    \"gender_global_men\"\n  FROM \"GOOGLE_DEI\".\"GOOGLE_DEI\".\"DAR_NON_INTERSECTIONAL_REPRESENTATION\"\n  WHERE \"workforce\" = 'overall' AND \"report_year\" = 2024\n)\nSELECT\n  (y2024.\"race_asian\" - y2014.\"race_asian\") / y2014.\"race_asian\" AS RACE_ASIAN_GROWTH,\n  (y2024.\"race_black\" - y2014.\"race_black\") / y2014.\"race_black\" AS RACE_BLACK_GROWTH,\n  (y2024.\"race_hispanic_latinx\" - y2014.\"race_hispanic_latinx\") / y2014.\"race_hispanic_latinx\" AS RACE_HISPANIC_GROWTH,\n  (y2024.\"race_native_american\" - y2014.\"race_native_american\") / y2014.\"race_native_american\" AS RACE_NATIVE_AMERICAN_GROWTH,\n  (y2024.\"race_white\" - y2014.\"race_white\") / y2014.\"race_white\" AS RACE_WHITE_GROWTH,\n  (y2024.\"gender_us_women\" - y2014.\"gender_us_women\") / y2014.\"gender_us_women\" AS GENDER_US_WOMEN_GROWTH,\n  (y2024.\"gender_us_men\" - y2014.\"gender_us_men\") / y2014.\"gender_us_men\" AS GENDER_US_MEN_GROWTH,\n  (y2024.\"gender_global_women\" - y2014.\"gender_global_women\") / y2014.\"gender_global_women\" AS GENDER_GLOBAL_WOMEN_GROWTH,\n  (y2024.\"gender_global_men\" - y2014.\"gender_global_men\") / y2014.\"gender_global_men\" AS GENDER_GLOBAL_MEN_GROWTH\nFROM y2014\nCROSS JOIN y2024;") t ~= (sql%([DAR_NON_INTERSECTIONAL_REPRESENTATION_schema]) "SELECT\n  (y2024.\"race_asian\" - y2014.\"race_asian\") / y2014.\"race_asian\" AS RACE_ASIAN_GROWTH,\n  (y2024.\"race_black\" - y2014.\"race_black\") / y2014.\"race_black\" AS RACE_BLACK_GROWTH,\n  (y2024.\"race_hispanic_latinx\" - y2014.\"race_hispanic_latinx\") / y2014.\"race_hispanic_latinx\" AS RACE_HISPANIC_GROWTH,\n  (y2024.\"race_native_american\" - y2014.\"race_native_american\") / y2014.\"race_native_american\" AS RACE_NATIVE_AMERICAN_GROWTH,\n  (y2024.\"race_white\" - y2014.\"race_white\") / y2014.\"race_white\" AS RACE_WHITE_GROWTH,\n  (y2024.\"gender_us_women\" - y2014.\"gender_us_women\") / y2014.\"gender_us_women\" AS GENDER_US_WOMEN_GROWTH,\n  (y2024.\"gender_us_men\" - y2014.\"gender_us_men\") / y2014.\"gender_us_men\" AS GENDER_US_MEN_GROWTH,\n  (y2024.\"gender_global_women\" - y2014.\"gender_global_women\") / y2014.\"gender_global_women\" AS GENDER_GLOBAL_WOMEN_GROWTH,\n  (y2024.\"gender_global_men\" - y2014.\"gender_global_men\") / y2014.\"gender_global_men\" AS GENDER_GLOBAL_MEN_GROWTH\nFROM\n  (SELECT * FROM \"GOOGLE_DEI\".\"GOOGLE_DEI\".\"DAR_NON_INTERSECTIONAL_REPRESENTATION\" WHERE \"workforce\" = 'overall' AND \"report_year\" = 2014) y2014,\n  (SELECT * FROM \"GOOGLE_DEI\".\"GOOGLE_DEI\".\"DAR_NON_INTERSECTIONAL_REPRESENTATION\" WHERE \"workforce\" = 'overall' AND \"report_year\" = 2024) y2024;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq406
