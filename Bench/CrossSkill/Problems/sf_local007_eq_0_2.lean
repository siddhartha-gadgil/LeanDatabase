import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local007_eq_0_2

CREATE TABLE PLAYER («player_id» STRING, «birth_year» STRING, «birth_month» STRING, «birth_day» STRING, «birth_country» STRING, «birth_state» STRING, «birth_city» STRING, «death_year» STRING, «death_month» STRING, «death_day» STRING, «death_country» STRING, «death_state» STRING, «death_city» STRING, «name_first» STRING, «name_last» STRING, «name_given» STRING, «weight» STRING, «height» STRING, «bats» STRING, «throws» STRING, «debut» STRING, «final_game» STRING, «retro_id» STRING, «bbref_id» STRING)

theorem eq (t0 : TableRel PLAYER_schema) :
    (sql%([PLAYER_schema]) "SELECT AVG(CAST((CAST(\"FINAL_GAME\" AS DATE) - CAST(\"DEBUT\" AS DATE)) AS DOUBLE PRECISION) / 365.0) AS \"AVG_CAREER_SPAN\" FROM \"BASEBALL\".\"BASEBALL\".\"PLAYER\" WHERE NOT \"DEBUT\" IS NULL AND NOT \"FINAL_GAME\" IS NULL") t0
  ~= (sql%([PLAYER_schema]) "SELECT ROUND(CAST(AVG(CAST((CAST(\"FINAL_GAME\" AS DATE) - CAST(\"DEBUT\" AS DATE)) AS DOUBLE PRECISION) / 365.0) AS DECIMAL), 12) AS \"AVERAGE_CAREER_SPAN_YEARS\" FROM \"BASEBALL\".\"BASEBALL\".\"PLAYER\" WHERE NOT \"DEBUT\" IS NULL AND NOT \"FINAL_GAME\" IS NULL") t0
  := by first | sql_equiv | sorry

end N_sf_local007_eq_0_2
