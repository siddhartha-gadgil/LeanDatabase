import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq229_eq_0_1

CREATE TABLE IMAGES («image_id» STRING, «subset» STRING, «original_url» STRING, «original_landing_url» STRING, «license» STRING, «author_profile_url» STRING, «author» STRING, «title» STRING, «original_size» INT, «original_md5» STRING, «thumbnail_300k_url» STRING)
CREATE TABLE LABELS («image_id» STRING, «source» STRING, «label_name» STRING, «confidence» FLOAT)

theorem eq (t0 : TableRel IMAGES_schema) (t1 : TableRel LABELS_schema) :
    (sql%([IMAGES_schema, LABELS_schema]) "WITH cat_images AS (SELECT DISTINCT l.\"image_id\" FROM \"OPEN_IMAGES\".\"OPEN_IMAGES\".\"LABELS\" AS l WHERE l.\"label_name\" = '/m/01yrx' AND l.\"confidence\" = 1), cat_urls AS (SELECT COUNT(DISTINCT i.\"original_url\") AS url_count FROM \"OPEN_IMAGES\".\"OPEN_IMAGES\".\"IMAGES\" AS i INNER JOIN cat_images AS c ON i.\"image_id\" = c.\"image_id\"), all_cat_images AS (SELECT DISTINCT \"image_id\" FROM \"OPEN_IMAGES\".\"OPEN_IMAGES\".\"LABELS\" WHERE \"label_name\" = '/m/01yrx'), other_urls AS (SELECT COUNT(DISTINCT i.\"original_url\") AS url_count FROM \"OPEN_IMAGES\".\"OPEN_IMAGES\".\"IMAGES\" AS i WHERE i.\"image_id\" <> ALL (SELECT \"image_id\" FROM all_cat_images)) SELECT 'cat' AS CATEGORY, url_count AS URL_COUNT FROM cat_urls UNION ALL SELECT 'other' AS CATEGORY, url_count AS URL_COUNT FROM other_urls") t0 t1
  ~= (sql%([IMAGES_schema, LABELS_schema]) "/* Cat images: label '/m/01yrx' with confidence=1 */ SELECT 'cat' AS CATEGORY, COUNT(DISTINCT i.\"original_url\") AS URL_COUNT FROM \"OPEN_IMAGES\".\"OPEN_IMAGES\".\"LABELS\" AS l JOIN \"OPEN_IMAGES\".\"OPEN_IMAGES\".\"IMAGES\" AS i ON l.\"image_id\" = i.\"image_id\" WHERE l.\"label_name\" = '/m/01yrx' AND l.\"confidence\" = 1 UNION ALL /* Other images: no cat label '/m/01yrx' at any confidence */ SELECT 'other' AS CATEGORY, COUNT(DISTINCT i.\"original_url\") AS URL_COUNT FROM \"OPEN_IMAGES\".\"OPEN_IMAGES\".\"IMAGES\" AS i WHERE i.\"image_id\" <> ALL (SELECT \"image_id\" FROM \"OPEN_IMAGES\".\"OPEN_IMAGES\".\"LABELS\" WHERE \"label_name\" = '/m/01yrx')") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq229_eq_0_1
