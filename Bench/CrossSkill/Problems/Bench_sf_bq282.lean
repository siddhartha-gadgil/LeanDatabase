import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq282 — crossskill equivalence(s)

Question: Can you tell me the numeric value of the active council district in Austin which has the highest number of bike trips that start and end within the same district, but not at the same station?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq282

CREATE TABLE BIKESHARE_TRIPS («trip_id» STRING, «subscriber_type» STRING, «bike_id» STRING, «bike_type» STRING, «start_time» INT, «start_station_id» INT, «start_station_name» STRING, «end_station_id» STRING, «end_station_name» STRING, «duration_minutes» INT)
CREATE TABLE BIKESHARE_STATIONS («station_id» INT, «name» STRING, «status» STRING, «location» STRING, «address» STRING, «alternate_name» STRING, «city_asset_number» INT, «property_type» STRING, «number_of_docks» INT, «power_type» STRING, «footprint_length» INT, «footprint_width» FLOAT, «notes» STRING, «council_district» INT, «image» STRING, «modified_date» INT)

theorem eq_0_1 :
    sql%([BIKESHARE_TRIPS_schema, BIKESHARE_STATIONS_schema]) "SELECT s1.\"council_district\" AS output\nFROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" t\nJOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" s1\n  ON TRY_CAST(t.\"start_station_id\" AS INTEGER) = s1.\"station_id\"\nJOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" s2\n  ON TRY_CAST(t.\"end_station_id\" AS INTEGER) = s2.\"station_id\"\nWHERE s1.\"status\" = 'active'\n  AND s2.\"status\" = 'active'\n  AND s1.\"council_district\" = s2.\"council_district\"\n  AND t.\"start_station_id\" != t.\"end_station_id\"\nGROUP BY s1.\"council_district\"\nORDER BY COUNT(*) DESC\nLIMIT 1;" = sql%([BIKESHARE_TRIPS_schema, BIKESHARE_STATIONS_schema]) "SELECT s1.\"council_district\" AS output\nFROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" t\nJOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" s1\n  ON TRY_CAST(t.\"start_station_id\" AS INTEGER) = s1.\"station_id\"\nJOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" s2\n  ON TRY_CAST(t.\"end_station_id\" AS INTEGER) = s2.\"station_id\"\nWHERE s1.\"council_district\" = s2.\"council_district\"\n  AND t.\"start_station_id\" != t.\"end_station_id\"\n  AND s1.\"status\" = 'active'\n  AND s2.\"status\" = 'active'\nGROUP BY s1.\"council_district\"\nORDER BY COUNT(*) DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

-- eq_0_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_2 :
    sql%([BIKESHARE_TRIPS_schema, BIKESHARE_STATIONS_schema]) "SELECT s1.\"council_district\" AS output\nFROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" t\nJOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" s1\n  ON TRY_CAST(t.\"start_station_id\" AS INTEGER) = s1.\"station_id\"\nJOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" s2\n  ON TRY_CAST(t.\"end_station_id\" AS INTEGER) = s2.\"station_id\"\nWHERE s1.\"status\" = 'active'\n  AND s2.\"status\" = 'active'\n  AND s1.\"council_district\" = s2.\"council_district\"\n  AND t.\"start_station_id\" != t.\"end_station_id\"\nGROUP BY s1.\"council_district\"\nORDER BY COUNT(*) DESC\nLIMIT 1;" = sql%([BIKESHARE_TRIPS_schema, BIKESHARE_STATIONS_schema]) "SELECT s1.\"council_district\" AS \"output\"\nFROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" t\nJOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" s1\n  ON t.\"start_station_id\" = s1.\"station_id\"\nJOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" s2\n  ON TRY_CAST(t.\"end_station_id\" AS NUMBER) = s2.\"station_id\"\nWHERE s1.\"status\" = 'active'\n  AND s2.\"status\" = 'active'\n  AND s1.\"council_district\" = s2.\"council_district\"\n  AND t.\"start_station_id\" != TRY_CAST(t.\"end_station_id\" AS NUMBER)\nGROUP BY s1.\"council_district\"\nORDER BY COUNT(*) DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

-- eq_1_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_1_2 :
    sql%([BIKESHARE_TRIPS_schema, BIKESHARE_STATIONS_schema]) "SELECT s1.\"council_district\" AS output\nFROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" t\nJOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" s1\n  ON TRY_CAST(t.\"start_station_id\" AS INTEGER) = s1.\"station_id\"\nJOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" s2\n  ON TRY_CAST(t.\"end_station_id\" AS INTEGER) = s2.\"station_id\"\nWHERE s1.\"council_district\" = s2.\"council_district\"\n  AND t.\"start_station_id\" != t.\"end_station_id\"\n  AND s1.\"status\" = 'active'\n  AND s2.\"status\" = 'active'\nGROUP BY s1.\"council_district\"\nORDER BY COUNT(*) DESC\nLIMIT 1;" = sql%([BIKESHARE_TRIPS_schema, BIKESHARE_STATIONS_schema]) "SELECT s1.\"council_district\" AS \"output\"\nFROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" t\nJOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" s1\n  ON t.\"start_station_id\" = s1.\"station_id\"\nJOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" s2\n  ON TRY_CAST(t.\"end_station_id\" AS NUMBER) = s2.\"station_id\"\nWHERE s1.\"status\" = 'active'\n  AND s2.\"status\" = 'active'\n  AND s1.\"council_district\" = s2.\"council_district\"\n  AND t.\"start_station_id\" != TRY_CAST(t.\"end_station_id\" AS NUMBER)\nGROUP BY s1.\"council_district\"\nORDER BY COUNT(*) DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

end Bench_sf_bq282
