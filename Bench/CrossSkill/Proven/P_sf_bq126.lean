import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq126 — proven cross-skill equivalence(s)

Question: What are the titles, artist names, mediums, and original image URLs of objects with 'Photograph' in their names from the 'Photographs' department, created not by an unknown artist, with an object end date of 1839 or earlier?

Independently-written SQL variants proved equal for all table contents by `sql_equiv`; where
they differ by a `WHERE`/`SELECT` fact, that data assumption is an explicit `HYPOTHESIS` antecedent.
-/

namespace P_sf_bq126

CREATE TABLE IMAGES («object_id» INT, «public_caption» STRING, «title» STRING, «original_image_url» STRING, «caption» STRING, «is_oasc» BOOL, «gcs_url» STRING)
CREATE TABLE OBJECTS («object_number» STRING, «is_highlight» BOOL, «is_public_domain» BOOL, «object_id» INT, «department» STRING, «object_name» STRING, «title» STRING, «culture» STRING, «period» STRING, «dynasty» STRING, «reign» STRING, «portfolio» STRING, «artist_role» STRING, «artist_prefix» STRING, «artist_display_name» STRING, «artist_display_bio» STRING, «artist_suffix» STRING, «artist_alpha_sort» STRING, «artist_nationality» STRING, «artist_begin_date» STRING, «artist_end_date» STRING, «object_date» STRING, «object_begin_date» INT, «object_end_date» INT, «medium» STRING, «dimensions» STRING, «credit_line» STRING, «geography_type» STRING, «city» STRING, «state» STRING, «county» STRING, «country» STRING, «region» STRING, «subregion» STRING, «locale» STRING, «locus» STRING, «excavation» STRING, «river» STRING, «classification» STRING, «rights_and_reproduction» STRING, «link_resource» STRING, «metadata_date» INT, «repository» STRING)

theorem eq_0_1 :
    sql%([IMAGES_schema, OBJECTS_schema]) "SELECT\n    o.\"artist_display_name\",\n    o.\"title\",\n    o.\"object_end_date\",\n    o.\"medium\",\n    i.\"original_image_url\"\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"IMAGES\" i\n    ON o.\"object_id\" = i.\"object_id\"\nWHERE o.\"department\" = 'Photographs'\n  AND o.\"object_name\" LIKE '%Photograph%'\n  AND o.\"object_end_date\" <= 1839\n  AND o.\"artist_display_name\" != 'Unknown'\nORDER BY o.\"title\", i.\"original_image_url\";" = sql%([IMAGES_schema, OBJECTS_schema]) "SELECT\n    o.\"artist_display_name\",\n    o.\"title\",\n    o.\"object_end_date\",\n    o.\"medium\",\n    i.\"original_image_url\"\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"IMAGES\" i\n    ON o.\"object_id\" = i.\"object_id\"\nWHERE o.\"department\" = 'Photographs'\n  AND o.\"object_name\" LIKE '%Photograph%'\n  AND o.\"artist_display_name\" != 'Unknown'\n  AND o.\"object_end_date\" <= 1839;" := by sql_equiv

end P_sf_bq126
