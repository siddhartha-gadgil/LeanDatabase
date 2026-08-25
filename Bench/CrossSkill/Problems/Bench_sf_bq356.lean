import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq356 — crossskill equivalence(s)

Question: Among all NOAA GSOD weather stations that recorded valid daily temperature data (non-missing temp, max, min) in 2019 and whose period of record began on or before January 1, 2000, and continued through at least June 30, 2019, how many of these stations achieved 90% or more of the maximum possible number of valid temperature-record days in 2019?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq356

CREATE TABLE STATIONS («usaf» STRING, «wban» STRING, «name» STRING, «country» STRING, «state» STRING, «call» STRING, «lat» FLOAT, «lon» FLOAT, «elev» STRING, «begin» STRING, «end» STRING)
CREATE TABLE GSOD2019 («stn» STRING, «wban» STRING, «year» STRING, «mo» STRING, «da» STRING, «temp» FLOAT, «count_temp» INT, «dewp» FLOAT, «count_dewp» INT, «slp» FLOAT, «count_slp» INT, «stp» FLOAT, «count_stp» INT, «visib» FLOAT, «count_visib» INT, «wdsp» STRING, «count_wdsp» STRING, «mxpsd» STRING, «gust» FLOAT, «max» FLOAT, «flag_max» STRING, «min» FLOAT, «flag_min» STRING, «prcp» FLOAT, «flag_prcp» STRING, «sndp» FLOAT, «fog» STRING, «rain_drizzle» STRING, «snow_ice_pellets» STRING, «hail» STRING, «thunder» STRING, «tornado_funnel_cloud» STRING)

-- eq_0_1: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_1 : ∀ t,
    (sql%([STATIONS_schema, GSOD2019_schema]) "WITH qualifying_stations AS (/* Stations whose period of record began on or before Jan 1, 2000 */ /* and continued through at least June 30, 2019 */ SELECT \"usaf\", \"wban\" FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" WHERE \"begin\" <= '20000101' AND \"end\" >= '20190630'), valid_days_per_station AS (/* Count valid temperature-record days in 2019 per qualifying station */ /* A valid day requires all three: temp, max, min to be non-missing (not 9999.9) */ SELECT g.\"stn\", g.\"wban\", COUNT(*) AS valid_day_count FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2019\" AS g JOIN qualifying_stations AS qs ON g.\"stn\" = qs.\"usaf\" AND g.\"wban\" = qs.\"wban\" WHERE g.\"temp\" <> 9999.9 AND g.\"max\" <> 9999.9 AND g.\"min\" <> 9999.9 GROUP BY g.\"stn\", g.\"wban\") /* Count stations that achieved 90% or more of the maximum possible days (365) */ SELECT COUNT(*) AS STATION_COUNT FROM valid_days_per_station WHERE CAST(valid_day_count AS DOUBLE PRECISION) / 365.0 >= 0.9") t ~= (sql%([STATIONS_schema, GSOD2019_schema]) "SELECT COUNT(*) AS STATION_COUNT FROM (SELECT g.\"stn\", g.\"wban\" FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2019\" AS g JOIN \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" AS s ON g.\"stn\" = s.\"usaf\" AND g.\"wban\" = s.\"wban\" WHERE g.\"temp\" <> 9999.9 AND g.\"max\" <> 9999.9 AND g.\"min\" <> 9999.9 AND s.\"begin\" <= '20000101' AND s.\"end\" >= '20190630' GROUP BY g.\"stn\", g.\"wban\" HAVING COUNT(*) >= 365 * 0.9)") t := by
  intro t; first | sql_equiv | sorry

-- eq_0_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_2 :
    sql%([STATIONS_schema, GSOD2019_schema]) "WITH qualifying_stations AS (/* Stations whose period of record began on or before Jan 1, 2000 */ /* and continued through at least June 30, 2019 */ SELECT \"usaf\", \"wban\" FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" WHERE \"begin\" <= '20000101' AND \"end\" >= '20190630'), valid_days_per_station AS (/* Count valid temperature-record days in 2019 per qualifying station */ /* A valid day requires all three: temp, max, min to be non-missing (not 9999.9) */ SELECT g.\"stn\", g.\"wban\", COUNT(*) AS valid_day_count FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2019\" AS g JOIN qualifying_stations AS qs ON g.\"stn\" = qs.\"usaf\" AND g.\"wban\" = qs.\"wban\" WHERE g.\"temp\" <> 9999.9 AND g.\"max\" <> 9999.9 AND g.\"min\" <> 9999.9 GROUP BY g.\"stn\", g.\"wban\") /* Count stations that achieved 90% or more of the maximum possible days (365) */ SELECT COUNT(*) AS STATION_COUNT FROM valid_days_per_station WHERE CAST(valid_day_count AS DOUBLE PRECISION) / 365.0 >= 0.9" = sql%([STATIONS_schema, GSOD2019_schema]) "WITH valid_stations AS (SELECT \"usaf\", \"wban\" FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" WHERE \"begin\" <= '20000101' AND \"end\" >= '20190630'), daily_valid AS (SELECT g.\"stn\", g.\"wban\", COUNT(*) AS valid_days FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2019\" AS g INNER JOIN valid_stations AS s ON g.\"stn\" = s.\"usaf\" AND g.\"wban\" = s.\"wban\" WHERE g.\"temp\" <> 9999.9 AND g.\"max\" <> 9999.9 AND g.\"min\" <> 9999.9 GROUP BY g.\"stn\", g.\"wban\" HAVING COUNT(*) >= 365 * 0.9) SELECT COUNT(*) AS \"STATION_COUNT\" FROM daily_valid" := by
  first | sql_equiv | sorry

-- eq_0_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_3 : ∀ t,
    (sql%([STATIONS_schema, GSOD2019_schema]) "WITH qualifying_stations AS (/* Stations whose period of record began on or before Jan 1, 2000 */ /* and continued through at least June 30, 2019 */ SELECT \"usaf\", \"wban\" FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" WHERE \"begin\" <= '20000101' AND \"end\" >= '20190630'), valid_days_per_station AS (/* Count valid temperature-record days in 2019 per qualifying station */ /* A valid day requires all three: temp, max, min to be non-missing (not 9999.9) */ SELECT g.\"stn\", g.\"wban\", COUNT(*) AS valid_day_count FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2019\" AS g JOIN qualifying_stations AS qs ON g.\"stn\" = qs.\"usaf\" AND g.\"wban\" = qs.\"wban\" WHERE g.\"temp\" <> 9999.9 AND g.\"max\" <> 9999.9 AND g.\"min\" <> 9999.9 GROUP BY g.\"stn\", g.\"wban\") /* Count stations that achieved 90% or more of the maximum possible days (365) */ SELECT COUNT(*) AS STATION_COUNT FROM valid_days_per_station WHERE CAST(valid_day_count AS DOUBLE PRECISION) / 365.0 >= 0.9") t ~= (sql%([STATIONS_schema, GSOD2019_schema]) "WITH valid_days AS (SELECT g.\"stn\", g.\"wban\", COUNT(*) AS valid_day_count FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2019\" AS g JOIN \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" AS s ON g.\"stn\" = s.\"usaf\" AND g.\"wban\" = s.\"wban\" WHERE s.\"begin\" <= '20000101' AND s.\"end\" >= '20190630' AND g.\"temp\" <> 9999.9 AND g.\"max\" <> 9999.9 AND g.\"min\" <> 9999.9 GROUP BY g.\"stn\", g.\"wban\") SELECT COUNT(*) AS station_count FROM valid_days WHERE valid_day_count >= 0.9 * 365") t := by
  intro t; first | sql_equiv | sorry

-- eq_1_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_1_2 : ∀ t,
    (sql%([STATIONS_schema, GSOD2019_schema]) "SELECT COUNT(*) AS STATION_COUNT FROM (SELECT g.\"stn\", g.\"wban\" FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2019\" AS g JOIN \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" AS s ON g.\"stn\" = s.\"usaf\" AND g.\"wban\" = s.\"wban\" WHERE g.\"temp\" <> 9999.9 AND g.\"max\" <> 9999.9 AND g.\"min\" <> 9999.9 AND s.\"begin\" <= '20000101' AND s.\"end\" >= '20190630' GROUP BY g.\"stn\", g.\"wban\" HAVING COUNT(*) >= 365 * 0.9)") t ~= (sql%([STATIONS_schema, GSOD2019_schema]) "WITH valid_stations AS (SELECT \"usaf\", \"wban\" FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" WHERE \"begin\" <= '20000101' AND \"end\" >= '20190630'), daily_valid AS (SELECT g.\"stn\", g.\"wban\", COUNT(*) AS valid_days FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2019\" AS g INNER JOIN valid_stations AS s ON g.\"stn\" = s.\"usaf\" AND g.\"wban\" = s.\"wban\" WHERE g.\"temp\" <> 9999.9 AND g.\"max\" <> 9999.9 AND g.\"min\" <> 9999.9 GROUP BY g.\"stn\", g.\"wban\" HAVING COUNT(*) >= 365 * 0.9) SELECT COUNT(*) AS \"STATION_COUNT\" FROM daily_valid") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_3 : ∀ t,
    (sql%([STATIONS_schema, GSOD2019_schema]) "SELECT COUNT(*) AS STATION_COUNT FROM (SELECT g.\"stn\", g.\"wban\" FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2019\" AS g JOIN \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" AS s ON g.\"stn\" = s.\"usaf\" AND g.\"wban\" = s.\"wban\" WHERE g.\"temp\" <> 9999.9 AND g.\"max\" <> 9999.9 AND g.\"min\" <> 9999.9 AND s.\"begin\" <= '20000101' AND s.\"end\" >= '20190630' GROUP BY g.\"stn\", g.\"wban\" HAVING COUNT(*) >= 365 * 0.9)") t ~= (sql%([STATIONS_schema, GSOD2019_schema]) "WITH valid_days AS (SELECT g.\"stn\", g.\"wban\", COUNT(*) AS valid_day_count FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2019\" AS g JOIN \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" AS s ON g.\"stn\" = s.\"usaf\" AND g.\"wban\" = s.\"wban\" WHERE s.\"begin\" <= '20000101' AND s.\"end\" >= '20190630' AND g.\"temp\" <> 9999.9 AND g.\"max\" <> 9999.9 AND g.\"min\" <> 9999.9 GROUP BY g.\"stn\", g.\"wban\") SELECT COUNT(*) AS station_count FROM valid_days WHERE valid_day_count >= 0.9 * 365") t := by
  intro t; first | sql_equiv | sorry

-- eq_2_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_2_3 : ∀ t,
    (sql%([STATIONS_schema, GSOD2019_schema]) "WITH valid_stations AS (SELECT \"usaf\", \"wban\" FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" WHERE \"begin\" <= '20000101' AND \"end\" >= '20190630'), daily_valid AS (SELECT g.\"stn\", g.\"wban\", COUNT(*) AS valid_days FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2019\" AS g INNER JOIN valid_stations AS s ON g.\"stn\" = s.\"usaf\" AND g.\"wban\" = s.\"wban\" WHERE g.\"temp\" <> 9999.9 AND g.\"max\" <> 9999.9 AND g.\"min\" <> 9999.9 GROUP BY g.\"stn\", g.\"wban\" HAVING COUNT(*) >= 365 * 0.9) SELECT COUNT(*) AS \"STATION_COUNT\" FROM daily_valid") t ~= (sql%([STATIONS_schema, GSOD2019_schema]) "WITH valid_days AS (SELECT g.\"stn\", g.\"wban\", COUNT(*) AS valid_day_count FROM \"NOAA_DATA\".\"NOAA_GSOD\".\"GSOD2019\" AS g JOIN \"NOAA_DATA\".\"NOAA_GSOD\".\"STATIONS\" AS s ON g.\"stn\" = s.\"usaf\" AND g.\"wban\" = s.\"wban\" WHERE s.\"begin\" <= '20000101' AND s.\"end\" >= '20190630' AND g.\"temp\" <> 9999.9 AND g.\"max\" <> 9999.9 AND g.\"min\" <> 9999.9 GROUP BY g.\"stn\", g.\"wban\") SELECT COUNT(*) AS station_count FROM valid_days WHERE valid_day_count >= 0.9 * 365") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq356
