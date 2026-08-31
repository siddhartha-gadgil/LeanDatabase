import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local098_eq_0_1

CREATE TABLE MOVIE («index» INT, «MID» STRING, «title» STRING, «year» STRING, «rating» FLOAT, «num_votes» INT)
CREATE TABLE M_CAST («index» INT, «MID» STRING, «PID» STRING, «ID» INT)

theorem eq (t0 : TableRel MOVIE_schema) (t1 : TableRel M_CAST_schema) :
    (sql%([MOVIE_schema, M_CAST_schema]) "WITH actor_years AS (SELECT c.\"PID\", CAST(REGEXP_EXTRACT(m.\"year\", '\\d{4}', 0) AS INT) AS yr FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS c JOIN \"DB_IMDB\".\"DB_IMDB\".\"MOVIE\" AS m ON c.\"MID\" = m.\"MID\" WHERE NOT CAST(REGEXP_EXTRACT(m.\"year\", '\\d{4}', 0) AS INT) IS NULL GROUP BY c.\"PID\", CAST(REGEXP_EXTRACT(m.\"year\", '\\d{4}', 0) AS INT)), gaps AS (SELECT \"PID\", yr, yr - LAG(yr) OVER (PARTITION BY \"PID\" ORDER BY yr) AS diff FROM actor_years), max_gaps AS (SELECT \"PID\", MAX(diff) AS max_diff FROM gaps GROUP BY \"PID\") SELECT COUNT(*) AS ACTOR_COUNT_NO_4YR_GAP FROM max_gaps WHERE max_diff <= 4 OR max_diff IS NULL") t0 t1
  = (sql%([MOVIE_schema, M_CAST_schema]) "WITH actor_years AS (SELECT TRIM(mc.\"PID\") AS pid, CAST(REGEXP_EXTRACT(m.\"year\", '\\d{4}', 0) AS INT) AS yr FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS mc JOIN \"DB_IMDB\".\"DB_IMDB\".\"MOVIE\" AS m ON mc.\"MID\" = m.\"MID\" WHERE NOT REGEXP_EXTRACT(m.\"year\", '\\d{4}', 0) IS NULL GROUP BY TRIM(mc.\"PID\"), CAST(REGEXP_EXTRACT(m.\"year\", '\\d{4}', 0) AS INT)), actor_gaps AS (SELECT pid, yr, yr - LAG(yr) OVER (PARTITION BY pid ORDER BY yr) AS gap FROM actor_years), actor_max_gap AS (SELECT pid, MAX(gap) AS max_gap FROM actor_gaps GROUP BY pid) SELECT COUNT(*) AS \"ACTOR_COUNT_NO_4YR_GAP\" FROM actor_max_gap WHERE max_gap <= 4 OR max_gap IS NULL") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local098_eq_0_1
