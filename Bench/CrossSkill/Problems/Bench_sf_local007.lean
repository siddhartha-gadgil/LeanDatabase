import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_local007 — crossskill equivalence(s)

Question: Could you help me calculate the average single career span value in years for all baseball players? Please precise the result as a float number. First, calculate the difference in years, months, and days between the debut and final game dates. For each player, the career span is computed as the sum of the absolute number of years, plus the absolute number of months divided by 12, plus the absolute number of days divided by 365. Round each part to two decimal places before summing. Finally, average the career spans and round the result to a float number.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_local007

CREATE TABLE PLAYER («player_id» STRING, «birth_year» STRING, «birth_month» STRING, «birth_day» STRING, «birth_country» STRING, «birth_state» STRING, «birth_city» STRING, «death_year» STRING, «death_month» STRING, «death_day» STRING, «death_country» STRING, «death_state» STRING, «death_city» STRING, «name_first» STRING, «name_last» STRING, «name_given» STRING, «weight» STRING, «height» STRING, «bats» STRING, «throws» STRING, «debut» STRING, «final_game» STRING, «retro_id» STRING, «bbref_id» STRING)

HYPOTHESIS hyp0_1_0 : PLAYER "\"FINAL_GAME\" IS NOT NULL"
theorem eq_0_1 (t : TableRel PLAYER_schema) (h0 : hyp0_1_0 t) :
    (sql%([PLAYER_schema]) "SELECT AVG(DATEDIFF('day', \"DEBUT\", \"FINAL_GAME\") / 365.0) AS \"AVG_CAREER_SPAN\"\nFROM \"BASEBALL\".\"BASEBALL\".\"PLAYER\"\nWHERE \"DEBUT\" IS NOT NULL AND \"FINAL_GAME\" IS NOT NULL") t ~= (sql%([PLAYER_schema]) "SELECT \n  AVG(DATEDIFF('day', \"DEBUT\", \"FINAL_GAME\") / 365.0) AS \"AVERAGE_CAREER_SPAN_YEARS\"\nFROM \"BASEBALL\".\"BASEBALL\".\"PLAYER\"\nWHERE \"DEBUT\" IS NOT NULL \n  AND \"FINAL_GAME\" IS NOT NULL;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : PLAYER "\"FINAL_GAME\" IS NOT NULL"
theorem eq_0_2 (t : TableRel PLAYER_schema) (h0 : hyp0_2_0 t) :
    (sql%([PLAYER_schema]) "SELECT AVG(DATEDIFF('day', \"DEBUT\", \"FINAL_GAME\") / 365.0) AS \"AVG_CAREER_SPAN\"\nFROM \"BASEBALL\".\"BASEBALL\".\"PLAYER\"\nWHERE \"DEBUT\" IS NOT NULL AND \"FINAL_GAME\" IS NOT NULL") t ~= (sql%([PLAYER_schema]) "SELECT\n    ROUND(AVG(DATEDIFF('day', \"DEBUT\", \"FINAL_GAME\") / 365.0), 12) AS \"AVERAGE_CAREER_SPAN_YEARS\"\nFROM \"BASEBALL\".\"BASEBALL\".\"PLAYER\"\nWHERE \"DEBUT\" IS NOT NULL AND \"FINAL_GAME\" IS NOT NULL;") t := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([PLAYER_schema]) "SELECT \n  AVG(DATEDIFF('day', \"DEBUT\", \"FINAL_GAME\") / 365.0) AS \"AVERAGE_CAREER_SPAN_YEARS\"\nFROM \"BASEBALL\".\"BASEBALL\".\"PLAYER\"\nWHERE \"DEBUT\" IS NOT NULL \n  AND \"FINAL_GAME\" IS NOT NULL;" = sql%([PLAYER_schema]) "SELECT\n    ROUND(AVG(DATEDIFF('day', \"DEBUT\", \"FINAL_GAME\") / 365.0), 12) AS \"AVERAGE_CAREER_SPAN_YEARS\"\nFROM \"BASEBALL\".\"BASEBALL\".\"PLAYER\"\nWHERE \"DEBUT\" IS NOT NULL AND \"FINAL_GAME\" IS NOT NULL;" := by
  first | sql_equiv | sorry

end Bench_sf_local007
