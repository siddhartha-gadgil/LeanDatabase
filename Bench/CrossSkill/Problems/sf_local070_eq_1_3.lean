import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local070_eq_1_3

CREATE TABLE CITIES («city_id» INT, «city_name» STRING, «latitude» FLOAT, «longitude» FLOAT, «country_code_2» STRING, «capital» INT, «population» FLOAT, «insert_date» STRING)

theorem eq (t0 : TableRel CITIES_schema) :
    (sql%([CITIES_schema]) "WITH chinese_dates AS (/* Get distinct dates with one city per date (MIN city_id) */ SELECT \"insert_date\", MIN(\"city_id\") AS min_city_id FROM \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"CITIES\" WHERE \"country_code_2\" = 'cn' AND \"insert_date\" >= '2021-07-01' AND \"insert_date\" <= '2021-07-31' GROUP BY \"insert_date\"), city_per_date AS (/* Join back to get the city_name for the MIN city_id */ SELECT cd.\"insert_date\", c.\"city_name\" FROM chinese_dates AS cd JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"CITIES\" AS c ON cd.min_city_id = c.\"city_id\"), streaks AS (/* Gaps-and-islands: assign streak group using DATEADD */ SELECT \"insert_date\", \"city_name\", \"insert_date\" + INTERVAL '1 DAY' * -ROW_NUMBER() OVER (ORDER BY \"insert_date\") AS streak_group FROM city_per_date), streak_lengths AS (/* Compute streak length per group */ SELECT streak_group, COUNT(*) AS streak_len FROM streaks GROUP BY streak_group), shortest_longest AS (/* Find shortest and longest streak groups */ SELECT streak_group FROM streak_lengths WHERE streak_len = (SELECT MIN(streak_len) FROM streak_lengths) UNION ALL SELECT streak_group FROM streak_lengths WHERE streak_len = (SELECT MAX(streak_len) FROM streak_lengths)) SELECT s.\"insert_date\" AS MOST_CONSECUTIVE_DATES, UPPER(LEFT(s.\"city_name\", 1)) || LOWER(SUBSTRING(s.\"city_name\" FROM 2)) AS CITY_NAME FROM streaks AS s JOIN shortest_longest AS sl ON s.streak_group = sl.streak_group ORDER BY s.\"insert_date\"") t0
  ~= (sql%([CITIES_schema]) "WITH cn_dates AS (SELECT CAST(\"insert_date\" AS DATE) AS dt, MIN(\"city_id\") AS min_city_id FROM \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"CITIES\" WHERE \"country_code_2\" = 'cn' AND \"insert_date\" >= '2021-07-01' AND \"insert_date\" <= '2021-07-31' GROUP BY CAST(\"insert_date\" AS DATE)), numbered AS (SELECT dt, min_city_id, dt + INTERVAL '1 DAY' * -ROW_NUMBER() OVER (ORDER BY dt) AS grp FROM cn_dates), streaks AS (SELECT grp, MIN(dt) AS streak_start, MAX(dt) AS streak_end, COUNT(*) AS streak_len FROM numbered GROUP BY grp), min_max_streaks AS (SELECT MIN(streak_len) AS min_len, MAX(streak_len) AS max_len FROM streaks), target_streaks AS (SELECT s.* FROM streaks AS s JOIN min_max_streaks AS mm ON s.streak_len = mm.min_len OR s.streak_len = mm.max_len), target_dates AS (SELECT n.dt, n.min_city_id FROM numbered AS n JOIN target_streaks AS ts ON n.grp = ts.grp) SELECT td.dt AS \"MOST_CONSECUTIVE_DATES\", UPPER(LEFT(c.\"city_name\", 1)) || LOWER(SUBSTRING(c.\"city_name\" FROM 2)) AS \"CITY_NAME\" FROM target_dates AS td JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"CITIES\" AS c ON c.\"city_id\" = td.min_city_id ORDER BY td.dt") t0
  := by first | sql_equiv | sorry

end N_sf_local070_eq_1_3
