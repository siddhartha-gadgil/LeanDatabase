import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local099_eq_1_2

CREATE TABLE M_DIRECTOR («index» INT, «MID» STRING, «PID» STRING, «ID» INT)
CREATE TABLE M_CAST («index» INT, «MID» STRING, «PID» STRING, «ID» INT)

theorem eq (t0 : TableRel M_DIRECTOR_schema) (t1 : TableRel M_CAST_schema) :
    (sql%([M_DIRECTOR_schema, M_CAST_schema]) "WITH actor_director_counts AS (SELECT TRIM(c.\"PID\") AS actor_pid, TRIM(d.\"PID\") AS director_pid, COUNT(DISTINCT c.\"MID\") AS num_films FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c JOIN \"DB_IMDB\".\"DB_IMDB\".\"M_DIRECTOR\" AS d ON c.\"MID\" = d.\"MID\" GROUP BY TRIM(c.\"PID\"), TRIM(d.\"PID\")), actor_yc AS (SELECT actor_pid, num_films AS yc_films FROM actor_director_counts WHERE director_pid = 'nm0007181'), actor_max_other AS (SELECT actor_pid, MAX(num_films) AS max_other_films FROM actor_director_counts WHERE director_pid <> 'nm0007181' GROUP BY actor_pid) SELECT COUNT(*) AS OUTPUT FROM actor_yc AS yc LEFT JOIN actor_max_other AS mo ON yc.actor_pid = mo.actor_pid WHERE yc.yc_films > COALESCE(mo.max_other_films, 0)") t0 t1
  ~= (sql%([M_DIRECTOR_schema, M_CAST_schema]) "/* How many actors have made more films with Yash Chopra than with any other director? */ /* For each actor, count films with each director. */ /* An actor qualifies if their count with Yash Chopra is strictly greater than their count with any other single director. */ WITH actor_director_counts AS (/* Count the number of films each actor has worked with each director */ SELECT c.\"PID\" AS actor_pid, d.\"PID\" AS director_pid, COUNT(DISTINCT c.\"MID\") AS film_count FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c JOIN \"DB_IMDB\".\"DB_IMDB\".\"M_DIRECTOR\" AS d ON c.\"MID\" = d.\"MID\" GROUP BY c.\"PID\", d.\"PID\"), yash_chopra_counts AS (/* Films each actor made with Yash Chopra */ SELECT actor_pid, film_count AS yc_count FROM actor_director_counts WHERE director_pid = 'nm0007181'), max_other_counts AS (/* Max films each actor made with any other director */ SELECT actor_pid, MAX(film_count) AS max_other_count FROM actor_director_counts WHERE director_pid <> 'nm0007181' GROUP BY actor_pid) SELECT COUNT(*) AS \"OUTPUT\" FROM yash_chopra_counts AS yc LEFT JOIN max_other_counts AS mo ON yc.actor_pid = mo.actor_pid WHERE yc.yc_count > COALESCE(mo.max_other_count, 0)") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local099_eq_1_2
