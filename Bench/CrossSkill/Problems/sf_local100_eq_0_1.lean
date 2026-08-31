import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local100_eq_0_1

CREATE TABLE M_CAST («index» INT, «MID» STRING, «PID» STRING, «ID» INT)

theorem eq (t0 : TableRel M_CAST_schema) :
    (sql%([M_CAST_schema]) "WITH srk_movies AS (/* Movies that Shah Rukh Khan acted in */ SELECT \"MID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" WHERE \"PID\" = ' nm0451321'), srk_coactors AS (/* Shahrukh number 1: actors who directly acted with SRK */ SELECT DISTINCT mc.\"PID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS mc JOIN srk_movies AS sm ON mc.\"MID\" = sm.\"MID\" WHERE mc.\"PID\" <> ' nm0451321'), srk_number_2 AS (/* Shahrukh number 2: actors who acted with SRK's co-actors */ /* but NOT directly with SRK himself */ SELECT DISTINCT mc2.\"PID\" FROM srk_coactors AS sc JOIN \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS mc1 ON sc.\"PID\" = mc1.\"PID\" JOIN \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS mc2 ON mc1.\"MID\" = mc2.\"MID\" WHERE mc2.\"PID\" <> ALL (SELECT \"PID\" FROM srk_coactors) AND mc2.\"PID\" <> ' nm0451321') SELECT COUNT(*) AS SHAHRUKH_NUMBER_2_COUNT FROM srk_number_2") t0
  = (sql%([M_CAST_schema]) "/* Find actors with Shahrukh number 2: */ /* Actors who co-acted with someone who co-acted with Shah Rukh Khan, */ /* but did NOT co-act directly with Shah Rukh Khan themselves. */ WITH srk_movies AS (/* Movies Shah Rukh Khan appeared in */ SELECT DISTINCT \"MID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" WHERE \"PID\" = ' nm0451321'), srk_coactors AS (/* Shahrukh number 1: actors who share a movie with SRK */ SELECT DISTINCT c.\"PID\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c JOIN srk_movies AS m ON c.\"MID\" = m.\"MID\" WHERE c.\"PID\" <> ' nm0451321'), srk_num2_candidates AS (/* Actors who share a movie with any Shahrukh number 1 actor */ SELECT DISTINCT c2.\"PID\" FROM srk_coactors AS s1 JOIN \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c1 ON s1.\"PID\" = c1.\"PID\" JOIN \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c2 ON c1.\"MID\" = c2.\"MID\" WHERE c2.\"PID\" <> c1.\"PID\") SELECT COUNT(*) AS SHAHRUKH_NUMBER_2_COUNT FROM srk_num2_candidates WHERE \"PID\" <> ALL (SELECT \"PID\" FROM srk_coactors) AND \"PID\" <> ' nm0451321'") t0
  := by first | sql_equiv | sorry

end N_sf_local100_eq_0_1
