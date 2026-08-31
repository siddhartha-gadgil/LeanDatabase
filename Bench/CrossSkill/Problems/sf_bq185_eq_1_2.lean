import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq185_eq_1_2

CREATE TABLE TAXI_ZONE_GEOM («zone_id» STRING, «zone_name» STRING, «borough» STRING, «zone_geom» STRING)
CREATE TABLE TLC_YELLOW_TRIPS_2016 («vendor_id» STRING, «pickup_datetime» INT, «dropoff_datetime» INT, «passenger_count» INT, «trip_distance» INT, «rate_code» STRING, «store_and_fwd_flag» STRING, «payment_type» STRING, «fare_amount» INT, «extra» INT, «mta_tax» INT, «tip_amount» INT, «tolls_amount» INT, «imp_surcharge» INT, «airport_fee» INT, «total_amount» INT, «pickup_location_id» STRING, «dropoff_location_id» STRING, «data_file_year» INT, «data_file_month» INT)

theorem eq (t0 : TableRel TAXI_ZONE_GEOM_schema) (t1 : TableRel TLC_YELLOW_TRIPS_2016_schema) :
    (sql%([TAXI_ZONE_GEOM_schema, TLC_YELLOW_TRIPS_2016_schema]) "SELECT AVG(CAST(EXTRACT(epoch FROM CAST(TO_TIMESTAMP(CAST(t.\"dropoff_datetime\" AS DOUBLE PRECISION) / 1000000) AS TIMESTAMP) - CAST(TO_TIMESTAMP(CAST(t.\"pickup_datetime\" AS DOUBLE PRECISION) / 1000000) AS TIMESTAMP)) / 60 AS BIGINT)) AS AVG_DURATION FROM \"NEW_YORK_PLUS\".\"NEW_YORK_TAXI_TRIPS\".\"TLC_YELLOW_TRIPS_2016\" AS t JOIN \"NEW_YORK_PLUS\".\"NEW_YORK_TAXI_TRIPS\".\"TAXI_ZONE_GEOM\" AS pu ON t.\"pickup_location_id\" = pu.\"zone_id\" JOIN \"NEW_YORK_PLUS\".\"NEW_YORK_TAXI_TRIPS\".\"TAXI_ZONE_GEOM\" AS do ON t.\"dropoff_location_id\" = do.\"zone_id\" WHERE TO_TIMESTAMP(CAST(t.\"pickup_datetime\" AS DOUBLE PRECISION) / 1000000) >= '2016-02-01' AND TO_TIMESTAMP(CAST(t.\"pickup_datetime\" AS DOUBLE PRECISION) / 1000000) < '2016-02-08' AND t.\"passenger_count\" > 3 AND t.\"trip_distance\" >= 10 AND pu.\"borough\" = 'Brooklyn' AND do.\"borough\" = 'Brooklyn' AND (t.\"dropoff_datetime\" - t.\"pickup_datetime\") > 0") t0 t1
  ~= (sql%([TAXI_ZONE_GEOM_schema, TLC_YELLOW_TRIPS_2016_schema]) "SELECT AVG(CAST(CAST((\"dropoff_datetime\" - \"pickup_datetime\") AS DOUBLE PRECISION) / 1000000.0 AS DOUBLE PRECISION) / 60.0) AS \"AVG_DURATION\" FROM \"NEW_YORK_PLUS\".\"NEW_YORK_TAXI_TRIPS\".\"TLC_YELLOW_TRIPS_2016\" AS t JOIN \"NEW_YORK_PLUS\".\"NEW_YORK_TAXI_TRIPS\".\"TAXI_ZONE_GEOM\" AS pz ON CAST(t.\"pickup_location_id\" AS VARCHAR) = pz.\"zone_id\" JOIN \"NEW_YORK_PLUS\".\"NEW_YORK_TAXI_TRIPS\".\"TAXI_ZONE_GEOM\" AS dz ON CAST(t.\"dropoff_location_id\" AS VARCHAR) = dz.\"zone_id\" WHERE TO_TIMESTAMP(CAST(t.\"pickup_datetime\" AS DOUBLE PRECISION) / 1000000) >= '2016-02-01' AND TO_TIMESTAMP(CAST(t.\"pickup_datetime\" AS DOUBLE PRECISION) / 1000000) < '2016-02-08' AND t.\"dropoff_datetime\" > t.\"pickup_datetime\" AND t.\"passenger_count\" > 3 AND t.\"trip_distance\" >= 10 AND pz.\"borough\" = 'Brooklyn' AND dz.\"borough\" = 'Brooklyn'") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq185_eq_1_2
