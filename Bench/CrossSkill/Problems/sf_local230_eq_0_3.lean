import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local230_eq_0_3

CREATE TABLE GENRE («movie_id» STRING, «genre» STRING)
CREATE TABLE DIRECTOR_MAPPING («movie_id» STRING, «name_id» STRING)
CREATE TABLE NAMES («id» STRING, «name» STRING, «height» FLOAT, «date_of_birth» STRING, «known_for_movies» STRING)
CREATE TABLE RATINGS («movie_id» STRING, «avg_rating» FLOAT, «total_votes» INT, «median_rating» FLOAT)

theorem eq (t0 : TableRel GENRE_schema) (t1 : TableRel DIRECTOR_MAPPING_schema) (t2 : TableRel NAMES_schema) (t3 : TableRel RATINGS_schema) :
    (sql%([GENRE_schema, DIRECTOR_MAPPING_schema, NAMES_schema, RATINGS_schema]) "WITH top_genres AS (SELECT g.\"genre\", COUNT(DISTINCT g.\"movie_id\") AS movie_count FROM \"IMDB_MOVIES\".\"IMDB_MOVIES\".\"GENRE\" AS g JOIN \"IMDB_MOVIES\".\"IMDB_MOVIES\".\"RATINGS\" AS r ON g.\"movie_id\" = r.\"movie_id\" WHERE r.\"avg_rating\" > 8 GROUP BY g.\"genre\" ORDER BY movie_count DESC LIMIT 3), director_movies AS (SELECT n.\"name\" AS DIRECTOR, COUNT(DISTINCT dm.\"movie_id\") AS MOVIE_COUNT FROM \"IMDB_MOVIES\".\"IMDB_MOVIES\".\"DIRECTOR_MAPPING\" AS dm JOIN \"IMDB_MOVIES\".\"IMDB_MOVIES\".\"NAMES\" AS n ON dm.\"name_id\" = n.\"id\" JOIN \"IMDB_MOVIES\".\"IMDB_MOVIES\".\"GENRE\" AS g ON dm.\"movie_id\" = g.\"movie_id\" JOIN \"IMDB_MOVIES\".\"IMDB_MOVIES\".\"RATINGS\" AS r ON dm.\"movie_id\" = r.\"movie_id\" WHERE r.\"avg_rating\" > 8 AND g.\"genre\" IN (SELECT \"genre\" FROM top_genres) GROUP BY n.\"name\" ORDER BY MOVIE_COUNT DESC, DIRECTOR ASC LIMIT 4) SELECT DIRECTOR, MOVIE_COUNT FROM director_movies ORDER BY DIRECTOR ASC") t0 t1 t2 t3
  ~= (sql%([GENRE_schema, DIRECTOR_MAPPING_schema, NAMES_schema, RATINGS_schema]) "WITH top_genres AS (SELECT g.\"genre\" FROM \"IMDB_MOVIES\".\"IMDB_MOVIES\".\"GENRE\" AS g JOIN \"IMDB_MOVIES\".\"IMDB_MOVIES\".\"RATINGS\" AS r ON g.\"movie_id\" = r.\"movie_id\" WHERE r.\"avg_rating\" > 8 GROUP BY g.\"genre\" ORDER BY COUNT(*) DESC LIMIT 3), movies_in_top_genres AS (SELECT DISTINCT g.\"movie_id\" FROM \"IMDB_MOVIES\".\"IMDB_MOVIES\".\"GENRE\" AS g JOIN \"IMDB_MOVIES\".\"IMDB_MOVIES\".\"RATINGS\" AS r ON g.\"movie_id\" = r.\"movie_id\" WHERE r.\"avg_rating\" > 8 AND g.\"genre\" IN (SELECT \"genre\" FROM top_genres)) SELECT n.\"name\" AS DIRECTOR, COUNT(DISTINCT dm.\"movie_id\") AS MOVIE_COUNT FROM \"IMDB_MOVIES\".\"IMDB_MOVIES\".\"DIRECTOR_MAPPING\" AS dm JOIN movies_in_top_genres AS m ON dm.\"movie_id\" = m.\"movie_id\" JOIN \"IMDB_MOVIES\".\"IMDB_MOVIES\".\"NAMES\" AS n ON dm.\"name_id\" = n.\"id\" GROUP BY n.\"name\" ORDER BY MOVIE_COUNT DESC, n.\"name\" ASC LIMIT 4") t0 t1 t2 t3
  := by first | sql_equiv | sorry

end N_sf_local230_eq_0_3
