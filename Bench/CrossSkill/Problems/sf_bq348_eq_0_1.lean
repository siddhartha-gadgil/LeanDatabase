import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq348_eq_0_1

CREATE TABLE HISTORY_NODES («id» INT, «version» INT, «username» STRING, «changeset» INT, «visible» BOOL, «osm_timestamp» INT, «geometry» STRING, «all_tags» STRING, «latitude» INT, «longitude» INT)
CREATE TABLE PLANET_NODES («id» INT, «version» INT, «username» STRING, «changeset» INT, «visible» BOOL, «osm_timestamp» INT, «geometry» STRING, «all_tags» STRING, «latitude» INT, «longitude» INT)

theorem eq (t0 : TableRel HISTORY_NODES_schema) (t1 : TableRel PLANET_NODES_schema) :
    (sql%([HISTORY_NODES_schema, PLANET_NODES_schema]) "WITH amenity_history AS (SELECT h.\"id\", h.\"username\", h.\"version\", ROW_NUMBER() OVER (PARTITION BY h.\"id\" ORDER BY h.\"version\" ASC) AS rn FROM \"GEO_OPENSTREETMAP\".\"GEO_OPENSTREETMAP\".\"HISTORY_NODES\" AS h, LATERAL UNNEST(input => h.\"all_tags\") AS t(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(t.value, 'key') AS TEXT) = 'amenity' AND CAST(JSON_EXTRACT_PATH(t.value, 'value') AS TEXT) IN ('hospital', 'clinic', 'doctors') AND h.\"latitude\" BETWEEN 31.1798246 AND 54.3798246 AND h.\"longitude\" BETWEEN 18.0 AND 33.6519921 AND NOT EXISTS(SELECT 1 FROM \"GEO_OPENSTREETMAP\".\"GEO_OPENSTREETMAP\".\"PLANET_NODES\" AS p WHERE p.\"id\" = h.\"id\")) SELECT \"username\", COUNT(*) AS NODE_COUNT FROM amenity_history WHERE rn = 1 GROUP BY \"username\" ORDER BY NODE_COUNT DESC LIMIT 3") t0 t1
  = (sql%([HISTORY_NODES_schema, PLANET_NODES_schema]) "WITH amenity_versions AS (SELECT h.\"id\", h.\"username\", h.\"version\", ROW_NUMBER() OVER (PARTITION BY h.\"id\" ORDER BY h.\"version\" ASC) AS rn FROM \"GEO_OPENSTREETMAP\".\"GEO_OPENSTREETMAP\".\"HISTORY_NODES\" AS h, LATERAL UNNEST(input => h.\"all_tags\") AS t(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE h.\"latitude\" BETWEEN 31.1798246 AND 54.3798246 AND h.\"longitude\" BETWEEN 18.4519921 AND 33.6519921 AND CAST(JSON_EXTRACT_PATH(t.value, 'key') AS TEXT) = 'amenity' AND CAST(JSON_EXTRACT_PATH(t.value, 'value') AS TEXT) IN ('hospital', 'clinic', 'doctors')), first_amenity AS (SELECT \"id\", \"username\" FROM amenity_versions WHERE rn = 1), removed_nodes AS (SELECT fa.\"id\", fa.\"username\" FROM first_amenity AS fa WHERE fa.\"id\" <> ALL (SELECT p.\"id\" FROM \"GEO_OPENSTREETMAP\".\"GEO_OPENSTREETMAP\".\"PLANET_NODES\" AS p)) SELECT \"username\", COUNT(*) AS \"NODE_COUNT\" FROM removed_nodes GROUP BY \"username\" ORDER BY \"NODE_COUNT\" DESC LIMIT 3") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq348_eq_0_1
