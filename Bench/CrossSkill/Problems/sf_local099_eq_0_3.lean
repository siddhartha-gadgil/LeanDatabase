import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local099_eq_0_3

CREATE TABLE M_DIRECTOR («index» INT, «MID» STRING, «PID» STRING, «ID» INT)
CREATE TABLE M_CAST («index» INT, «MID» STRING, «PID» STRING, «ID» INT)

theorem eq (t0 : TableRel M_DIRECTOR_schema) (t1 : TableRel M_CAST_schema) :
    (sql%([M_DIRECTOR_schema, M_CAST_schema]) "WITH actor_director_counts AS (SELECT c.\"PID\" AS actor_pid, d.\"PID\" AS director_pid, COUNT(DISTINCT c.\"MID\") AS film_count FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c JOIN \"DB_IMDB\".\"DB_IMDB\".\"M_DIRECTOR\" AS d ON c.\"MID\" = d.\"MID\" GROUP BY c.\"PID\", d.\"PID\"), yc_actors AS (SELECT actor_pid, film_count AS yc_count FROM actor_director_counts WHERE director_pid = 'nm0007181'), max_other AS (SELECT actor_pid, MAX(film_count) AS max_other_count FROM actor_director_counts WHERE director_pid <> 'nm0007181' GROUP BY actor_pid) SELECT COUNT(*) AS OUTPUT FROM yc_actors AS ya LEFT JOIN max_other AS mo ON ya.actor_pid = mo.actor_pid WHERE ya.yc_count > COALESCE(mo.max_other_count, 0)") t0 t1
  = (sql%([M_DIRECTOR_schema, M_CAST_schema]) "WITH actor_director_counts AS (SELECT TRIM(c.\"PID\") AS actor_pid, TRIM(d.\"PID\") AS director_pid, COUNT(DISTINCT c.\"MID\") AS film_count FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c JOIN \"DB_IMDB\".\"DB_IMDB\".\"M_DIRECTOR\" AS d ON TRIM(c.\"MID\") = TRIM(d.\"MID\") GROUP BY TRIM(c.\"PID\"), TRIM(d.\"PID\")), yash_chopra_counts AS (SELECT actor_pid, film_count AS yc_count FROM actor_director_counts WHERE director_pid = 'nm0007181'), max_other_counts AS (SELECT actor_pid, MAX(film_count) AS max_other_count FROM actor_director_counts WHERE director_pid <> 'nm0007181' GROUP BY actor_pid) SELECT COUNT(*) AS num_actors FROM yash_chopra_counts AS yc LEFT JOIN max_other_counts AS mo ON yc.actor_pid = mo.actor_pid WHERE yc.yc_count > COALESCE(mo.max_other_count, 0)") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local099_eq_0_3
