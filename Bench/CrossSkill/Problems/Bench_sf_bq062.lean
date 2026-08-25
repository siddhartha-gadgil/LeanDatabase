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
    (sql%([PACKAGEVERSIONS_schema]) "WITH license_counts AS (SELECT \"System\", CAST(f.value AS TEXT) AS \"License\", COUNT(DISTINCT \"Name\") AS package_count FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\", LATERAL UNNEST(input => \"Licenses\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) GROUP BY \"System\", CAST(f.value AS TEXT)), ranked AS (SELECT \"System\", \"License\", package_count, ROW_NUMBER() OVER (PARTITION BY \"System\" ORDER BY package_count DESC) AS rn FROM license_counts) SELECT \"System\", \"License\" FROM ranked WHERE rn = 1 ORDER BY \"System\"") t ~= (sql%([PACKAGEVERSIONS_schema]) "WITH license_counts AS (SELECT \"System\", CAST(lic.VALUE AS TEXT) AS \"License\", COUNT(DISTINCT \"Name\") AS pkg_count FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\", LATERAL UNNEST(input => \"Licenses\") AS lic(SEQ, KEY, PATH, INDEX, VALUE, THIS) GROUP BY \"System\", CAST(lic.VALUE AS TEXT)), ranked AS (SELECT \"System\", \"License\", pkg_count, ROW_NUMBER() OVER (PARTITION BY \"System\" ORDER BY pkg_count DESC) AS rn FROM license_counts) SELECT \"System\", \"License\" FROM ranked WHERE rn = 1 ORDER BY \"System\"") t := by
  intro t; first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : PACKAGEVERSIONS "NOT \"Licenses\" IS NULL"
HYPOTHESIS hyp0_2_1 : PACKAGEVERSIONS "ARRAY_LENGTH(\"Licenses\", 1) > 0"
theorem eq_0_2 (t : TableRel PACKAGEVERSIONS_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) :
    (sql%([PACKAGEVERSIONS_schema]) "WITH license_counts AS (SELECT \"System\", CAST(f.value AS TEXT) AS \"License\", COUNT(DISTINCT \"Name\") AS package_count FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\", LATERAL UNNEST(input => \"Licenses\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) GROUP BY \"System\", CAST(f.value AS TEXT)), ranked AS (SELECT \"System\", \"License\", package_count, ROW_NUMBER() OVER (PARTITION BY \"System\" ORDER BY package_count DESC) AS rn FROM license_counts) SELECT \"System\", \"License\" FROM ranked WHERE rn = 1 ORDER BY \"System\"") t ~= (sql%([PACKAGEVERSIONS_schema]) "WITH license_counts AS (SELECT \"System\", CAST(f.VALUE AS TEXT) AS \"License\", COUNT(DISTINCT \"Name\") AS pkg_count FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\", LATERAL UNNEST(input => \"Licenses\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE NOT \"Licenses\" IS NULL AND ARRAY_LENGTH(\"Licenses\", 1) > 0 GROUP BY \"System\", CAST(f.VALUE AS TEXT)), ranked AS (SELECT \"System\", \"License\", pkg_count, ROW_NUMBER() OVER (PARTITION BY \"System\" ORDER BY pkg_count DESC) AS rn FROM license_counts) SELECT \"System\", \"License\" FROM ranked WHERE rn = 1 ORDER BY \"System\"") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : PACKAGEVERSIONS "NOT \"Licenses\" IS NULL"
HYPOTHESIS hyp1_2_1 : PACKAGEVERSIONS "ARRAY_LENGTH(\"Licenses\", 1) > 0"
theorem eq_1_2 (t : TableRel PACKAGEVERSIONS_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) :
    (sql%([PACKAGEVERSIONS_schema]) "WITH license_counts AS (SELECT \"System\", CAST(lic.VALUE AS TEXT) AS \"License\", COUNT(DISTINCT \"Name\") AS pkg_count FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\", LATERAL UNNEST(input => \"Licenses\") AS lic(SEQ, KEY, PATH, INDEX, VALUE, THIS) GROUP BY \"System\", CAST(lic.VALUE AS TEXT)), ranked AS (SELECT \"System\", \"License\", pkg_count, ROW_NUMBER() OVER (PARTITION BY \"System\" ORDER BY pkg_count DESC) AS rn FROM license_counts) SELECT \"System\", \"License\" FROM ranked WHERE rn = 1 ORDER BY \"System\"") t = (sql%([PACKAGEVERSIONS_schema]) "WITH license_counts AS (SELECT \"System\", CAST(f.VALUE AS TEXT) AS \"License\", COUNT(DISTINCT \"Name\") AS pkg_count FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\", LATERAL UNNEST(input => \"Licenses\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE NOT \"Licenses\" IS NULL AND ARRAY_LENGTH(\"Licenses\", 1) > 0 GROUP BY \"System\", CAST(f.VALUE AS TEXT)), ranked AS (SELECT \"System\", \"License\", pkg_count, ROW_NUMBER() OVER (PARTITION BY \"System\" ORDER BY pkg_count DESC) AS rn FROM license_counts) SELECT \"System\", \"License\" FROM ranked WHERE rn = 1 ORDER BY \"System\"") t := by
  first | sql_equiv | sorry

end Bench_sf_bq062
