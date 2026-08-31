import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq181_eq_2_3

CREATE TABLE STATIONS («usaf» STRING, «wban» STRING, «name» STRING, «country» STRING, «state» STRING, «call» STRING, «lat» FLOAT, «lon» FLOAT, «elev» STRING, «begin» STRING, «end» STRING)
CREATE TABLE GSOD2022 («stn» STRING, «wban» STRING, «date» STRING, «year» STRING, «mo» STRING, «da» STRING, «temp» FLOAT, «count_temp» INT, «dewp» FLOAT, «count_dewp» INT, «slp» FLOAT, «count_slp» INT, «stp» FLOAT, «count_stp» INT, «visib» FLOAT, «count_visib» INT, «wdsp» STRING, «count_wdsp» STRING, «mxpsd» STRING, «gust» FLOAT, «max» FLOAT, «flag_max» STRING, «min» FLOAT, «flag_min» STRING, «prcp» FLOAT, «flag_prcp» STRING, «sndp» FLOAT, «fog» STRING, «rain_drizzle» STRING, «snow_ice_pellets» STRING, «hail» STRING, «thunder» STRING, «tornado_funnel_cloud» STRING)

theorem eq (t0 : TableRel STATIONS_schema) (t1 : TableRel GSOD2022_schema) :
    (sql%([STATIONS_schema, GSOD2022_schema]) "WITH station_coverage AS (SELECT \"stn\", \"wban\", COUNT(CASE WHEN NOT \"temp\" IS NULL AND \"temp\" <> 9999.9 AND NOT \"max\" IS NULL AND \"max\" <> 9999.9 AND NOT \"min\" IS NULL AND \"min\" <> 9999.9 THEN 1 END) AS valid_days FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2022\" WHERE \"stn\" <> '999999' GROUP BY \"stn\", \"wban\" HAVING valid_days >= 0.9 * 365), total_stations AS (SELECT COUNT(*) AS total_count FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" WHERE \"usaf\" <> '999999') SELECT ROUND(CAST(100.0 * (SELECT COUNT(*) FROM station_coverage) AS DOUBLE PRECISION) / total_count, 2) AS \"percentage_of_stations_with_90_percent_coverage\" FROM total_stations") t0 t1
  ~= (sql%([STATIONS_schema, GSOD2022_schema]) "WITH valid_station_days AS (SELECT \"stn\", \"wban\", COUNT(DISTINCT \"date\") AS valid_day_count FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2022\" WHERE \"stn\" <> '999999' AND NOT \"temp\" IS NULL AND \"temp\" <> 9999.9 AND NOT \"max\" IS NULL AND \"max\" <> 9999.9 AND NOT \"min\" IS NULL AND \"min\" <> 9999.9 GROUP BY \"stn\", \"wban\" HAVING COUNT(DISTINCT \"date\") >= 0.9 * 365), total_stations AS (SELECT COUNT(*) AS cnt FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" WHERE \"usaf\" <> '999999') SELECT CAST(100.0 * (SELECT COUNT(*) FROM valid_station_days) AS DOUBLE PRECISION) / (SELECT cnt FROM total_stations) AS percentage_of_stations_with_90_percent_coverage") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq181_eq_2_3
