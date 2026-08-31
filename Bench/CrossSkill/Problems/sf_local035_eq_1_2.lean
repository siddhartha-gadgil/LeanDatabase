import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local035_eq_1_2

CREATE TABLE OLIST_GEOLOCATION («geolocation_zip_code_prefix» INT, «geolocation_lat» FLOAT, «geolocation_lng» FLOAT, «geolocation_city» STRING, «geolocation_state» STRING)

theorem eq (t0 : TableRel OLIST_GEOLOCATION_schema) :
    (sql%([OLIST_GEOLOCATION_schema]) "WITH filtered AS (SELECT * FROM \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_GEOLOCATION\" WHERE \"geolocation_lat\" BETWEEN -35 AND 30 AND \"geolocation_lng\" BETWEEN -80 AND -10), city_avg AS (SELECT \"geolocation_city\" AS city, \"geolocation_state\" AS state, AVG(\"geolocation_lat\") AS avg_lat, AVG(\"geolocation_lng\") AS avg_lng FROM filtered GROUP BY \"geolocation_city\", \"geolocation_state\"), ordered AS (SELECT city, state, avg_lat, avg_lng, LAG(city) OVER (ORDER BY state, city) AS prev_city, LAG(avg_lat) OVER (ORDER BY state, city) AS prev_lat, LAG(avg_lng) OVER (ORDER BY state, city) AS prev_lng FROM city_avg), with_dist AS (SELECT city AS city_one, prev_city AS city_two, 6371 * ACOS(GREATEST(-1, LEAST(1, COS(RADIANS(prev_lat)) * COS(RADIANS(avg_lat)) * COS(RADIANS(avg_lng) - RADIANS(prev_lng)) + SIN(RADIANS(prev_lat)) * SIN(RADIANS(avg_lat))))) AS distance_km FROM ordered WHERE NOT prev_city IS NULL AND city <> prev_city) SELECT city_one, city_two FROM with_dist ORDER BY distance_km DESC LIMIT 1") t0
  ~= (sql%([OLIST_GEOLOCATION_schema]) "WITH ordered AS (SELECT \"geolocation_city\", \"geolocation_lat\", \"geolocation_lng\", LAG(\"geolocation_city\") OVER (ORDER BY \"geolocation_state\", \"geolocation_city\", \"geolocation_zip_code_prefix\", \"geolocation_lat\", \"geolocation_lng\") AS prev_city, LAG(\"geolocation_lat\") OVER (ORDER BY \"geolocation_state\", \"geolocation_city\", \"geolocation_zip_code_prefix\", \"geolocation_lat\", \"geolocation_lng\") AS prev_lat, LAG(\"geolocation_lng\") OVER (ORDER BY \"geolocation_state\", \"geolocation_city\", \"geolocation_zip_code_prefix\", \"geolocation_lat\", \"geolocation_lng\") AS prev_lng FROM \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_GEOLOCATION\"), distances AS (SELECT prev_city AS city_one, \"geolocation_city\" AS city_two, 6371 * ACOS(LEAST(1.0, GREATEST(-1.0, COS(RADIANS(prev_lat)) * COS(RADIANS(\"geolocation_lat\")) * COS(RADIANS(\"geolocation_lng\") - RADIANS(prev_lng)) + SIN(RADIANS(prev_lat)) * SIN(RADIANS(\"geolocation_lat\"))))) AS distance_km FROM ordered WHERE NOT prev_city IS NULL) SELECT city_one AS \"CITY_ONE\", city_two AS \"CITY_TWO\" FROM distances ORDER BY distance_km DESC LIMIT 1") t0
  := by first | sql_equiv | sorry

end N_sf_local035_eq_1_2
