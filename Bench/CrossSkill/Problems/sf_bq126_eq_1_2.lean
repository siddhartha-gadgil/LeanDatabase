import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq126_eq_1_2

CREATE TABLE IMAGES («object_id» INT, «public_caption» STRING, «title» STRING, «original_image_url» STRING, «caption» STRING, «is_oasc» BOOL, «gcs_url» STRING)
CREATE TABLE OBJECTS («object_number» STRING, «is_highlight» BOOL, «is_public_domain» BOOL, «object_id» INT, «department» STRING, «object_name» STRING, «title» STRING, «culture» STRING, «period» STRING, «dynasty» STRING, «reign» STRING, «portfolio» STRING, «artist_role» STRING, «artist_prefix» STRING, «artist_display_name» STRING, «artist_display_bio» STRING, «artist_suffix» STRING, «artist_alpha_sort» STRING, «artist_nationality» STRING, «artist_begin_date» STRING, «artist_end_date» STRING, «object_date» STRING, «object_begin_date» INT, «object_end_date» INT, «medium» STRING, «dimensions» STRING, «credit_line» STRING, «geography_type» STRING, «city» STRING, «state» STRING, «county» STRING, «country» STRING, «region» STRING, «subregion» STRING, «locale» STRING, «locus» STRING, «excavation» STRING, «river» STRING, «classification» STRING, «rights_and_reproduction» STRING, «link_resource» STRING, «metadata_date» INT, «repository» STRING)

theorem eq (t0 : TableRel IMAGES_schema) (t1 : TableRel OBJECTS_schema) :
    (sql%([IMAGES_schema, OBJECTS_schema]) "SELECT o.\"artist_display_name\", o.\"title\", o.\"object_end_date\", o.\"medium\", i.\"original_image_url\" FROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" AS o JOIN \"THE_MET\".\"THE_MET\".\"IMAGES\" AS i ON o.\"object_id\" = i.\"object_id\" WHERE o.\"department\" = 'Photographs' AND o.\"object_name\" LIKE '%Photograph%' AND o.\"artist_display_name\" <> 'Unknown' AND o.\"object_end_date\" <= 1839") t0 t1
  = (sql%([IMAGES_schema, OBJECTS_schema]) "SELECT o.\"artist_display_name\", o.\"title\", o.\"object_end_date\", o.\"medium\", i.\"original_image_url\" FROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" AS o JOIN \"THE_MET\".\"THE_MET\".\"IMAGES\" AS i ON o.\"object_id\" = i.\"object_id\" WHERE o.\"department\" = 'Photographs' AND o.\"object_name\" LIKE '%Photograph%' AND NOT o.\"artist_display_name\" IN ('', 'Unknown') AND o.\"object_end_date\" <= 1839 ORDER BY o.\"object_end_date\", o.\"artist_display_name\", o.\"title\"") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq126_eq_1_2
