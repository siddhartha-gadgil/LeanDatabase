import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq411 — crossskill equivalence(s)

Question: Please retrieve the top three Google Trends search terms (ranks 1, 2, and 3) from top_terms for each weekday (Monday through Friday) between September 1, 2024, and September 14, 2024, grouped by the refresh_date column and ordered in descending order of refresh_date.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq411

CREATE TABLE TOP_TERMS («dma_name» STRING, «dma_id» INT, «term» STRING, «week» STRING, «score» INT, «rank» INT, «refresh_date» STRING)

HYPOTHESIS hyp0_1_0 : TOP_TERMS "\"rank\" <= 3"
HYPOTHESIS hyp0_1_1 : TOP_TERMS "\"rank\" IN (1, 2, 3)"
theorem eq_0_1 (t : TableRel TOP_TERMS_schema) (h0 : hyp0_1_0 t) (h1 : hyp0_1_1 t) :
    (sql%([TOP_TERMS_schema]) "SELECT DISTINCT \"refresh_date\", \"rank\", \"term\" FROM \"GOOGLE_TRENDS\".\"GOOGLE_TRENDS\".\"TOP_TERMS\" WHERE \"rank\" <= 3 AND DAY_OF_WEEK(\"refresh_date\") BETWEEN 2 AND 6 AND \"refresh_date\" BETWEEN '2024-09-01' AND '2024-09-28' ORDER BY \"refresh_date\" DESC, \"rank\" ASC") t = (sql%([TOP_TERMS_schema]) "SELECT DISTINCT \"refresh_date\", \"rank\", \"term\" FROM \"GOOGLE_TRENDS\".\"GOOGLE_TRENDS\".\"TOP_TERMS\" WHERE \"refresh_date\" BETWEEN '2024-09-15' AND '2024-09-28' AND DAY_OF_WEEK(\"refresh_date\") BETWEEN 2 AND 6 AND \"rank\" IN (1, 2, 3) ORDER BY \"refresh_date\" DESC, \"rank\"") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : TOP_TERMS "NOT DAY_OF_WEEK(\"refresh_date\") IN (0, 1)"
theorem eq_0_2 (t : TableRel TOP_TERMS_schema) (h0 : hyp0_2_0 t) :
    (sql%([TOP_TERMS_schema]) "SELECT DISTINCT \"refresh_date\", \"rank\", \"term\" FROM \"GOOGLE_TRENDS\".\"GOOGLE_TRENDS\".\"TOP_TERMS\" WHERE \"rank\" <= 3 AND DAY_OF_WEEK(\"refresh_date\") BETWEEN 2 AND 6 AND \"refresh_date\" BETWEEN '2024-09-01' AND '2024-09-28' ORDER BY \"refresh_date\" DESC, \"rank\" ASC") t = (sql%([TOP_TERMS_schema]) "SELECT DISTINCT \"refresh_date\", \"term\", \"rank\" FROM \"GOOGLE_TRENDS\".\"GOOGLE_TRENDS\".\"TOP_TERMS\" WHERE \"refresh_date\" BETWEEN '2024-09-17' AND '2024-09-28' AND NOT DAY_OF_WEEK(\"refresh_date\") IN (0, 1) AND \"rank\" <= 3 ORDER BY \"refresh_date\" DESC, \"rank\"") t := by
  first | sql_equiv | sorry

theorem eq_0_3 :
    sql%([TOP_TERMS_schema]) "SELECT DISTINCT \"refresh_date\", \"rank\", \"term\" FROM \"GOOGLE_TRENDS\".\"GOOGLE_TRENDS\".\"TOP_TERMS\" WHERE \"rank\" <= 3 AND DAY_OF_WEEK(\"refresh_date\") BETWEEN 2 AND 6 AND \"refresh_date\" BETWEEN '2024-09-01' AND '2024-09-28' ORDER BY \"refresh_date\" DESC, \"rank\" ASC" = sql%([TOP_TERMS_schema]) "SELECT DISTINCT \"refresh_date\", \"term\", \"rank\" FROM \"GOOGLE_TRENDS\".\"GOOGLE_TRENDS\".\"TOP_TERMS\" WHERE \"refresh_date\" BETWEEN '2024-09-16' AND '2024-09-29' AND DAY_OF_WEEK(\"refresh_date\") BETWEEN 2 AND 6 AND \"rank\" <= 3 ORDER BY \"refresh_date\" DESC, \"rank\" ASC" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : TOP_TERMS "\"rank\" IN (1, 2, 3)"
HYPOTHESIS hyp1_2_1 : TOP_TERMS "NOT DAY_OF_WEEK(\"refresh_date\") IN (0, 1)"
HYPOTHESIS hyp1_2_2 : TOP_TERMS "\"rank\" <= 3"
theorem eq_1_2 (t : TableRel TOP_TERMS_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) (h2 : hyp1_2_2 t) :
    (sql%([TOP_TERMS_schema]) "SELECT DISTINCT \"refresh_date\", \"rank\", \"term\" FROM \"GOOGLE_TRENDS\".\"GOOGLE_TRENDS\".\"TOP_TERMS\" WHERE \"refresh_date\" BETWEEN '2024-09-15' AND '2024-09-28' AND DAY_OF_WEEK(\"refresh_date\") BETWEEN 2 AND 6 AND \"rank\" IN (1, 2, 3) ORDER BY \"refresh_date\" DESC, \"rank\"") t = (sql%([TOP_TERMS_schema]) "SELECT DISTINCT \"refresh_date\", \"term\", \"rank\" FROM \"GOOGLE_TRENDS\".\"GOOGLE_TRENDS\".\"TOP_TERMS\" WHERE \"refresh_date\" BETWEEN '2024-09-17' AND '2024-09-28' AND NOT DAY_OF_WEEK(\"refresh_date\") IN (0, 1) AND \"rank\" <= 3 ORDER BY \"refresh_date\" DESC, \"rank\"") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : TOP_TERMS "\"rank\" IN (1, 2, 3)"
HYPOTHESIS hyp1_3_1 : TOP_TERMS "\"rank\" <= 3"
theorem eq_1_3 (t : TableRel TOP_TERMS_schema) (h0 : hyp1_3_0 t) (h1 : hyp1_3_1 t) :
    (sql%([TOP_TERMS_schema]) "SELECT DISTINCT \"refresh_date\", \"rank\", \"term\" FROM \"GOOGLE_TRENDS\".\"GOOGLE_TRENDS\".\"TOP_TERMS\" WHERE \"refresh_date\" BETWEEN '2024-09-15' AND '2024-09-28' AND DAY_OF_WEEK(\"refresh_date\") BETWEEN 2 AND 6 AND \"rank\" IN (1, 2, 3) ORDER BY \"refresh_date\" DESC, \"rank\"") t = (sql%([TOP_TERMS_schema]) "SELECT DISTINCT \"refresh_date\", \"term\", \"rank\" FROM \"GOOGLE_TRENDS\".\"GOOGLE_TRENDS\".\"TOP_TERMS\" WHERE \"refresh_date\" BETWEEN '2024-09-16' AND '2024-09-29' AND DAY_OF_WEEK(\"refresh_date\") BETWEEN 2 AND 6 AND \"rank\" <= 3 ORDER BY \"refresh_date\" DESC, \"rank\" ASC") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : TOP_TERMS "NOT DAY_OF_WEEK(\"refresh_date\") IN (0, 1)"
theorem eq_2_3 (t : TableRel TOP_TERMS_schema) (h0 : hyp2_3_0 t) :
    (sql%([TOP_TERMS_schema]) "SELECT DISTINCT \"refresh_date\", \"term\", \"rank\" FROM \"GOOGLE_TRENDS\".\"GOOGLE_TRENDS\".\"TOP_TERMS\" WHERE \"refresh_date\" BETWEEN '2024-09-17' AND '2024-09-28' AND NOT DAY_OF_WEEK(\"refresh_date\") IN (0, 1) AND \"rank\" <= 3 ORDER BY \"refresh_date\" DESC, \"rank\"") t = (sql%([TOP_TERMS_schema]) "SELECT DISTINCT \"refresh_date\", \"term\", \"rank\" FROM \"GOOGLE_TRENDS\".\"GOOGLE_TRENDS\".\"TOP_TERMS\" WHERE \"refresh_date\" BETWEEN '2024-09-16' AND '2024-09-29' AND DAY_OF_WEEK(\"refresh_date\") BETWEEN 2 AND 6 AND \"rank\" <= 3 ORDER BY \"refresh_date\" DESC, \"rank\" ASC") t := by
  first | sql_equiv | sorry

end Bench_sf_bq411
