import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local202_eq_1_3

CREATE TABLE ALIEN_DATA («id» INT, «first_name» STRING, «last_name» STRING, «email» STRING, «gender» STRING, «type» STRING, «birth_year» INT, «age» INT, «favorite_food» STRING, «feeding_frequency» STRING, «aggressive» INT, «occupation» STRING, «current_location» STRING, «state» STRING, «us_region» STRING, «country» STRING)

theorem eq (t0 : TableRel ALIEN_DATA_schema) :
    (sql%([ALIEN_DATA_schema]) "WITH top10_states AS (SELECT \"state\", COUNT(*) AS alien_population FROM \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"ALIEN_DATA\" GROUP BY \"state\" ORDER BY alien_population DESC LIMIT 10), state_stats AS (SELECT t.\"state\", CAST(SUM(CASE WHEN a.\"aggressive\" = 0 THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS pct_friendly, CAST(SUM(CASE WHEN a.\"aggressive\" = 1 THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS pct_hostile, AVG(a.\"age\") AS avg_age FROM top10_states AS t JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"ALIEN_DATA\" AS a ON t.\"state\" = a.\"state\" GROUP BY t.\"state\") SELECT COUNT(*) AS NUMBER_OF_STATES FROM state_stats WHERE pct_friendly > pct_hostile AND avg_age > 200") t0
  ~= (sql%([ALIEN_DATA_schema]) "WITH top10_states AS (SELECT \"state\", COUNT(*) AS alien_pop FROM \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"ALIEN_DATA\" GROUP BY \"state\" ORDER BY alien_pop DESC LIMIT 10), state_stats AS (SELECT t.\"state\", AVG(a.\"age\") AS avg_age, CAST(SUM(CASE WHEN a.\"aggressive\" = 0 THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS friendly_pct, CAST(SUM(CASE WHEN a.\"aggressive\" = 1 THEN 1 ELSE 0 END) * 100.0 AS DOUBLE PRECISION) / COUNT(*) AS hostile_pct FROM top10_states AS t JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"ALIEN_DATA\" AS a ON t.\"state\" = a.\"state\" GROUP BY t.\"state\") SELECT COUNT(*) AS NUM_STATES FROM state_stats WHERE friendly_pct > hostile_pct AND avg_age > 200") t0
  := by first | sql_equiv | sorry

end N_sf_local202_eq_1_3
