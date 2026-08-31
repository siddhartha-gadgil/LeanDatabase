import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local035_eq_0_3

CREATE TABLE OLIST_GEOLOCATION («geolocation_zip_code_prefix» INT, «geolocation_lat» FLOAT, «geolocation_lng» FLOAT, «geolocation_city» STRING, «geolocation_state» STRING)

theorem eq (t0 : TableRel OLIST_GEOLOCATION_schema) :
    (sql%([OLIST_GEOLOCATION_schema]) "WITH ordered AS (SELECT \"geolocation_city\", \"geolocation_lat\", \"geolocation_lng\", LAG(\"geolocation_city\") OVER (ORDER BY \"geolocation_state\", \"geolocation_city\", \"geolocation_zip_code_prefix\", \"geolocation_lat\", \"geolocation_lng\") AS prev_city, LAG(\"geolocation_lat\") OVER (ORDER BY \"geolocation_state\", \"geolocation_city\", \"geolocation_zip_code_prefix\", \"geolocation_lat\", \"geolocation_lng\") AS prev_lat, LAG(\"geolocation_lng\") OVER (ORDER BY \"geolocation_state\", \"geolocation_city\", \"geolocation_zip_code_prefix\", \"geolocation_lat\", \"geolocation_lng\") AS prev_lng FROM \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_GEOLOCATION\"), with_distance AS (SELECT \"geolocation_city\" AS CITY_ONE, prev_city AS CITY_TWO, 6371 * ACOS(LEAST(1.0, GREATEST(-1.0, COS(RADIANS(prev_lat)) * COS(RADIANS(\"geolocation_lat\")) * COS(RADIANS(\"geolocation_lng\") - RADIANS(prev_lng)) + SIN(RADIANS(prev_lat)) * SIN(RADIANS(\"geolocation_lat\"))))) AS distance_km FROM ordered WHERE NOT prev_lat IS NULL AND NOT prev_city IS NULL AND prev_city <> \"geolocation_city\") SELECT CITY_ONE, CITY_TWO FROM with_distance ORDER BY distance_km DESC LIMIT 1") t0
  = (sql%([OLIST_GEOLOCATION_schema]) "WITH ordered_geo AS (SELECT \"geolocation_city\", \"geolocation_lat\", \"geolocation_lng\", LAG(\"geolocation_city\") OVER (ORDER BY \"geolocation_state\", \"geolocation_city\", \"geolocation_zip_code_prefix\", \"geolocation_lat\", \"geolocation_lng\") AS prev_city, LAG(\"geolocation_lat\") OVER (ORDER BY \"geolocation_state\", \"geolocation_city\", \"geolocation_zip_code_prefix\", \"geolocation_lat\", \"geolocation_lng\") AS prev_lat, LAG(\"geolocation_lng\") OVER (ORDER BY \"geolocation_state\", \"geolocation_city\", \"geolocation_zip_code_prefix\", \"geolocation_lat\", \"geolocation_lng\") AS prev_lng FROM \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_GEOLOCATION\"), distances AS (SELECT prev_city AS \"CITY_ONE\", \"geolocation_city\" AS \"CITY_TWO\", 6371 * ACOS(LEAST(1.0, GREATEST(-1.0, COS(RADIANS(prev_lat)) * COS(RADIANS(\"geolocation_lat\")) * COS(RADIANS(\"geolocation_lng\") - RADIANS(prev_lng)) + SIN(RADIANS(prev_lat)) * SIN(RADIANS(\"geolocation_lat\"))))) AS distance_km FROM ordered_geo WHERE NOT prev_city IS NULL) SELECT \"CITY_ONE\", \"CITY_TWO\" FROM distances ORDER BY distance_km DESC LIMIT 1") t0
  := by first | sql_equiv | sorry

end N_sf_local035_eq_0_3
