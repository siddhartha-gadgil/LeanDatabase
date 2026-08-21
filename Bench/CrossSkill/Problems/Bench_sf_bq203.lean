import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq203 — crossskill equivalence(s)

Question: For each New York City borough, how many subway stations are there in total, how many have at least one entrance that is marked both as an actual entry and as ADA-compliant, and what percentage of the total stations in each borough does this represent, listing boroughs from the highest to the lowest percentage?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq203

CREATE TABLE STATIONS («station_id» STRING, «complex_id» STRING, «gtfs_stop_id» STRING, «division» STRING, «line» STRING, «station_name» STRING, «borough_name» STRING, «daytime_routes» STRING, «structure» STRING, «north_direction_label» STRING, «south_direction_label» STRING, «station_lat» FLOAT, «station_lon» FLOAT, «station_geom» STRING)
CREATE TABLE STATION_ENTRANCES («division» STRING, «line» STRING, «station_name» STRING, «station_lat» FLOAT, «station_lon» FLOAT, «route_1» STRING, «route_2» STRING, «route_3» STRING, «route_4» STRING, «route_5» STRING, «route_6» STRING, «route_7» STRING, «route_8» STRING, «route_9» STRING, «route_10» STRING, «route_11» STRING, «entrance_type» STRING, «staff» STRING, «staff_hours» STRING, «ada_notes» STRING, «free_crossover» BOOL, «north_south_street» STRING, «east_west_street» STRING, «corner» STRING, «entrance_lat» FLOAT, «entrance_lon» FLOAT, «entry» BOOL, «exit_only» BOOL, «vending» BOOL, «ada_compliant» BOOL, «station_geom» STRING, «entrance_geom» STRING)

theorem eq_0_1 : ∀ t,
    (sql%([STATIONS_schema, STATION_ENTRANCES_schema]) "WITH total_stations AS (\n  SELECT \n    \"borough_name\",\n    COUNT(DISTINCT CONCAT(\"station_lat\", '|', \"station_lon\")) AS TOTAL_STATIONS\n  FROM \"NEW_YORK_PLUS\".\"NEW_YORK_SUBWAY\".\"STATIONS\"\n  GROUP BY \"borough_name\"\n),\nada_stations AS (\n  SELECT \n    s.\"borough_name\",\n    COUNT(DISTINCT CONCAT(s.\"station_lat\", '|', s.\"station_lon\")) AS ADA_STATION_COUNT\n  FROM \"NEW_YORK_PLUS\".\"NEW_YORK_SUBWAY\".\"STATIONS\" s\n  JOIN \"NEW_YORK_PLUS\".\"NEW_YORK_SUBWAY\".\"STATION_ENTRANCES\" e\n    ON s.\"station_name\" = e.\"station_name\"\n  WHERE e.\"entry\" = TRUE AND e.\"ada_compliant\" = TRUE\n  GROUP BY s.\"borough_name\"\n)\nSELECT \n  t.\"borough_name\",\n  COALESCE(a.ADA_STATION_COUNT, 0) AS ADA_STATION_COUNT,\n  t.TOTAL_STATIONS,\n  ROUND(COALESCE(a.ADA_STATION_COUNT, 0) * 100.0 / t.TOTAL_STATIONS, 2) AS PERCENTAGE\nFROM total_stations t\nLEFT JOIN ada_stations a ON t.\"borough_name\" = a.\"borough_name\"\nORDER BY PERCENTAGE DESC;") t ~= (sql%([STATIONS_schema, STATION_ENTRANCES_schema]) "SELECT\n    total.\"borough_name\",\n    COALESCE(ada.\"ADA_STATION_COUNT\", 0) AS \"ADA_STATION_COUNT\",\n    total.\"TOTAL_STATIONS\",\n    ROUND(COALESCE(ada.\"ADA_STATION_COUNT\", 0) * 100.0 / total.\"TOTAL_STATIONS\", 2) AS \"PERCENTAGE\"\nFROM (\n    SELECT \"borough_name\", COUNT(DISTINCT \"station_id\") AS \"TOTAL_STATIONS\"\n    FROM \"NEW_YORK_PLUS\".\"NEW_YORK_SUBWAY\".\"STATIONS\"\n    GROUP BY \"borough_name\"\n) total\nLEFT JOIN (\n    SELECT s.\"borough_name\", COUNT(DISTINCT s.\"station_id\") AS \"ADA_STATION_COUNT\"\n    FROM \"NEW_YORK_PLUS\".\"NEW_YORK_SUBWAY\".\"STATIONS\" s\n    JOIN \"NEW_YORK_PLUS\".\"NEW_YORK_SUBWAY\".\"STATION_ENTRANCES\" e\n        ON s.\"station_name\" = e.\"station_name\"\n    WHERE e.\"entry\" = TRUE AND e.\"ada_compliant\" = TRUE\n    GROUP BY s.\"borough_name\"\n) ada\n    ON total.\"borough_name\" = ada.\"borough_name\"\nORDER BY total.\"TOTAL_STATIONS\" DESC;") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq203
