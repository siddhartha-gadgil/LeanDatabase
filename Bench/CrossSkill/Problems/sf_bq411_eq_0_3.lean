import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq411_eq_0_3

CREATE TABLE TOP_TERMS («dma_name» STRING, «dma_id» INT, «term» STRING, «week» STRING, «score» INT, «rank» INT, «refresh_date» STRING)

theorem eq (t0 : TableRel TOP_TERMS_schema) :
    (sql%([TOP_TERMS_schema]) "SELECT DISTINCT \"refresh_date\", \"rank\", \"term\" FROM \"GOOGLE_TRENDS\".\"GOOGLE_TRENDS\".\"TOP_TERMS\" WHERE \"rank\" <= 3 AND DAY_OF_WEEK(\"refresh_date\") BETWEEN 2 AND 6 AND \"refresh_date\" BETWEEN '2024-09-01' AND '2024-09-28' ORDER BY \"refresh_date\" DESC, \"rank\" ASC") t0
  = (sql%([TOP_TERMS_schema]) "SELECT DISTINCT \"refresh_date\", \"term\", \"rank\" FROM \"GOOGLE_TRENDS\".\"GOOGLE_TRENDS\".\"TOP_TERMS\" WHERE \"refresh_date\" BETWEEN '2024-09-16' AND '2024-09-29' AND DAY_OF_WEEK(\"refresh_date\") BETWEEN 2 AND 6 AND \"rank\" <= 3 ORDER BY \"refresh_date\" DESC, \"rank\" ASC") t0
  := by first | sql_equiv | sorry

end N_sf_bq411_eq_0_3
