import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace G_sf_bq235

CREATE TABLE INPATIENT_CHARGES_2014 («provider_id» STRING, «provider_name» STRING, «provider_street_address» STRING, «provider_city» STRING, «provider_state» STRING, «provider_zipcode» STRING, «drg_definition» STRING, «hospital_referral_region_description» STRING, «total_discharges» INT, «average_covered_charges» FLOAT, «average_total_payments» FLOAT, «average_medicare_payments» FLOAT)
CREATE TABLE OUTPATIENT_CHARGES_2014 («provider_id» STRING, «provider_name» STRING, «provider_street_address» STRING, «provider_city» STRING, «provider_state» STRING, «provider_zipcode» STRING, «apc» STRING, «hospital_referral_region» STRING, «outpatient_services» INT, «average_estimated_submitted_charges» FLOAT, «average_total_payments» FLOAT)

theorem eq_0_3 : sql%([INPATIENT_CHARGES_2014_schema, OUTPATIENT_CHARGES_2014_schema]) "WITH inpatient_avg AS (SELECT \"provider_id\", \"provider_name\", AVG(\"average_total_payments\") AS avg_inpatient_cost FROM \"CMS_DATA\".\"CMS_MEDICARE\".\"INPATIENT_CHARGES_2014\" GROUP BY \"provider_id\", \"provider_name\"), outpatient_avg AS (SELECT \"provider_id\", \"provider_name\", AVG(\"average_total_payments\") AS avg_outpatient_cost FROM \"CMS_DATA\".\"CMS_MEDICARE\".\"OUTPATIENT_CHARGES_2014\" GROUP BY \"provider_id\", \"provider_name\") SELECT i.\"provider_name\" AS \"Provider_Name\" FROM inpatient_avg AS i INNER JOIN outpatient_avg AS o ON i.\"provider_id\" = o.\"provider_id\" ORDER BY (i.avg_inpatient_cost + o.avg_outpatient_cost) DESC LIMIT 1" = sql%([INPATIENT_CHARGES_2014_schema, OUTPATIENT_CHARGES_2014_schema]) "WITH inpatient_avg AS (SELECT \"provider_id\", \"provider_name\", AVG(\"average_total_payments\") AS avg_inpatient_cost FROM \"CMS_DATA\".\"CMS_MEDICARE\".\"INPATIENT_CHARGES_2014\" GROUP BY \"provider_id\", \"provider_name\"), outpatient_avg AS (SELECT \"provider_id\", \"provider_name\", AVG(\"average_total_payments\") AS avg_outpatient_cost FROM \"CMS_DATA\".\"CMS_MEDICARE\".\"OUTPATIENT_CHARGES_2014\" GROUP BY \"provider_id\", \"provider_name\") SELECT i.\"provider_name\" AS Provider_Name FROM inpatient_avg AS i JOIN outpatient_avg AS o ON i.\"provider_id\" = o.\"provider_id\" ORDER BY (i.avg_inpatient_cost + o.avg_outpatient_cost) DESC LIMIT 1" := by sql_equiv

end G_sf_bq235
