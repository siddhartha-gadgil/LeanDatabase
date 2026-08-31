import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local100_eq_2_3

CREATE TABLE M_CAST («index» INT, «MID» STRING, «PID» STRING, «ID» INT)

theorem eq (t0 : TableRel M_CAST_schema) :
    (sql%([M_CAST_schema]) "/* Shahrukh Khan's PID in PERSON table: 'nm0451321' */ /* M_CAST PID has leading space, so we TRIM when joining to PERSON */ WITH shahrukh_movies AS (/* Movies Shahrukh Khan appeared in */ SELECT DISTINCT \"MID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" WHERE TRIM(\"PID\") = 'nm0451321'), shahrukh_number_1 AS (/* Actors who co-starred with Shahrukh Khan (Shahrukh number 1) */ /* Exclude Shahrukh Khan himself */ SELECT DISTINCT TRIM(c.\"PID\") AS \"PID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c INNER JOIN shahrukh_movies AS sm ON c.\"MID\" = sm.\"MID\" WHERE TRIM(c.\"PID\") <> 'nm0451321'), sn1_movies AS (/* Movies that Shahrukh number 1 actors appeared in */ SELECT DISTINCT c.\"MID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c INNER JOIN shahrukh_number_1 AS sn1 ON TRIM(c.\"PID\") = sn1.\"PID\"), shahrukh_number_2_candidates AS (/* Actors who co-starred with Shahrukh number 1 actors */ /* Exclude Shahrukh Khan himself and Shahrukh number 1 actors */ SELECT DISTINCT TRIM(c.\"PID\") AS \"PID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c INNER JOIN sn1_movies AS sm ON c.\"MID\" = sm.\"MID\" WHERE TRIM(c.\"PID\") <> 'nm0451321' AND TRIM(c.\"PID\") <> ALL (SELECT \"PID\" FROM shahrukh_number_1)) SELECT COUNT(*) AS \"SHAHRUKH_NUMBER_2_COUNT\" FROM shahrukh_number_2_candidates") t0
  = (sql%([M_CAST_schema]) "/* Find count of actors with Shahrukh number = 2 */ /* Shahrukh number 1: actors who co-starred in a movie with Shahrukh Khan */ /* Shahrukh number 2: actors who co-starred with a Shahrukh-number-1 actor but NOT directly with Shahrukh Khan */ WITH shahrukh_movies AS (/* All movies Shahrukh Khan appeared in */ SELECT DISTINCT TRIM(\"MID\") AS MID FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" WHERE TRIM(\"PID\") = 'nm0451321'), shahrukh_number_1 AS (/* All actors who co-starred with Shahrukh Khan (Shahrukh number = 1) */ SELECT DISTINCT TRIM(c.\"PID\") AS PID FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c INNER JOIN shahrukh_movies AS sm ON TRIM(c.\"MID\") = sm.MID WHERE TRIM(c.\"PID\") <> 'nm0451321'), shahrukh_number_1_movies AS (/* All movies that Shahrukh-number-1 actors appeared in */ SELECT DISTINCT TRIM(c.\"MID\") AS MID, TRIM(c.\"PID\") AS PID FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c INNER JOIN shahrukh_number_1 AS s1 ON TRIM(c.\"PID\") = s1.PID), shahrukh_number_2 AS (/* All actors who co-starred with a Shahrukh-number-1 actor */ SELECT DISTINCT TRIM(c.\"PID\") AS PID FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c INNER JOIN shahrukh_number_1_movies AS s1m ON TRIM(c.\"MID\") = s1m.MID WHERE TRIM(c.\"PID\") <> 'nm0451321' AND TRIM(c.\"PID\") <> ALL (SELECT PID FROM shahrukh_number_1)) SELECT COUNT(*) AS SHAHRUKH_NUMBER_2_COUNT FROM shahrukh_number_2") t0
  := by first | sql_equiv | sorry

end N_sf_local100_eq_2_3
