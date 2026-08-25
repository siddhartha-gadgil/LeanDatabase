import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq096 — crossskill equivalence(s)

Question: Determine which year had the earliest date after January on which more than 10 sightings of Sterna paradisaea were recorded north of 40 degrees latitude. For each year, find the first day after January with over 10 sightings of this species in that region, and identify the year whose earliest such date is the earliest among all years.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq096

CREATE TABLE OCCURRENCES («gbifid» STRING, «datasetkey» STRING, «occurrenceid» STRING, «kingdom» STRING, «phylum» STRING, «class» STRING, «order» STRING, «family» STRING, «genus» STRING, «species» STRING, «infraspecificepithet» STRING, «taxonrank» STRING, «scientificname» STRING, «verbatimscientificname» STRING, «verbatimscientificnameauthorship» STRING, «countrycode» STRING, «locality» STRING, «stateprovince» STRING, «occurrencestatus» STRING, «individualcount» INT, «publishingorgkey» STRING, «decimallatitude» FLOAT, «decimallongitude» FLOAT, «coordinateuncertaintyinmeters» FLOAT, «coordinateprecision» FLOAT, «elevation» FLOAT, «elevationaccuracy» FLOAT, «depth» FLOAT, «depthaccuracy» FLOAT, «eventdate» INT, «day» INT, «month» INT, «year» INT, «taxonkey» INT, «specieskey» INT, «basisofrecord» STRING, «institutioncode» STRING, «collectioncode» STRING, «catalognumber» STRING, «recordnumber» STRING, «identifiedby» STRING, «dateidentified» INT, «license» STRING, «rightsholder» STRING, «recordedby» STRING, «typestatus» STRING, «establishmentmeans» STRING, «lastinterpreted» INT, «mediatype» STRING, «issue» STRING)

HYPOTHESIS hyp0_1_0 : OCCURRENCES "\"month\" >= 2"
HYPOTHESIS hyp0_1_1 : OCCURRENCES "\"month\" > 1"
theorem eq_0_1 (t : TableRel OCCURRENCES_schema) (h0 : hyp0_1_0 t) (h1 : hyp0_1_1 t) :
    (sql%([OCCURRENCES_schema]) "WITH daily_counts AS (SELECT \"year\", \"month\", \"day\", COUNT(*) AS daily_sightings FROM \"GBIF\".\"GBIF\".\"OCCURRENCES\" WHERE \"species\" = 'Sterna paradisaea' AND \"decimallatitude\" > 40 AND \"month\" >= 2 AND NOT \"year\" IS NULL AND NOT \"month\" IS NULL AND NOT \"day\" IS NULL GROUP BY \"year\", \"month\", \"day\" HAVING COUNT(*) > 10), earliest_per_year AS (SELECT \"year\", MIN(DATE_FROM_PARTS(\"year\", \"month\", \"day\")) AS earliest_date FROM daily_counts GROUP BY \"year\") SELECT \"year\" AS OUTPUT FROM earliest_per_year ORDER BY DAY_OF_YEAR(earliest_date) LIMIT 1") t ~= (sql%([OCCURRENCES_schema]) "WITH daily_counts AS (SELECT \"year\", \"month\", \"day\", COUNT(*) AS cnt FROM \"GBIF\".\"GBIF\".\"OCCURRENCES\" WHERE \"species\" = 'Sterna paradisaea' AND \"decimallatitude\" > 40 AND \"month\" > 1 AND NOT \"year\" IS NULL AND NOT \"month\" IS NULL AND NOT \"day\" IS NULL GROUP BY \"year\", \"month\", \"day\" HAVING COUNT(*) > 10), earliest_per_year AS (SELECT \"year\", MIN(\"month\" * 100 + \"day\") AS earliest_md FROM daily_counts GROUP BY \"year\") SELECT \"year\" AS OUTPUT FROM earliest_per_year ORDER BY earliest_md ASC LIMIT 1") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : OCCURRENCES "\"month\" >= 2"
HYPOTHESIS hyp0_2_1 : OCCURRENCES "\"month\" > 1"
theorem eq_0_2 (t : TableRel OCCURRENCES_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) :
    (sql%([OCCURRENCES_schema]) "WITH daily_counts AS (SELECT \"year\", \"month\", \"day\", COUNT(*) AS daily_sightings FROM \"GBIF\".\"GBIF\".\"OCCURRENCES\" WHERE \"species\" = 'Sterna paradisaea' AND \"decimallatitude\" > 40 AND \"month\" >= 2 AND NOT \"year\" IS NULL AND NOT \"month\" IS NULL AND NOT \"day\" IS NULL GROUP BY \"year\", \"month\", \"day\" HAVING COUNT(*) > 10), earliest_per_year AS (SELECT \"year\", MIN(DATE_FROM_PARTS(\"year\", \"month\", \"day\")) AS earliest_date FROM daily_counts GROUP BY \"year\") SELECT \"year\" AS OUTPUT FROM earliest_per_year ORDER BY DAY_OF_YEAR(earliest_date) LIMIT 1") t ~= (sql%([OCCURRENCES_schema]) "WITH daily_counts AS (SELECT \"year\", \"month\", \"day\", COUNT(*) AS sightings FROM \"GBIF\".\"GBIF\".\"OCCURRENCES\" WHERE \"species\" = 'Sterna paradisaea' AND \"decimallatitude\" > 40 AND \"month\" > 1 AND NOT \"year\" IS NULL AND NOT \"month\" IS NULL AND NOT \"day\" IS NULL GROUP BY \"year\", \"month\", \"day\" HAVING COUNT(*) > 10), earliest_per_year AS (SELECT \"year\", MIN(\"month\" * 100 + \"day\") AS earliest_date_key FROM daily_counts GROUP BY \"year\") SELECT \"year\" AS \"OUTPUT\" FROM earliest_per_year ORDER BY earliest_date_key ASC LIMIT 1") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_3_0 : OCCURRENCES "\"species\" = 'Sterna paradisaea'"
HYPOTHESIS hyp0_3_1 : OCCURRENCES "\"decimallatitude\" > 40"
HYPOTHESIS hyp0_3_2 : OCCURRENCES "\"month\" >= 2"
HYPOTHESIS hyp0_3_3 : OCCURRENCES "NOT \"year\" IS NULL"
HYPOTHESIS hyp0_3_4 : OCCURRENCES "NOT \"month\" IS NULL"
HYPOTHESIS hyp0_3_5 : OCCURRENCES "NOT \"day\" IS NULL"
theorem eq_0_3 (t : TableRel OCCURRENCES_schema) (h0 : hyp0_3_0 t) (h1 : hyp0_3_1 t) (h2 : hyp0_3_2 t) (h3 : hyp0_3_3 t) (h4 : hyp0_3_4 t) (h5 : hyp0_3_5 t) :
    (sql%([OCCURRENCES_schema]) "WITH daily_counts AS (SELECT \"year\", \"month\", \"day\", COUNT(*) AS daily_sightings FROM \"GBIF\".\"GBIF\".\"OCCURRENCES\" WHERE \"species\" = 'Sterna paradisaea' AND \"decimallatitude\" > 40 AND \"month\" >= 2 AND NOT \"year\" IS NULL AND NOT \"month\" IS NULL AND NOT \"day\" IS NULL GROUP BY \"year\", \"month\", \"day\" HAVING COUNT(*) > 10), earliest_per_year AS (SELECT \"year\", MIN(DATE_FROM_PARTS(\"year\", \"month\", \"day\")) AS earliest_date FROM daily_counts GROUP BY \"year\") SELECT \"year\" AS OUTPUT FROM earliest_per_year ORDER BY DAY_OF_YEAR(earliest_date) LIMIT 1") t ~= (sql%([OCCURRENCES_schema]) "/* For each year, find the first date after January where more than 10 sightings */ /* of Sterna paradisaea were recorded north of 40° latitude. */ /* Return the year with the overall earliest such date. */ WITH daily_counts AS (SELECT \"year\", \"month\", \"day\", COUNT(*) AS sighting_count FROM \"GBIF\".\"GBIF\".\"OCCURRENCES\" WHERE \"species\" = 'Sterna paradisaea' AND \"decimallatitude\" > 40 AND \"month\" > 1 GROUP BY \"year\", \"month\", \"day\" HAVING COUNT(*) > 10), earliest_per_year AS (SELECT \"year\", MIN(\"month\" * 100 + \"day\") AS earliest_date_key FROM daily_counts GROUP BY \"year\") SELECT \"year\" AS OUTPUT FROM earliest_per_year ORDER BY earliest_date_key ASC LIMIT 1") t := by
  first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([OCCURRENCES_schema]) "WITH daily_counts AS (SELECT \"year\", \"month\", \"day\", COUNT(*) AS cnt FROM \"GBIF\".\"GBIF\".\"OCCURRENCES\" WHERE \"species\" = 'Sterna paradisaea' AND \"decimallatitude\" > 40 AND \"month\" > 1 AND NOT \"year\" IS NULL AND NOT \"month\" IS NULL AND NOT \"day\" IS NULL GROUP BY \"year\", \"month\", \"day\" HAVING COUNT(*) > 10), earliest_per_year AS (SELECT \"year\", MIN(\"month\" * 100 + \"day\") AS earliest_md FROM daily_counts GROUP BY \"year\") SELECT \"year\" AS OUTPUT FROM earliest_per_year ORDER BY earliest_md ASC LIMIT 1") t ~= (sql%([OCCURRENCES_schema]) "WITH daily_counts AS (SELECT \"year\", \"month\", \"day\", COUNT(*) AS sightings FROM \"GBIF\".\"GBIF\".\"OCCURRENCES\" WHERE \"species\" = 'Sterna paradisaea' AND \"decimallatitude\" > 40 AND \"month\" > 1 AND NOT \"year\" IS NULL AND NOT \"month\" IS NULL AND NOT \"day\" IS NULL GROUP BY \"year\", \"month\", \"day\" HAVING COUNT(*) > 10), earliest_per_year AS (SELECT \"year\", MIN(\"month\" * 100 + \"day\") AS earliest_date_key FROM daily_counts GROUP BY \"year\") SELECT \"year\" AS \"OUTPUT\" FROM earliest_per_year ORDER BY earliest_date_key ASC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : OCCURRENCES "\"species\" = 'Sterna paradisaea'"
HYPOTHESIS hyp1_3_1 : OCCURRENCES "\"decimallatitude\" > 40"
HYPOTHESIS hyp1_3_2 : OCCURRENCES "\"month\" > 1"
HYPOTHESIS hyp1_3_3 : OCCURRENCES "NOT \"year\" IS NULL"
HYPOTHESIS hyp1_3_4 : OCCURRENCES "NOT \"month\" IS NULL"
HYPOTHESIS hyp1_3_5 : OCCURRENCES "NOT \"day\" IS NULL"
theorem eq_1_3 (t : TableRel OCCURRENCES_schema) (h0 : hyp1_3_0 t) (h1 : hyp1_3_1 t) (h2 : hyp1_3_2 t) (h3 : hyp1_3_3 t) (h4 : hyp1_3_4 t) (h5 : hyp1_3_5 t) :
    (sql%([OCCURRENCES_schema]) "WITH daily_counts AS (SELECT \"year\", \"month\", \"day\", COUNT(*) AS cnt FROM \"GBIF\".\"GBIF\".\"OCCURRENCES\" WHERE \"species\" = 'Sterna paradisaea' AND \"decimallatitude\" > 40 AND \"month\" > 1 AND NOT \"year\" IS NULL AND NOT \"month\" IS NULL AND NOT \"day\" IS NULL GROUP BY \"year\", \"month\", \"day\" HAVING COUNT(*) > 10), earliest_per_year AS (SELECT \"year\", MIN(\"month\" * 100 + \"day\") AS earliest_md FROM daily_counts GROUP BY \"year\") SELECT \"year\" AS OUTPUT FROM earliest_per_year ORDER BY earliest_md ASC LIMIT 1") t ~= (sql%([OCCURRENCES_schema]) "/* For each year, find the first date after January where more than 10 sightings */ /* of Sterna paradisaea were recorded north of 40° latitude. */ /* Return the year with the overall earliest such date. */ WITH daily_counts AS (SELECT \"year\", \"month\", \"day\", COUNT(*) AS sighting_count FROM \"GBIF\".\"GBIF\".\"OCCURRENCES\" WHERE \"species\" = 'Sterna paradisaea' AND \"decimallatitude\" > 40 AND \"month\" > 1 GROUP BY \"year\", \"month\", \"day\" HAVING COUNT(*) > 10), earliest_per_year AS (SELECT \"year\", MIN(\"month\" * 100 + \"day\") AS earliest_date_key FROM daily_counts GROUP BY \"year\") SELECT \"year\" AS OUTPUT FROM earliest_per_year ORDER BY earliest_date_key ASC LIMIT 1") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : OCCURRENCES "\"species\" = 'Sterna paradisaea'"
HYPOTHESIS hyp2_3_1 : OCCURRENCES "\"decimallatitude\" > 40"
HYPOTHESIS hyp2_3_2 : OCCURRENCES "\"month\" > 1"
HYPOTHESIS hyp2_3_3 : OCCURRENCES "NOT \"year\" IS NULL"
HYPOTHESIS hyp2_3_4 : OCCURRENCES "NOT \"month\" IS NULL"
HYPOTHESIS hyp2_3_5 : OCCURRENCES "NOT \"day\" IS NULL"
theorem eq_2_3 (t : TableRel OCCURRENCES_schema) (h0 : hyp2_3_0 t) (h1 : hyp2_3_1 t) (h2 : hyp2_3_2 t) (h3 : hyp2_3_3 t) (h4 : hyp2_3_4 t) (h5 : hyp2_3_5 t) :
    (sql%([OCCURRENCES_schema]) "WITH daily_counts AS (SELECT \"year\", \"month\", \"day\", COUNT(*) AS sightings FROM \"GBIF\".\"GBIF\".\"OCCURRENCES\" WHERE \"species\" = 'Sterna paradisaea' AND \"decimallatitude\" > 40 AND \"month\" > 1 AND NOT \"year\" IS NULL AND NOT \"month\" IS NULL AND NOT \"day\" IS NULL GROUP BY \"year\", \"month\", \"day\" HAVING COUNT(*) > 10), earliest_per_year AS (SELECT \"year\", MIN(\"month\" * 100 + \"day\") AS earliest_date_key FROM daily_counts GROUP BY \"year\") SELECT \"year\" AS \"OUTPUT\" FROM earliest_per_year ORDER BY earliest_date_key ASC LIMIT 1") t ~= (sql%([OCCURRENCES_schema]) "/* For each year, find the first date after January where more than 10 sightings */ /* of Sterna paradisaea were recorded north of 40° latitude. */ /* Return the year with the overall earliest such date. */ WITH daily_counts AS (SELECT \"year\", \"month\", \"day\", COUNT(*) AS sighting_count FROM \"GBIF\".\"GBIF\".\"OCCURRENCES\" WHERE \"species\" = 'Sterna paradisaea' AND \"decimallatitude\" > 40 AND \"month\" > 1 GROUP BY \"year\", \"month\", \"day\" HAVING COUNT(*) > 10), earliest_per_year AS (SELECT \"year\", MIN(\"month\" * 100 + \"day\") AS earliest_date_key FROM daily_counts GROUP BY \"year\") SELECT \"year\" AS OUTPUT FROM earliest_per_year ORDER BY earliest_date_key ASC LIMIT 1") t := by
  first | sql_equiv | sorry

end Bench_sf_bq096
