import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq414_eq_0_1

CREATE TABLE VISION_API_DATA («object_id» INT, «faceAnnotations» STRING, «landmarkAnnotations» STRING, «cropHintsAnnotation» STRING, «logoAnnotations» STRING, «labelAnnotations» STRING, «textAnnotations» STRING, «fullTextAnnotation» STRING, «imagePropertiesAnnotation» STRING, «safeSearchAnnotation» STRING, «webDetection» STRING)
CREATE TABLE OBJECTS («object_number» STRING, «is_highlight» BOOL, «is_public_domain» BOOL, «object_id» INT, «department» STRING, «object_name» STRING, «title» STRING, «culture» STRING, «period» STRING, «dynasty» STRING, «reign» STRING, «portfolio» STRING, «artist_role» STRING, «artist_prefix» STRING, «artist_display_name» STRING, «artist_display_bio» STRING, «artist_suffix» STRING, «artist_alpha_sort» STRING, «artist_nationality» STRING, «artist_begin_date» STRING, «artist_end_date» STRING, «object_date» STRING, «object_begin_date» INT, «object_end_date» INT, «medium» STRING, «dimensions» STRING, «credit_line» STRING, «geography_type» STRING, «city» STRING, «state» STRING, «county» STRING, «country» STRING, «region» STRING, «subregion» STRING, «locale» STRING, «locus» STRING, «excavation» STRING, «river» STRING, «classification» STRING, «rights_and_reproduction» STRING, «link_resource» STRING, «metadata_date» INT, «repository» STRING)

theorem eq (t0 : TableRel VISION_API_DATA_schema) (t1 : TableRel OBJECTS_schema) :
    (sql%([VISION_API_DATA_schema, OBJECTS_schema]) "SELECT o.\"object_id\" AS \"object_id\", o.\"title\" AS \"title\", TO_CHAR(TO_TIMESTAMP(CAST(o.\"metadata_date\" AS DOUBLE PRECISION) / 1000000), 'YYYY-MM-DD') AS \"METADATA_DATE\" FROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" AS o JOIN \"THE_MET\".\"THE_MET\".\"VISION_API_DATA\" AS v ON o.\"object_id\" = v.\"object_id\" WHERE o.\"department\" = 'The Libraries' AND CAST(JSON_EXTRACT_PATH(v.\"cropHintsAnnotation\", 'cropHints', '0', 'confidence') AS DOUBLE PRECISION) > 0.5 AND LOWER(o.\"title\") LIKE '%book%' ORDER BY o.\"object_id\"") t0 t1
  = (sql%([VISION_API_DATA_schema, OBJECTS_schema]) "SELECT o.\"object_id\" AS object_id, o.\"title\" AS title, TO_CHAR(TO_TIMESTAMP(CAST(o.\"metadata_date\" AS DOUBLE PRECISION) / POWER(10, 6)), 'YYYY-MM-DD') AS METADATA_DATE FROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" AS o JOIN \"THE_MET\".\"THE_MET\".\"VISION_API_DATA\" AS v ON o.\"object_id\" = v.\"object_id\" WHERE o.\"department\" = 'The Libraries' AND LOWER(o.\"title\") LIKE '%book%' AND CAST(JSON_EXTRACT_PATH(v.\"cropHintsAnnotation\", 'cropHints', '0', 'confidence') AS DOUBLE PRECISION) > 0.5") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq414_eq_0_1
