import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq062 — crossskill equivalence(s)

Question: What is the most frequently used license by packages in each system?

NOTE: uses WITH RECURSIVE / LATERAL / FLATTEN — may not elaborate yet.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq062

CREATE TABLE PACKAGEVERSIONS («SnapshotAt» INT, «System» STRING, «Name» STRING, «Version» STRING, «Licenses» STRING, «Links» STRING, «Advisories» STRING, «VersionInfo» STRING, «Hashes» STRING, «DependenciesProcessed» BOOL, «DependencyError» BOOL, «UpstreamPublishedAt» INT, «Registries» STRING, «SLSAProvenance» STRING, «UpstreamIdentifiers» STRING, «Purl» STRING)

theorem eq_0_1 : ∀ t,
    (sql%([PACKAGEVERSIONS_schema]) "WITH license_counts AS (\n  SELECT\n    \"System\",\n    f.value::STRING AS \"License\",\n    COUNT(DISTINCT \"Name\") AS package_count\n  FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\",\n  LATERAL FLATTEN(input => \"Licenses\") f\n  GROUP BY \"System\", f.value::STRING\n),\nranked AS (\n  SELECT\n    \"System\",\n    \"License\",\n    package_count,\n    ROW_NUMBER() OVER (PARTITION BY \"System\" ORDER BY package_count DESC) AS rn\n  FROM license_counts\n)\nSELECT \"System\", \"License\"\nFROM ranked\nWHERE rn = 1\nORDER BY \"System\";") t ~= (sql%([PACKAGEVERSIONS_schema]) "WITH license_counts AS (\n  SELECT\n    \"System\",\n    lic.VALUE::STRING AS \"License\",\n    COUNT(DISTINCT \"Name\") AS pkg_count\n  FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\",\n  LATERAL FLATTEN(input => \"Licenses\") lic\n  GROUP BY \"System\", lic.VALUE::STRING\n),\nranked AS (\n  SELECT\n    \"System\",\n    \"License\",\n    pkg_count,\n    ROW_NUMBER() OVER (PARTITION BY \"System\" ORDER BY pkg_count DESC) AS rn\n  FROM license_counts\n)\nSELECT\n  \"System\",\n  \"License\"\nFROM ranked\nWHERE rn = 1\nORDER BY \"System\";") t := by
  intro t; first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : PACKAGEVERSIONS "\"Licenses\" IS NOT NULL"
HYPOTHESIS hyp0_2_1 : PACKAGEVERSIONS "ARRAY_SIZE(\"Licenses\") > 0"
theorem eq_0_2 (t : TableRel PACKAGEVERSIONS_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) :
    (sql%([PACKAGEVERSIONS_schema]) "WITH license_counts AS (\n  SELECT\n    \"System\",\n    f.value::STRING AS \"License\",\n    COUNT(DISTINCT \"Name\") AS package_count\n  FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\",\n  LATERAL FLATTEN(input => \"Licenses\") f\n  GROUP BY \"System\", f.value::STRING\n),\nranked AS (\n  SELECT\n    \"System\",\n    \"License\",\n    package_count,\n    ROW_NUMBER() OVER (PARTITION BY \"System\" ORDER BY package_count DESC) AS rn\n  FROM license_counts\n)\nSELECT \"System\", \"License\"\nFROM ranked\nWHERE rn = 1\nORDER BY \"System\";") t ~= (sql%([PACKAGEVERSIONS_schema]) "WITH license_counts AS (\n  SELECT\n    \"System\",\n    f.VALUE::STRING AS \"License\",\n    COUNT(DISTINCT \"Name\") AS pkg_count\n  FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\",\n       LATERAL FLATTEN(input => \"Licenses\") f\n  WHERE \"Licenses\" IS NOT NULL\n    AND ARRAY_SIZE(\"Licenses\") > 0\n  GROUP BY \"System\", f.VALUE::STRING\n),\nranked AS (\n  SELECT\n    \"System\",\n    \"License\",\n    pkg_count,\n    ROW_NUMBER() OVER (PARTITION BY \"System\" ORDER BY pkg_count DESC) AS rn\n  FROM license_counts\n)\nSELECT\n  \"System\",\n  \"License\"\nFROM ranked\nWHERE rn = 1\nORDER BY \"System\";") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : PACKAGEVERSIONS "\"Licenses\" IS NOT NULL"
HYPOTHESIS hyp1_2_1 : PACKAGEVERSIONS "ARRAY_SIZE(\"Licenses\") > 0"
theorem eq_1_2 (t : TableRel PACKAGEVERSIONS_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) :
    (sql%([PACKAGEVERSIONS_schema]) "WITH license_counts AS (\n  SELECT\n    \"System\",\n    lic.VALUE::STRING AS \"License\",\n    COUNT(DISTINCT \"Name\") AS pkg_count\n  FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\",\n  LATERAL FLATTEN(input => \"Licenses\") lic\n  GROUP BY \"System\", lic.VALUE::STRING\n),\nranked AS (\n  SELECT\n    \"System\",\n    \"License\",\n    pkg_count,\n    ROW_NUMBER() OVER (PARTITION BY \"System\" ORDER BY pkg_count DESC) AS rn\n  FROM license_counts\n)\nSELECT\n  \"System\",\n  \"License\"\nFROM ranked\nWHERE rn = 1\nORDER BY \"System\";") t = (sql%([PACKAGEVERSIONS_schema]) "WITH license_counts AS (\n  SELECT\n    \"System\",\n    f.VALUE::STRING AS \"License\",\n    COUNT(DISTINCT \"Name\") AS pkg_count\n  FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\",\n       LATERAL FLATTEN(input => \"Licenses\") f\n  WHERE \"Licenses\" IS NOT NULL\n    AND ARRAY_SIZE(\"Licenses\") > 0\n  GROUP BY \"System\", f.VALUE::STRING\n),\nranked AS (\n  SELECT\n    \"System\",\n    \"License\",\n    pkg_count,\n    ROW_NUMBER() OVER (PARTITION BY \"System\" ORDER BY pkg_count DESC) AS rn\n  FROM license_counts\n)\nSELECT\n  \"System\",\n  \"License\"\nFROM ranked\nWHERE rn = 1\nORDER BY \"System\";") t := by
  first | sql_equiv | sorry

end Bench_sf_bq062
