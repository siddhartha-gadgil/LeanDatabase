import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local310_eq_0_1

CREATE TABLE RACES («race_id» INT, «year» INT, «round» INT, «circuit_id» INT, «name» STRING, «date» STRING, «time» STRING, «url» STRING, «fp1_date» STRING, «fp1_time» STRING, «fp2_date» STRING, «fp2_time» STRING, «fp3_date» STRING, «fp3_time» STRING, «quali_date» STRING, «quali_time» STRING, «sprint_date» STRING, «sprint_time» STRING)
CREATE TABLE RESULTS («result_id» INT, «race_id» INT, «driver_id» INT, «constructor_id» INT, «number» FLOAT, «grid» INT, «position» FLOAT, «position_text» STRING, «position_order» INT, «points» FLOAT, «laps» INT, «time» STRING, «milliseconds» FLOAT, «fastest_lap» FLOAT, «rank» FLOAT, «fastest_lap_time» STRING, «fastest_lap_speed» STRING, «status_id» INT)

theorem eq (t0 : TableRel RACES_schema) (t1 : TableRel RESULTS_schema) :
    (sql%([RACES_schema, RESULTS_schema]) "WITH driver_points AS (SELECT r.\"year\", res.\"driver_id\", SUM(res.\"points\") AS total_points FROM \"F1\".\"F1\".\"RESULTS\" AS res JOIN \"F1\".\"F1\".\"RACES\" AS r ON res.\"race_id\" = r.\"race_id\" GROUP BY r.\"year\", res.\"driver_id\"), max_driver AS (SELECT \"year\", MAX(total_points) AS max_driver_points FROM driver_points GROUP BY \"year\"), constructor_points AS (SELECT r.\"year\", res.\"constructor_id\", SUM(res.\"points\") AS total_points FROM \"F1\".\"F1\".\"RESULTS\" AS res JOIN \"F1\".\"F1\".\"RACES\" AS r ON res.\"race_id\" = r.\"race_id\" GROUP BY r.\"year\", res.\"constructor_id\"), max_constructor AS (SELECT \"year\", MAX(total_points) AS max_constructor_points FROM constructor_points GROUP BY \"year\") SELECT md.\"year\" FROM max_driver AS md JOIN max_constructor AS mc ON md.\"year\" = mc.\"year\" ORDER BY (md.max_driver_points + mc.max_constructor_points) ASC LIMIT 3") t0 t1
  ~= (sql%([RACES_schema, RESULTS_schema]) "WITH driver_year AS (SELECT ra.\"year\", r.\"driver_id\", SUM(r.\"points\") AS total_pts FROM \"F1\".\"F1\".\"RESULTS\" AS r JOIN \"F1\".\"F1\".\"RACES\" AS ra ON r.\"race_id\" = ra.\"race_id\" GROUP BY ra.\"year\", r.\"driver_id\"), max_driver AS (SELECT \"year\", MAX(total_pts) AS max_driver_pts FROM driver_year GROUP BY \"year\"), constructor_year AS (SELECT ra.\"year\", r.\"constructor_id\", SUM(r.\"points\") AS total_pts FROM \"F1\".\"F1\".\"RESULTS\" AS r JOIN \"F1\".\"F1\".\"RACES\" AS ra ON r.\"race_id\" = ra.\"race_id\" GROUP BY ra.\"year\", r.\"constructor_id\"), max_constructor AS (SELECT \"year\", MAX(total_pts) AS max_constructor_pts FROM constructor_year GROUP BY \"year\") SELECT d.\"year\" FROM max_driver AS d JOIN max_constructor AS c ON d.\"year\" = c.\"year\" ORDER BY (d.max_driver_pts + c.max_constructor_pts) ASC LIMIT 3") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local310_eq_0_1
