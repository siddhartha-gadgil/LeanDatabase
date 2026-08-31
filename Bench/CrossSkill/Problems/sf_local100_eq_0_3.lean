import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local100_eq_0_3

CREATE TABLE M_CAST («index» INT, «MID» STRING, «PID» STRING, «ID» INT)

theorem eq (t0 : TableRel M_CAST_schema) :
    (sql%([M_CAST_schema]) "WITH srk_movies AS (/* Movies that Shah Rukh Khan acted in */ SELECT \"MID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" WHERE \"PID\" = ' nm0451321'), srk_coactors AS (/* Shahrukh number 1: actors who directly acted with SRK */ SELECT DISTINCT mc.\"PID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS mc JOIN srk_movies AS sm ON mc.\"MID\" = sm.\"MID\" WHERE mc.\"PID\" <> ' nm0451321'), srk_number_2 AS (/* Shahrukh number 2: actors who acted with SRK's co-actors */ /* but NOT directly with SRK himself */ SELECT DISTINCT mc2.\"PID\" FROM srk_coactors AS sc JOIN \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS mc1 ON sc.\"PID\" = mc1.\"PID\" JOIN \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS mc2 ON mc1.\"MID\" = mc2.\"MID\" WHERE mc2.\"PID\" <> ALL (SELECT \"PID\" FROM srk_coactors) AND mc2.\"PID\" <> ' nm0451321') SELECT COUNT(*) AS SHAHRUKH_NUMBER_2_COUNT FROM srk_number_2") t0
  = (sql%([M_CAST_schema]) "/* Find count of actors with Shahrukh number = 2 */ /* Shahrukh number 1: actors who co-starred in a movie with Shahrukh Khan */ /* Shahrukh number 2: actors who co-starred with a Shahrukh-number-1 actor but NOT directly with Shahrukh Khan */ WITH shahrukh_movies AS (/* All movies Shahrukh Khan appeared in */ SELECT DISTINCT TRIM(\"MID\") AS MID FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" WHERE TRIM(\"PID\") = 'nm0451321'), shahrukh_number_1 AS (/* All actors who co-starred with Shahrukh Khan (Shahrukh number = 1) */ SELECT DISTINCT TRIM(c.\"PID\") AS PID FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c INNER JOIN shahrukh_movies AS sm ON TRIM(c.\"MID\") = sm.MID WHERE TRIM(c.\"PID\") <> 'nm0451321'), shahrukh_number_1_movies AS (/* All movies that Shahrukh-number-1 actors appeared in */ SELECT DISTINCT TRIM(c.\"MID\") AS MID, TRIM(c.\"PID\") AS PID FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c INNER JOIN shahrukh_number_1 AS s1 ON TRIM(c.\"PID\") = s1.PID), shahrukh_number_2 AS (/* All actors who co-starred with a Shahrukh-number-1 actor */ SELECT DISTINCT TRIM(c.\"PID\") AS PID FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c INNER JOIN shahrukh_number_1_movies AS s1m ON TRIM(c.\"MID\") = s1m.MID WHERE TRIM(c.\"PID\") <> 'nm0451321' AND TRIM(c.\"PID\") <> ALL (SELECT PID FROM shahrukh_number_1)) SELECT COUNT(*) AS SHAHRUKH_NUMBER_2_COUNT FROM shahrukh_number_2") t0
  := by first | sql_equiv | sorry

end N_sf_local100_eq_0_3
