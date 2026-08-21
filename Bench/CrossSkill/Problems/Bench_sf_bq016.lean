import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq016 — crossskill equivalence(s)

Question: Considering only the highest release versions of NPM packages, which dependency (package and its version) appears most frequently among the dependencies of these packages?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq016

CREATE TABLE DEPENDENCIES («SnapshotAt» INT, «System» STRING, «Name» STRING, «Version» STRING, «Dependency» STRING, «MinimumDepth» INT)
CREATE TABLE SNAPSHOTS («Time» INT)
CREATE TABLE PACKAGEVERSIONS («SnapshotAt» INT, «System» STRING, «Name» STRING, «Version» STRING, «Licenses» STRING, «Links» STRING, «Advisories» STRING, «VersionInfo» STRING, «Hashes» STRING, «DependenciesProcessed» BOOL, «DependencyError» BOOL, «UpstreamPublishedAt» INT, «Registries» STRING, «SLSAProvenance» STRING, «UpstreamIdentifiers» STRING, «Purl» STRING)

-- eq_0_1: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_1 :
    sql%([DEPENDENCIES_schema, SNAPSHOTS_schema, PACKAGEVERSIONS_schema]) "WITH release_versions AS (\n    -- Get all NPM release versions with their ordinals\n    -- Deduplicate across snapshots by taking MAX ordinal per Name+Version\n    SELECT\n        \"Name\",\n        \"Version\",\n        MAX(\"VersionInfo\":\"Ordinal\"::INT) AS ordinal\n    FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\"\n    WHERE \"System\" = 'NPM'\n      AND \"VersionInfo\":\"IsRelease\"::BOOLEAN = TRUE\n    GROUP BY \"Name\", \"Version\"\n),\nhighest_release AS (\n    -- For each package, find the version with the highest ordinal\n    SELECT\n        \"Name\",\n        \"Version\"\n    FROM (\n        SELECT\n            \"Name\",\n            \"Version\",\n            ROW_NUMBER() OVER (PARTITION BY \"Name\" ORDER BY ordinal DESC) AS rn\n        FROM release_versions\n    )\n    WHERE rn = 1\n),\ndep_data AS (\n    -- Get distinct dependencies for the highest release versions\n    SELECT DISTINCT\n        d.\"Dependency\":\"Name\"::STRING AS dep_name,\n        d.\"Dependency\":\"Version\"::STRING AS dep_version,\n        d.\"Name\" AS source_package\n    FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"DEPENDENCIES\" d\n    INNER JOIN highest_release hr\n        ON d.\"System\" = 'NPM'\n        AND d.\"Name\" = hr.\"Name\"\n        AND d.\"Version\" = hr.\"Version\"\n)\nSELECT\n    dep_name AS DEP_NAME,\n    dep_version AS DEP_VERSION,\n    COUNT(*) AS FREQ\nFROM dep_data\nGROUP BY dep_name, dep_version\nORDER BY FREQ DESC\nLIMIT 1;" = sql%([DEPENDENCIES_schema, SNAPSHOTS_schema, PACKAGEVERSIONS_schema]) "-- For each NPM package, find the highest release version (max Ordinal where IsRelease=TRUE)\n-- from PACKAGEVERSIONS, then join to deduplicated DEPENDENCIES to get all dependency\n-- relationships, and count the most frequently appearing dependency (Name + Version).\nWITH all_releases AS (\n  SELECT DISTINCT\n    \"Name\",\n    \"Version\",\n    \"VersionInfo\":\"Ordinal\"::INT AS ordinal\n  FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\"\n  WHERE \"System\" = 'NPM'\n    AND \"VersionInfo\":\"IsRelease\"::BOOLEAN = TRUE\n),\nhighest_release AS (\n  SELECT\n    \"Name\",\n    \"Version\",\n    ROW_NUMBER() OVER (PARTITION BY \"Name\" ORDER BY ordinal DESC) AS rn\n  FROM all_releases\n),\ndeps_dedup AS (\n  SELECT DISTINCT\n    \"Name\",\n    \"Version\",\n    \"Dependency\":\"Name\"::VARCHAR AS dep_name,\n    \"Dependency\":\"Version\"::VARCHAR AS dep_version\n  FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"DEPENDENCIES\"\n  WHERE \"System\" = 'NPM'\n)\nSELECT\n  dd.dep_name AS DEP_NAME,\n  dd.dep_version AS DEP_VERSION,\n  COUNT(*) AS FREQ\nFROM highest_release hr\nJOIN deps_dedup dd\n  ON dd.\"Name\" = hr.\"Name\"\n  AND dd.\"Version\" = hr.\"Version\"\nWHERE hr.rn = 1\nGROUP BY dd.dep_name, dd.dep_version\nORDER BY FREQ DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

end Bench_sf_bq016
