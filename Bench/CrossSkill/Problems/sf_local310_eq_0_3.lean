import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local310_eq_0_3

CREATE TABLE RACES («race_id» INT, «year» INT, «round» INT, «circuit_id» INT, «name» STRING, «date» STRING, «time» STRING, «url» STRING, «fp1_date» STRING, «fp1_time» STRING, «fp2_date» STRING, «fp2_time» STRING, «fp3_date» STRING, «fp3_time» STRING, «quali_date» STRING, «quali_time» STRING, «sprint_date» STRING, «sprint_time» STRING)
CREATE TABLE RESULTS («result_id» INT, «race_id» INT, «driver_id» INT, «constructor_id» INT, «number» FLOAT, «grid» INT, «position» FLOAT, «position_text» STRING, «position_order» INT, «points» FLOAT, «laps» INT, «time» STRING, «milliseconds» FLOAT, «fastest_lap» FLOAT, «rank» FLOAT, «fastest_lap_time» STRING, «fastest_lap_speed» STRING, «status_id» INT)

theorem eq (t0 : TableRel RACES_schema) (t1 : TableRel RESULTS_schema) :
    (sql%([RACES_schema, RESULTS_schema]) "WITH driver_points AS (SELECT r.\"year\", res.\"driver_id\", SUM(res.\"points\") AS total_points FROM \"F1\".\"F1\".\"RESULTS\" AS res JOIN \"F1\".\"F1\".\"RACES\" AS r ON res.\"race_id\" = r.\"race_id\" GROUP BY r.\"year\", res.\"driver_id\"), max_driver AS (SELECT \"year\", MAX(total_points) AS max_driver_points FROM driver_points GROUP BY \"year\"), constructor_points AS (SELECT r.\"year\", res.\"constructor_id\", SUM(res.\"points\") AS total_points FROM \"F1\".\"F1\".\"RESULTS\" AS res JOIN \"F1\".\"F1\".\"RACES\" AS r ON res.\"race_id\" = r.\"race_id\" GROUP BY r.\"year\", res.\"constructor_id\"), max_constructor AS (SELECT \"year\", MAX(total_points) AS max_constructor_points FROM constructor_points GROUP BY \"year\") SELECT md.\"year\" FROM max_driver AS md JOIN max_constructor AS mc ON md.\"year\" = mc.\"year\" ORDER BY (md.max_driver_points + mc.max_constructor_points) ASC LIMIT 3") t0 t1
  = (sql%([RACES_schema, RESULTS_schema]) "WITH yearly_driver_points AS (SELECT ra.\"year\" AS year, re.\"driver_id\", SUM(re.\"points\") AS total_points FROM \"F1\".\"F1\".\"RESULTS\" AS re JOIN \"F1\".\"F1\".\"RACES\" AS ra ON re.\"race_id\" = ra.\"race_id\" GROUP BY ra.\"year\", re.\"driver_id\"), yearly_constructor_points AS (SELECT ra.\"year\" AS year, re.\"constructor_id\", SUM(re.\"points\") AS total_points FROM \"F1\".\"F1\".\"RESULTS\" AS re JOIN \"F1\".\"F1\".\"RACES\" AS ra ON re.\"race_id\" = ra.\"race_id\" GROUP BY ra.\"year\", re.\"constructor_id\"), max_driver_per_year AS (SELECT year, MAX(total_points) AS max_driver_points FROM yearly_driver_points GROUP BY year), max_constructor_per_year AS (SELECT year, MAX(total_points) AS max_constructor_points FROM yearly_constructor_points GROUP BY year), combined AS (SELECT d.year, d.max_driver_points + c.max_constructor_points AS combined_total FROM max_driver_per_year AS d JOIN max_constructor_per_year AS c ON d.year = c.year) SELECT year FROM combined ORDER BY combined_total ASC LIMIT 3") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local310_eq_0_3
