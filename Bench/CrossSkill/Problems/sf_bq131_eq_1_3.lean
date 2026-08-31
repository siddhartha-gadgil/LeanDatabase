import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq131_eq_1_3

CREATE TABLE PLANET_FEATURES («feature_type» STRING, «osm_id» INT, «osm_way_id» INT, «osm_version» INT, «osm_timestamp» INT, «all_tags» STRING, «geometry» STRING)
CREATE TABLE PLANET_FEATURES_POINTS («osm_id» INT, «osm_version» INT, «osm_way_id» INT, «osm_timestamp» INT, «geometry» STRING, «all_tags» STRING)

theorem eq (t0 : TableRel PLANET_FEATURES_schema) (t1 : TableRel PLANET_FEATURES_POINTS_schema) :
    (sql%([PLANET_FEATURES_schema, PLANET_FEATURES_POINTS_schema]) "WITH denmark AS (SELECT CAST(\"geometry\" AS GEOGRAPHY) AS geo FROM \"GEO_OPENSTREETMAP\".\"GEO_OPENSTREETMAP\".\"PLANET_FEATURES\" WHERE \"osm_id\" = 50046), bus_stops_with_network AS (SELECT bs.\"osm_id\", CAST(JSON_EXTRACT_PATH(nw.value, 'value') AS TEXT) AS network FROM \"GEO_OPENSTREETMAP\".\"GEO_OPENSTREETMAP\".\"PLANET_FEATURES_POINTS\" AS bs, denmark AS dk, LATERAL UNNEST(input => bs.\"all_tags\") AS nw(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(bs.\"all_tags\" AS VARCHAR) LIKE '%bus_stop%' AND CAST(bs.\"all_tags\" AS VARCHAR) LIKE '%highway%' AND CAST(bs.\"all_tags\" AS VARCHAR) LIKE '%\"network\"%' AND CAST(JSON_EXTRACT_PATH(nw.value, 'key') AS TEXT) = 'network' AND ST_DWITHIN(CAST(bs.\"geometry\" AS GEOGRAPHY), dk.geo, 0)) SELECT network, COUNT(DISTINCT \"osm_id\") AS bus_stop_count FROM bus_stops_with_network GROUP BY network ORDER BY bus_stop_count DESC") t0 t1
  ~= (sql%([PLANET_FEATURES_schema, PLANET_FEATURES_POINTS_schema]) "WITH denmark AS (SELECT CAST(\"geometry\" AS GEOGRAPHY) AS geog FROM \"GEO_OPENSTREETMAP\".\"GEO_OPENSTREETMAP\".\"PLANET_FEATURES\" WHERE \"feature_type\" = 'multipolygons' AND \"osm_id\" = 50046), bus_stops AS (SELECT p.\"osm_id\", p.\"geometry\", p.\"all_tags\" FROM \"GEO_OPENSTREETMAP\".\"GEO_OPENSTREETMAP\".\"PLANET_FEATURES_POINTS\" AS p, LATERAL UNNEST(input => p.\"all_tags\") AS t(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(t.value, 'key') AS TEXT) = 'highway' AND CAST(JSON_EXTRACT_PATH(t.value, 'value') AS TEXT) = 'bus_stop'), bus_stops_in_denmark AS (SELECT bs.\"osm_id\", bs.\"all_tags\" FROM bus_stops AS bs, denmark AS dk WHERE ST_WITHIN(CAST(bs.\"geometry\" AS GEOGRAPHY), dk.geog)), bus_networks AS (SELECT CAST(JSON_EXTRACT_PATH(t.value, 'value') AS TEXT) AS network, bsd.\"osm_id\" FROM bus_stops_in_denmark AS bsd, LATERAL UNNEST(input => bsd.\"all_tags\") AS t(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(t.value, 'key') AS TEXT) = 'network') SELECT network, COUNT(*) AS bus_stop_count FROM bus_networks GROUP BY network ORDER BY bus_stop_count DESC") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq131_eq_1_3
