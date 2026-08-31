import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local100_eq_0_2

CREATE TABLE M_CAST («index» INT, «MID» STRING, «PID» STRING, «ID» INT)

theorem eq (t0 : TableRel M_CAST_schema) :
    (sql%([M_CAST_schema]) "WITH srk_movies AS (/* Movies that Shah Rukh Khan acted in */ SELECT \"MID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" WHERE \"PID\" = ' nm0451321'), srk_coactors AS (/* Shahrukh number 1: actors who directly acted with SRK */ SELECT DISTINCT mc.\"PID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS mc JOIN srk_movies AS sm ON mc.\"MID\" = sm.\"MID\" WHERE mc.\"PID\" <> ' nm0451321'), srk_number_2 AS (/* Shahrukh number 2: actors who acted with SRK's co-actors */ /* but NOT directly with SRK himself */ SELECT DISTINCT mc2.\"PID\" FROM srk_coactors AS sc JOIN \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS mc1 ON sc.\"PID\" = mc1.\"PID\" JOIN \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS mc2 ON mc1.\"MID\" = mc2.\"MID\" WHERE mc2.\"PID\" <> ALL (SELECT \"PID\" FROM srk_coactors) AND mc2.\"PID\" <> ' nm0451321') SELECT COUNT(*) AS SHAHRUKH_NUMBER_2_COUNT FROM srk_number_2") t0
  = (sql%([M_CAST_schema]) "/* Shahrukh Khan's PID in PERSON table: 'nm0451321' */ /* M_CAST PID has leading space, so we TRIM when joining to PERSON */ WITH shahrukh_movies AS (/* Movies Shahrukh Khan appeared in */ SELECT DISTINCT \"MID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" WHERE TRIM(\"PID\") = 'nm0451321'), shahrukh_number_1 AS (/* Actors who co-starred with Shahrukh Khan (Shahrukh number 1) */ /* Exclude Shahrukh Khan himself */ SELECT DISTINCT TRIM(c.\"PID\") AS \"PID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c INNER JOIN shahrukh_movies AS sm ON c.\"MID\" = sm.\"MID\" WHERE TRIM(c.\"PID\") <> 'nm0451321'), sn1_movies AS (/* Movies that Shahrukh number 1 actors appeared in */ SELECT DISTINCT c.\"MID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c INNER JOIN shahrukh_number_1 AS sn1 ON TRIM(c.\"PID\") = sn1.\"PID\"), shahrukh_number_2_candidates AS (/* Actors who co-starred with Shahrukh number 1 actors */ /* Exclude Shahrukh Khan himself and Shahrukh number 1 actors */ SELECT DISTINCT TRIM(c.\"PID\") AS \"PID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c INNER JOIN sn1_movies AS sm ON c.\"MID\" = sm.\"MID\" WHERE TRIM(c.\"PID\") <> 'nm0451321' AND TRIM(c.\"PID\") <> ALL (SELECT \"PID\" FROM shahrukh_number_1)) SELECT COUNT(*) AS \"SHAHRUKH_NUMBER_2_COUNT\" FROM shahrukh_number_2_candidates") t0
  := by first | sql_equiv | sorry

end N_sf_local100_eq_0_2
