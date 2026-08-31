import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local096_eq_2_3

CREATE TABLE MOVIE («index» INT, «MID» STRING, «title» STRING, «year» STRING, «rating» FLOAT, «num_votes» INT)
CREATE TABLE PERSON («index» INT, «PID» STRING, «Name» STRING, «Gender» STRING)
CREATE TABLE M_CAST («index» INT, «MID» STRING, «PID» STRING, «ID» INT)

theorem eq (t0 : TableRel MOVIE_schema) (t1 : TableRel PERSON_schema) (t2 : TableRel M_CAST_schema) :
    (sql%([MOVIE_schema, PERSON_schema, M_CAST_schema]) "WITH movie_year AS (SELECT \"MID\", CAST(RIGHT(\"year\", 4) AS INT) AS \"YEAR\" FROM \"DB_IMDB\".\"DB_IMDB\".\"MOVIE\"), movie_cast_gender AS (SELECT mc.\"MID\", p.\"Gender\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS mc JOIN \"DB_IMDB\".\"DB_IMDB\".\"PERSON\" AS p ON TRIM(mc.\"PID\") = TRIM(p.\"PID\")), exclusively_female AS (SELECT \"MID\" FROM movie_cast_gender GROUP BY \"MID\" HAVING SUM(CASE WHEN \"Gender\" <> 'Female' THEN 1 ELSE 0 END) = 0), yearly_stats AS (SELECT my.\"YEAR\", COUNT(DISTINCT my.\"MID\") AS \"TOTAL_MOVIES\", COUNT(DISTINCT ef.\"MID\") AS female_only_count FROM movie_year AS my LEFT JOIN exclusively_female AS ef ON my.\"MID\" = ef.\"MID\" GROUP BY my.\"YEAR\") SELECT \"YEAR\", \"TOTAL_MOVIES\", ROUND(CAST(female_only_count * 100.0 AS DOUBLE PRECISION) / \"TOTAL_MOVIES\", 2) AS \"PERCENTAGE_EXCLUSIVELY_FEMALE\" FROM yearly_stats ORDER BY \"YEAR\"") t0 t1 t2
  ~= (sql%([MOVIE_schema, PERSON_schema, M_CAST_schema]) "WITH movie_years AS (SELECT \"MID\", \"title\", CAST(RIGHT(\"year\", 4) AS INT) AS \"YEAR\" FROM \"DB_IMDB\".\"DB_IMDB\".\"MOVIE\"), movie_cast_gender AS (SELECT mc.\"MID\", p.\"Gender\" FROM \"DB_IMDB\".\"DB_IMDB\".\"M_CAST\" AS mc JOIN \"DB_IMDB\".\"DB_IMDB\".\"PERSON\" AS p ON TRIM(mc.\"PID\") = TRIM(p.\"PID\")), exclusively_female AS (SELECT my.\"MID\", my.\"YEAR\", CASE WHEN COUNT(mcg.\"Gender\") > 0 AND SUM(CASE WHEN mcg.\"Gender\" <> 'Female' THEN 1 ELSE 0 END) = 0 THEN 1 ELSE 0 END AS is_exclusively_female FROM movie_years AS my LEFT JOIN movie_cast_gender AS mcg ON my.\"MID\" = mcg.\"MID\" GROUP BY my.\"MID\", my.\"YEAR\") SELECT \"YEAR\", COUNT(*) AS \"TOTAL_MOVIES\", ROUND(CAST(CAST(100.0 * SUM(is_exclusively_female) AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 2) AS \"PERCENTAGE_EXCLUSIVELY_FEMALE\" FROM exclusively_female GROUP BY \"YEAR\" ORDER BY \"YEAR\"") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_local096_eq_2_3
