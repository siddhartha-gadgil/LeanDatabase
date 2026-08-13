import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq126 — a proven cross-skill equivalence

Question: What are the titles, artist names, mediums, and original image URLs of objects with 'Photograph' in their names from the 'Photographs' department, created not by an unknown artist, with an object end date of 1839 or earlier?

Two independently-written SQL answers to the same question, proved equivalent for *all*
table contents by `sql_equiv` (not just on one instance).
-/

namespace P_sf_bq126

CREATE TABLE IMAGES («object_id» INT, «title» STRING, «original_image_url» STRING)
CREATE TABLE OBJECTS («object_id» INT, «department» STRING, «object_name» STRING, «title» STRING, «artist_display_name» STRING, «object_end_date» INT, «medium» STRING)

/-- Variant A:  SELECT o."artist_display_name", o."title", o."object_end_date", o."medium", i."original_image_url" FROM "THE_MET"."THE_MET"."OBJECTS" o JOIN "THE_MET"."THE_MET"
    Variant B:  SELECT o."artist_display_name", o."title", o."object_end_date", o."medium", i."original_image_url" FROM "THE_MET"."THE_MET"."OBJECTS" o JOIN "THE_MET"."THE_MET" -/
theorem equivalent :
    sql%([IMAGES_schema, OBJECTS_schema]) "SELECT\n    o.\"artist_display_name\",\n    o.\"title\",\n    o.\"object_end_date\",\n    o.\"medium\",\n    i.\"original_image_url\"\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"IMAGES\" i\n    ON o.\"object_id\" = i.\"object_id\"\nWHERE o.\"department\" = 'Photographs'\n  AND o.\"object_name\" LIKE '%Photograph%'\n  AND o.\"object_end_date\" <= 1839\n  AND o.\"artist_display_name\" != 'Unknown'\nORDER BY o.\"title\", i.\"original_image_url\";"
      = sql%([IMAGES_schema, OBJECTS_schema]) "SELECT\n    o.\"artist_display_name\",\n    o.\"title\",\n    o.\"object_end_date\",\n    o.\"medium\",\n    i.\"original_image_url\"\nFROM \"THE_MET\".\"THE_MET\".\"OBJECTS\" o\nJOIN \"THE_MET\".\"THE_MET\".\"IMAGES\" i\n    ON o.\"object_id\" = i.\"object_id\"\nWHERE o.\"department\" = 'Photographs'\n  AND o.\"object_name\" LIKE '%Photograph%'\n  AND o.\"artist_display_name\" != 'Unknown'\n  AND o.\"object_end_date\" <= 1839;" := by sql_equiv

end P_sf_bq126
