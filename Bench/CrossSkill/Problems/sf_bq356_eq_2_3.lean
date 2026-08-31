import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq356_eq_2_3

CREATE TABLE STATIONS («usaf» STRING, «wban» STRING, «name» STRING, «country» STRING, «state» STRING, «call» STRING, «lat» FLOAT, «lon» FLOAT, «elev» STRING, «begin» STRING, «end» STRING)
CREATE TABLE GSOD2019 («stn» STRING, «wban» STRING, «year» STRING, «mo» STRING, «da» STRING, «temp» FLOAT, «count_temp» INT, «dewp» FLOAT, «count_dewp» INT, «slp» FLOAT, «count_slp» INT, «stp» FLOAT, «count_stp» INT, «visib» FLOAT, «count_visib» INT, «wdsp» STRING, «count_wdsp» STRING, «mxpsd» STRING, «gust» FLOAT, «max» FLOAT, «flag_max» STRING, «min» FLOAT, «flag_min» STRING, «prcp» FLOAT, «flag_prcp» STRING, «sndp» FLOAT, «fog» STRING, «rain_drizzle» STRING, «snow_ice_pellets» STRING, «hail» STRING, «thunder» STRING, «tornado_funnel_cloud» STRING)

theorem eq (t0 : TableRel STATIONS_schema) (t1 : TableRel GSOD2019_schema) :
    (sql%([STATIONS_schema, GSOD2019_schema]) "WITH valid_stations AS (SELECT \"usaf\", \"wban\" FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" WHERE \"begin\" <= '20000101' AND \"end\" >= '20190630'), daily_valid AS (SELECT g.\"stn\", g.\"wban\", COUNT(*) AS valid_days FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2019\" AS g INNER JOIN valid_stations AS s ON g.\"stn\" = s.\"usaf\" AND g.\"wban\" = s.\"wban\" WHERE g.\"temp\" <> 9999.9 AND g.\"max\" <> 9999.9 AND g.\"min\" <> 9999.9 GROUP BY g.\"stn\", g.\"wban\" HAVING COUNT(*) >= 365 * 0.9) SELECT COUNT(*) AS \"STATION_COUNT\" FROM daily_valid") t0 t1
  ~= (sql%([STATIONS_schema, GSOD2019_schema]) "WITH valid_days AS (SELECT g.\"stn\", g.\"wban\", COUNT(*) AS valid_day_count FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2019\" AS g JOIN \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" AS s ON g.\"stn\" = s.\"usaf\" AND g.\"wban\" = s.\"wban\" WHERE s.\"begin\" <= '20000101' AND s.\"end\" >= '20190630' AND g.\"temp\" <> 9999.9 AND g.\"max\" <> 9999.9 AND g.\"min\" <> 9999.9 GROUP BY g.\"stn\", g.\"wban\") SELECT COUNT(*) AS station_count FROM valid_days WHERE valid_day_count >= 0.9 * 365") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq356_eq_2_3
