import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq348 — crossskill equivalence(s)

Question: Within the rectangular area defined by the geogpoints (31.1798246, 18.4519921), (54.3798246, 18.4519921), (54.3798246, 33.6519921), and (31.1798246, 33.6519921), which are the top three usernames responsible for the highest number of historical nodes, originally tagged with the amenities ‘hospital’, ‘clinic’, or ‘doctors’, that do not appear anymore in the current planet_nodes dataset?

NOTE: uses WITH RECURSIVE / LATERAL / FLATTEN — may not elaborate yet.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq348

CREATE TABLE HISTORY_NODES («id» INT, «version» INT, «username» STRING, «changeset» INT, «visible» BOOL, «osm_timestamp» INT, «geometry» STRING, «all_tags» STRING, «latitude» INT, «longitude» INT)
CREATE TABLE PLANET_NODES («id» INT, «version» INT, «username» STRING, «changeset» INT, «visible» BOOL, «osm_timestamp» INT, «geometry» STRING, «all_tags» STRING, «latitude» INT, «longitude» INT)

theorem eq_0_1 :
    sql%([HISTORY_NODES_schema, PLANET_NODES_schema]) "WITH amenity_history AS (\n  SELECT\n    h.\"id\",\n    h.\"username\",\n    h.\"version\",\n    ROW_NUMBER() OVER (PARTITION BY h.\"id\" ORDER BY h.\"version\" ASC) AS rn\n  FROM \"GEO_OPENSTREETMAP\".\"GEO_OPENSTREETMAP\".\"HISTORY_NODES\" h,\n       LATERAL FLATTEN(input => h.\"all_tags\") t\n  WHERE t.value:\"key\"::STRING = 'amenity'\n    AND t.value:\"value\"::STRING IN ('hospital', 'clinic', 'doctors')\n    AND h.\"latitude\" BETWEEN 31.1798246 AND 54.3798246\n    AND h.\"longitude\" BETWEEN 18.0 AND 33.6519921\n    AND NOT EXISTS (\n      SELECT 1\n      FROM \"GEO_OPENSTREETMAP\".\"GEO_OPENSTREETMAP\".\"PLANET_NODES\" p\n      WHERE p.\"id\" = h.\"id\"\n    )\n)\nSELECT\n  \"username\",\n  COUNT(*) AS NODE_COUNT\nFROM amenity_history\nWHERE rn = 1\nGROUP BY \"username\"\nORDER BY NODE_COUNT DESC\nLIMIT 3;" = sql%([HISTORY_NODES_schema, PLANET_NODES_schema]) "WITH amenity_versions AS (\n    SELECT h.\"id\", h.\"username\", h.\"version\",\n           ROW_NUMBER() OVER (PARTITION BY h.\"id\" ORDER BY h.\"version\" ASC) as rn\n    FROM \"GEO_OPENSTREETMAP\".\"GEO_OPENSTREETMAP\".\"HISTORY_NODES\" h,\n         LATERAL FLATTEN(input => h.\"all_tags\") t\n    WHERE h.\"latitude\" BETWEEN 31.1798246 AND 54.3798246\n      AND h.\"longitude\" BETWEEN 18.4519921 AND 33.6519921\n      AND t.value:key::STRING = 'amenity'\n      AND t.value:value::STRING IN ('hospital', 'clinic', 'doctors')\n),\nfirst_amenity AS (\n    SELECT \"id\", \"username\"\n    FROM amenity_versions\n    WHERE rn = 1\n),\nremoved_nodes AS (\n    SELECT fa.\"id\", fa.\"username\"\n    FROM first_amenity fa\n    WHERE fa.\"id\" NOT IN (\n        SELECT p.\"id\"\n        FROM \"GEO_OPENSTREETMAP\".\"GEO_OPENSTREETMAP\".\"PLANET_NODES\" p\n    )\n)\nSELECT \"username\",\n       COUNT(*) AS \"NODE_COUNT\"\nFROM removed_nodes\nGROUP BY \"username\"\nORDER BY \"NODE_COUNT\" DESC\nLIMIT 3;" := by
  first | sql_equiv | sorry

end Bench_sf_bq348
