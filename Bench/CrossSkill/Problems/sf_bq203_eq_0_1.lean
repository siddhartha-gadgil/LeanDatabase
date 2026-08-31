import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq203_eq_0_1

CREATE TABLE STATIONS («station_id» STRING, «complex_id» STRING, «gtfs_stop_id» STRING, «division» STRING, «line» STRING, «station_name» STRING, «borough_name» STRING, «daytime_routes» STRING, «structure» STRING, «north_direction_label» STRING, «south_direction_label» STRING, «station_lat» FLOAT, «station_lon» FLOAT, «station_geom» STRING)
CREATE TABLE STATION_ENTRANCES («division» STRING, «line» STRING, «station_name» STRING, «station_lat» FLOAT, «station_lon» FLOAT, «route_1» STRING, «route_2» STRING, «route_3» STRING, «route_4» STRING, «route_5» STRING, «route_6» STRING, «route_7» STRING, «route_8» STRING, «route_9» STRING, «route_10» STRING, «route_11» STRING, «entrance_type» STRING, «staff» STRING, «staff_hours» STRING, «ada_notes» STRING, «free_crossover» BOOL, «north_south_street» STRING, «east_west_street» STRING, «corner» STRING, «entrance_lat» FLOAT, «entrance_lon» FLOAT, «entry» BOOL, «exit_only» BOOL, «vending» BOOL, «ada_compliant» BOOL, «station_geom» STRING, «entrance_geom» STRING)

theorem eq (t0 : TableRel STATIONS_schema) (t1 : TableRel STATION_ENTRANCES_schema) :
    (sql%([STATIONS_schema, STATION_ENTRANCES_schema]) "WITH total_stations AS (SELECT \"borough_name\", COUNT(DISTINCT \"station_lat\" || '|' || \"station_lon\") AS TOTAL_STATIONS FROM \"NEW_YORK_PLUS\".\"NEW_YORK_SUBWAY\".\"STATIONS\" GROUP BY \"borough_name\"), ada_stations AS (SELECT s.\"borough_name\", COUNT(DISTINCT s.\"station_lat\" || '|' || s.\"station_lon\") AS ADA_STATION_COUNT FROM \"NEW_YORK_PLUS\".\"NEW_YORK_SUBWAY\".\"STATIONS\" AS s JOIN \"NEW_YORK_PLUS\".\"NEW_YORK_SUBWAY\".\"STATION_ENTRANCES\" AS e ON s.\"station_name\" = e.\"station_name\" WHERE e.\"entry\" = TRUE AND e.\"ada_compliant\" = TRUE GROUP BY s.\"borough_name\") SELECT t.\"borough_name\", COALESCE(a.ADA_STATION_COUNT, 0) AS ADA_STATION_COUNT, t.TOTAL_STATIONS, ROUND(CAST(COALESCE(a.ADA_STATION_COUNT, 0) * 100.0 AS DOUBLE PRECISION) / t.TOTAL_STATIONS, 2) AS PERCENTAGE FROM total_stations AS t LEFT JOIN ada_stations AS a ON t.\"borough_name\" = a.\"borough_name\" ORDER BY PERCENTAGE DESC") t0 t1
  ~= (sql%([STATIONS_schema, STATION_ENTRANCES_schema]) "SELECT total.\"borough_name\", COALESCE(ada.\"ADA_STATION_COUNT\", 0) AS \"ADA_STATION_COUNT\", total.\"TOTAL_STATIONS\", ROUND(CAST(COALESCE(ada.\"ADA_STATION_COUNT\", 0) * 100.0 AS DOUBLE PRECISION) / total.\"TOTAL_STATIONS\", 2) AS \"PERCENTAGE\" FROM (SELECT \"borough_name\", COUNT(DISTINCT \"station_id\") AS \"TOTAL_STATIONS\" FROM \"NEW_YORK_PLUS\".\"NEW_YORK_SUBWAY\".\"STATIONS\" GROUP BY \"borough_name\") AS total LEFT JOIN (SELECT s.\"borough_name\", COUNT(DISTINCT s.\"station_id\") AS \"ADA_STATION_COUNT\" FROM \"NEW_YORK_PLUS\".\"NEW_YORK_SUBWAY\".\"STATIONS\" AS s JOIN \"NEW_YORK_PLUS\".\"NEW_YORK_SUBWAY\".\"STATION_ENTRANCES\" AS e ON s.\"station_name\" = e.\"station_name\" WHERE e.\"entry\" = TRUE AND e.\"ada_compliant\" = TRUE GROUP BY s.\"borough_name\") AS ada ON total.\"borough_name\" = ada.\"borough_name\" ORDER BY total.\"TOTAL_STATIONS\" DESC") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq203_eq_0_1
