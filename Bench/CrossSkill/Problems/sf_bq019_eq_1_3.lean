import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq019_eq_1_3

CREATE TABLE INPATIENT_CHARGES_2014 («provider_id» STRING, «provider_name» STRING, «provider_street_address» STRING, «provider_city» STRING, «provider_state» STRING, «provider_zipcode» STRING, «drg_definition» STRING, «hospital_referral_region_description» STRING, «total_discharges» INT, «average_covered_charges» FLOAT, «average_total_payments» FLOAT, «average_medicare_payments» FLOAT)

theorem eq (t0 : TableRel INPATIENT_CHARGES_2014_schema) :
    (sql%([INPATIENT_CHARGES_2014_schema]) "WITH top_drg AS (SELECT \"drg_definition\" FROM \"CMS_DATA\".\"CMS_MEDICARE\".\"INPATIENT_CHARGES_2014\" GROUP BY \"drg_definition\" ORDER BY SUM(\"total_discharges\") DESC LIMIT 1), city_stats AS (SELECT ic.\"drg_definition\" AS Diagnosis, ic.\"provider_city\" AS City, ic.\"provider_state\" AS State, SUM(ic.\"total_discharges\") AS total_discharges, ROUND(CAST(SUM(ic.\"average_total_payments\" * ic.\"total_discharges\") AS DOUBLE PRECISION) / SUM(ic.\"total_discharges\"), 0) AS Citywise_Avg_Payments FROM \"CMS_DATA\".\"CMS_MEDICARE\".\"INPATIENT_CHARGES_2014\" AS ic JOIN top_drg AS td ON ic.\"drg_definition\" = td.\"drg_definition\" GROUP BY ic.\"drg_definition\", ic.\"provider_city\", ic.\"provider_state\"), ranked AS (SELECT Diagnosis, City, State, ROW_NUMBER() OVER (ORDER BY total_discharges DESC) AS City_Rank, Citywise_Avg_Payments FROM city_stats) SELECT Diagnosis, City, State, City_Rank, Citywise_Avg_Payments FROM ranked WHERE City_Rank <= 3 ORDER BY City_Rank") t0
  = (sql%([INPATIENT_CHARGES_2014_schema]) "WITH top_drg AS (SELECT \"drg_definition\" FROM \"CMS_DATA\".\"CMS_MEDICARE\".\"INPATIENT_CHARGES_2014\" GROUP BY \"drg_definition\" ORDER BY SUM(\"total_discharges\") DESC LIMIT 1), city_stats AS (SELECT i.\"drg_definition\" AS \"Diagnosis\", i.\"provider_city\" AS \"City\", i.\"provider_state\" AS \"State\", SUM(i.\"total_discharges\") AS total_city_discharges, ROUND(CAST(SUM(i.\"average_total_payments\" * i.\"total_discharges\") AS DOUBLE PRECISION) / SUM(i.\"total_discharges\"), 0) AS \"Citywise_Avg_Payments\" FROM \"CMS_DATA\".\"CMS_MEDICARE\".\"INPATIENT_CHARGES_2014\" AS i JOIN top_drg AS t ON i.\"drg_definition\" = t.\"drg_definition\" GROUP BY i.\"drg_definition\", i.\"provider_city\", i.\"provider_state\" ORDER BY total_city_discharges DESC LIMIT 3) SELECT \"Diagnosis\", \"City\", \"State\", ROW_NUMBER() OVER (ORDER BY total_city_discharges DESC) AS \"City_Rank\", \"Citywise_Avg_Payments\" FROM city_stats ORDER BY \"City_Rank\"") t0
  := by first | sql_equiv | sorry

end N_sf_bq019_eq_1_3
