import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq414 — crossskill equivalence(s)

Question: Retrieve the object id, title, and the formatted metadata date (as a string in 'YYYY-MM-DD' format) for objects in the "The Libraries" department where the cropConfidence is greater than 0.5, the object's title contains the word "book".

NOTE: uses WITH RECURSIVE / LATERAL / FLATTEN — may not elaborate yet.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq414

CREATE TABLE VISION_API_DATA («object_id» INT, «faceAnnotations» STRING, «landmarkAnnotations» STRING, «cropHintsAnnotation» STRING, «logoAnnotations» STRING, «labelAnnotations» STRING, «textAnnotations» STRING, «fullTextAnnotation» STRING, «imagePropertiesAnnotation» STRING, «safeSearchAnnotation» STRING, «webDetection» STRING)
CREATE TABLE OBJECTS («object_number» STRING, «is_highlight» BOOL, «is_public_domain» BOOL, «object_id» INT, «department» STRING, «object_name» STRING, «title» STRING, «culture» STRING, «period» STRING, «dynasty» STRING, «reign» STRING, «portfolio» STRING, «artist_role» STRING, «artist_prefix» STRING, «artist_display_name» STRING, «artist_display_bio» STRING, «artist_suffix» STRING, «artist_alpha_sort» STRING, «artist_nationality» STRING, «artist_begin_date» STRING, «artist_end_date» STRING, «object_date» STRING, «object_begin_date» INT, «object_end_date» INT, «medium» STRING, «dimensions» STRING, «credit_line» STRING, «geography_type» STRING, «city» STRING, «state» STRING, «county» STRING, «country» STRING, «region» STRING, «subregion» STRING, «locale» STRING, «locus» STRING, «excavation» STRING, «river» STRING, «classification» STRING, «rights_and_reproduction» STRING, «link_resource» STRING, «metadata_date» INT, «repository» STRING)

theorem eq_0_1 :
    sql%([VISION_API_DATA_schema, OBJECTS_schema]) "SELECT \n    o.\"object_id\" AS \"object_id\",\n    o.\"title\" AS \"title\",\n    TO_VARCHAR(TO_TIMESTAMP(o.\"metadata_date\" / 1000000), 'YYYY-MM-DD') AS \"METADATA_DATE\"\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"VISION_API_DATA\" v \n    ON o.\"object_id\" = v.\"object_id\"\nWHERE o.\"department\" = 'The Libraries'\n  AND v.\"cropHintsAnnotation\":\"cropHints\"[0]:\"confidence\"::FLOAT > 0.5\n  AND LOWER(o.\"title\") LIKE '%book%'\nORDER BY o.\"object_id\";" = sql%([VISION_API_DATA_schema, OBJECTS_schema]) "SELECT \n  o.\"object_id\" AS object_id,\n  o.\"title\" AS title,\n  TO_VARCHAR(TO_TIMESTAMP(o.\"metadata_date\", 6), 'YYYY-MM-DD') AS METADATA_DATE\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"VISION_API_DATA\" v \n  ON o.\"object_id\" = v.\"object_id\"\nWHERE o.\"department\" = 'The Libraries'\n  AND LOWER(o.\"title\") LIKE '%book%'\n  AND v.\"cropHintsAnnotation\":\"cropHints\"[0]:\"confidence\"::FLOAT > 0.5;" := by
  first | sql_equiv | sorry

theorem eq_0_2 :
    sql%([VISION_API_DATA_schema, OBJECTS_schema]) "SELECT \n    o.\"object_id\" AS \"object_id\",\n    o.\"title\" AS \"title\",\n    TO_VARCHAR(TO_TIMESTAMP(o.\"metadata_date\" / 1000000), 'YYYY-MM-DD') AS \"METADATA_DATE\"\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"VISION_API_DATA\" v \n    ON o.\"object_id\" = v.\"object_id\"\nWHERE o.\"department\" = 'The Libraries'\n  AND v.\"cropHintsAnnotation\":\"cropHints\"[0]:\"confidence\"::FLOAT > 0.5\n  AND LOWER(o.\"title\") LIKE '%book%'\nORDER BY o.\"object_id\";" = sql%([VISION_API_DATA_schema, OBJECTS_schema]) "SELECT DISTINCT\n    o.\"object_id\" AS \"object_id\",\n    o.\"title\" AS \"title\",\n    TO_VARCHAR(TO_TIMESTAMP(o.\"metadata_date\" / 1000000), 'YYYY-MM-DD') AS \"METADATA_DATE\"\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"VISION_API_DATA\" v\n    ON o.\"object_id\" = v.\"object_id\"\n, LATERAL FLATTEN(input => v.\"cropHintsAnnotation\":\"cropHints\") ch\nWHERE o.\"department\" = 'The Libraries'\n  AND LOWER(o.\"title\") LIKE '%book%'\n  AND ch.value:confidence::FLOAT > 0.5\nORDER BY o.\"object_id\";" := by
  first | sql_equiv | sorry

theorem eq_0_3 :
    sql%([VISION_API_DATA_schema, OBJECTS_schema]) "SELECT \n    o.\"object_id\" AS \"object_id\",\n    o.\"title\" AS \"title\",\n    TO_VARCHAR(TO_TIMESTAMP(o.\"metadata_date\" / 1000000), 'YYYY-MM-DD') AS \"METADATA_DATE\"\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"VISION_API_DATA\" v \n    ON o.\"object_id\" = v.\"object_id\"\nWHERE o.\"department\" = 'The Libraries'\n  AND v.\"cropHintsAnnotation\":\"cropHints\"[0]:\"confidence\"::FLOAT > 0.5\n  AND LOWER(o.\"title\") LIKE '%book%'\nORDER BY o.\"object_id\";" = sql%([VISION_API_DATA_schema, OBJECTS_schema]) "SELECT\n    o.\"object_id\" AS \"object_id\",\n    o.\"title\" AS \"title\",\n    TO_VARCHAR(TO_TIMESTAMP(o.\"metadata_date\" / 1000000), 'YYYY-MM-DD') AS \"metadata_date\"\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"VISION_API_DATA\" v\n    ON o.\"object_id\" = v.\"object_id\"\n, LATERAL FLATTEN(input => v.\"cropHintsAnnotation\":\"cropHints\") f\nWHERE o.\"department\" = 'The Libraries'\n  AND f.value:confidence::FLOAT > 0.5\n  AND LOWER(o.\"title\") LIKE '%book%'\nORDER BY o.\"object_id\";" := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([VISION_API_DATA_schema, OBJECTS_schema]) "SELECT \n  o.\"object_id\" AS object_id,\n  o.\"title\" AS title,\n  TO_VARCHAR(TO_TIMESTAMP(o.\"metadata_date\", 6), 'YYYY-MM-DD') AS METADATA_DATE\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"VISION_API_DATA\" v \n  ON o.\"object_id\" = v.\"object_id\"\nWHERE o.\"department\" = 'The Libraries'\n  AND LOWER(o.\"title\") LIKE '%book%'\n  AND v.\"cropHintsAnnotation\":\"cropHints\"[0]:\"confidence\"::FLOAT > 0.5;" = sql%([VISION_API_DATA_schema, OBJECTS_schema]) "SELECT DISTINCT\n    o.\"object_id\" AS \"object_id\",\n    o.\"title\" AS \"title\",\n    TO_VARCHAR(TO_TIMESTAMP(o.\"metadata_date\" / 1000000), 'YYYY-MM-DD') AS \"METADATA_DATE\"\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"VISION_API_DATA\" v\n    ON o.\"object_id\" = v.\"object_id\"\n, LATERAL FLATTEN(input => v.\"cropHintsAnnotation\":\"cropHints\") ch\nWHERE o.\"department\" = 'The Libraries'\n  AND LOWER(o.\"title\") LIKE '%book%'\n  AND ch.value:confidence::FLOAT > 0.5\nORDER BY o.\"object_id\";" := by
  first | sql_equiv | sorry

theorem eq_1_3 :
    sql%([VISION_API_DATA_schema, OBJECTS_schema]) "SELECT \n  o.\"object_id\" AS object_id,\n  o.\"title\" AS title,\n  TO_VARCHAR(TO_TIMESTAMP(o.\"metadata_date\", 6), 'YYYY-MM-DD') AS METADATA_DATE\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"VISION_API_DATA\" v \n  ON o.\"object_id\" = v.\"object_id\"\nWHERE o.\"department\" = 'The Libraries'\n  AND LOWER(o.\"title\") LIKE '%book%'\n  AND v.\"cropHintsAnnotation\":\"cropHints\"[0]:\"confidence\"::FLOAT > 0.5;" = sql%([VISION_API_DATA_schema, OBJECTS_schema]) "SELECT\n    o.\"object_id\" AS \"object_id\",\n    o.\"title\" AS \"title\",\n    TO_VARCHAR(TO_TIMESTAMP(o.\"metadata_date\" / 1000000), 'YYYY-MM-DD') AS \"metadata_date\"\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"VISION_API_DATA\" v\n    ON o.\"object_id\" = v.\"object_id\"\n, LATERAL FLATTEN(input => v.\"cropHintsAnnotation\":\"cropHints\") f\nWHERE o.\"department\" = 'The Libraries'\n  AND f.value:confidence::FLOAT > 0.5\n  AND LOWER(o.\"title\") LIKE '%book%'\nORDER BY o.\"object_id\";" := by
  first | sql_equiv | sorry

theorem eq_2_3 :
    sql%([VISION_API_DATA_schema, OBJECTS_schema]) "SELECT DISTINCT\n    o.\"object_id\" AS \"object_id\",\n    o.\"title\" AS \"title\",\n    TO_VARCHAR(TO_TIMESTAMP(o.\"metadata_date\" / 1000000), 'YYYY-MM-DD') AS \"METADATA_DATE\"\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"VISION_API_DATA\" v\n    ON o.\"object_id\" = v.\"object_id\"\n, LATERAL FLATTEN(input => v.\"cropHintsAnnotation\":\"cropHints\") ch\nWHERE o.\"department\" = 'The Libraries'\n  AND LOWER(o.\"title\") LIKE '%book%'\n  AND ch.value:confidence::FLOAT > 0.5\nORDER BY o.\"object_id\";" = sql%([VISION_API_DATA_schema, OBJECTS_schema]) "SELECT\n    o.\"object_id\" AS \"object_id\",\n    o.\"title\" AS \"title\",\n    TO_VARCHAR(TO_TIMESTAMP(o.\"metadata_date\" / 1000000), 'YYYY-MM-DD') AS \"metadata_date\"\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"VISION_API_DATA\" v\n    ON o.\"object_id\" = v.\"object_id\"\n, LATERAL FLATTEN(input => v.\"cropHintsAnnotation\":\"cropHints\") f\nWHERE o.\"department\" = 'The Libraries'\n  AND f.value:confidence::FLOAT > 0.5\n  AND LOWER(o.\"title\") LIKE '%book%'\nORDER BY o.\"object_id\";" := by
  first | sql_equiv | sorry

end Bench_sf_bq414
