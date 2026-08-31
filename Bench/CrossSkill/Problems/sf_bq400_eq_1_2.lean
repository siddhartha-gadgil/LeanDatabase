import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq400_eq_1_2

CREATE TABLE STOPS («stop_id» STRING, «stop_name» STRING, «stop_lat» FLOAT, «stop_lon» FLOAT, «stop_geom» STRING)
CREATE TABLE STOP_TIMES («stop_id» INT, «trip_id» INT, «stop_sequence» INT, «arrival_time» STRING, «arrives_next_day» BOOL, «departure_time» STRING, «departs_next_day» BOOL, «dropoff_type» STRING, «exact_timepoint» BOOL)
CREATE TABLE TRIPS («trip_id» STRING, «route_id» STRING, «direction» STRING, «block_id» STRING, «service_category» STRING, «trip_headsign» STRING, «shape_id» STRING, «trip_shape» STRING)

theorem eq (t0 : TableRel STOPS_schema) (t1 : TableRel STOP_TIMES_schema) (t2 : TableRel TRIPS_schema) :
    (sql%([STOPS_schema, STOP_TIMES_schema, TRIPS_schema]) "SELECT t.\"trip_headsign\", MIN(st1.\"departure_time\") AS \"START_TIME\", MAX(st2.\"arrival_time\") AS \"END_TIME\" FROM \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_TRANSIT_MUNI\".\"STOP_TIMES\" AS st1 JOIN \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_TRANSIT_MUNI\".\"STOP_TIMES\" AS st2 ON st1.\"trip_id\" = st2.\"trip_id\" JOIN \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_TRANSIT_MUNI\".\"TRIPS\" AS t ON st1.\"trip_id\" = t.\"trip_id\" WHERE st1.\"stop_id\" = 14015 AND st2.\"stop_id\" = 16294 AND st1.\"stop_sequence\" < st2.\"stop_sequence\" GROUP BY t.\"trip_headsign\" ORDER BY t.\"trip_headsign\"") t0 t1 t2
  = (sql%([STOPS_schema, STOP_TIMES_schema, TRIPS_schema]) "SELECT t.\"trip_headsign\", MIN(st1.\"departure_time\") AS \"START_TIME\", MAX(st2.\"arrival_time\") AS \"END_TIME\" FROM \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_TRANSIT_MUNI\".\"TRIPS\" AS t JOIN \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_TRANSIT_MUNI\".\"STOP_TIMES\" AS st1 ON t.\"trip_id\" = st1.\"trip_id\" JOIN \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_TRANSIT_MUNI\".\"STOPS\" AS s1 ON st1.\"stop_id\" = s1.\"stop_id\" AND s1.\"stop_name\" = 'Clay St & Drumm St' JOIN \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_TRANSIT_MUNI\".\"STOP_TIMES\" AS st2 ON t.\"trip_id\" = st2.\"trip_id\" JOIN \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_TRANSIT_MUNI\".\"STOPS\" AS s2 ON st2.\"stop_id\" = s2.\"stop_id\" AND s2.\"stop_name\" = 'Sacramento St & Davis St' WHERE st1.\"stop_sequence\" < st2.\"stop_sequence\" GROUP BY t.\"trip_headsign\"") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_bq400_eq_1_2
