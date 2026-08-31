import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local168_eq_2_3

CREATE TABLE SKILLS_DIM («skill_id» INT, «skills» STRING, «type» STRING)
CREATE TABLE SKILLS_JOB_DIM («job_id» INT, «skill_id» INT)
CREATE TABLE JOB_POSTINGS_FACT («job_id» INT, «company_id» INT, «job_title_short» STRING, «job_title» STRING, «job_location» STRING, «job_via» STRING, «job_schedule_type» STRING, «job_work_from_home» INT, «search_location» STRING, «job_posted_date» STRING, «job_no_degree_mention» INT, «job_health_insurance» INT, «job_country» STRING, «salary_rate» STRING, «salary_year_avg» FLOAT, «salary_hour_avg» FLOAT)

theorem eq (t0 : TableRel SKILLS_DIM_schema) (t1 : TableRel SKILLS_JOB_DIM_schema) (t2 : TableRel JOB_POSTINGS_FACT_schema) :
    (sql%([SKILLS_DIM_schema, SKILLS_JOB_DIM_schema, JOB_POSTINGS_FACT_schema]) "WITH data_analyst_remote AS (SELECT jp.\"job_id\", jp.\"salary_year_avg\" FROM \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"JOB_POSTINGS_FACT\" AS jp WHERE jp.\"job_title_short\" = 'Data Analyst' AND NOT jp.\"salary_year_avg\" IS NULL AND jp.\"job_work_from_home\" = TRUE), skill_counts AS (SELECT sd.\"skill_id\", sd.\"skills\", COUNT(*) AS skill_demand FROM data_analyst_remote AS dar JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"SKILLS_JOB_DIM\" AS sjd ON dar.\"job_id\" = sjd.\"job_id\" JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"SKILLS_DIM\" AS sd ON sjd.\"skill_id\" = sd.\"skill_id\" GROUP BY sd.\"skill_id\", sd.\"skills\" ORDER BY skill_demand DESC LIMIT 3), top_skill_jobs AS (SELECT DISTINCT dar.\"job_id\", dar.\"salary_year_avg\" FROM data_analyst_remote AS dar JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"SKILLS_JOB_DIM\" AS sjd ON dar.\"job_id\" = sjd.\"job_id\" JOIN skill_counts AS sc ON sjd.\"skill_id\" = sc.\"skill_id\") SELECT ROUND(CAST(AVG(\"salary_year_avg\") AS DECIMAL), 2) AS \"OVERALL_AVG_SALARY\" FROM top_skill_jobs") t0 t1 t2
  = (sql%([SKILLS_DIM_schema, SKILLS_JOB_DIM_schema, JOB_POSTINGS_FACT_schema]) "WITH remote_da_jobs AS (SELECT \"job_id\", \"salary_year_avg\" FROM \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"JOB_POSTINGS_FACT\" WHERE \"job_title_short\" = 'Data Analyst' AND \"job_work_from_home\" = TRUE), top_3_skills AS (SELECT sjd.\"skill_id\", COUNT(*) AS demand_count FROM remote_da_jobs AS rdj JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"SKILLS_JOB_DIM\" AS sjd ON rdj.\"job_id\" = sjd.\"job_id\" JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"SKILLS_DIM\" AS sd ON sjd.\"skill_id\" = sd.\"skill_id\" GROUP BY sjd.\"skill_id\" ORDER BY demand_count DESC LIMIT 3), skill_avg_salary AS (SELECT t3.\"skill_id\", ROUND(CAST(AVG(rdj.\"salary_year_avg\") AS DECIMAL), 1) AS avg_salary FROM top_3_skills AS t3 JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"SKILLS_JOB_DIM\" AS sjd ON t3.\"skill_id\" = sjd.\"skill_id\" JOIN remote_da_jobs AS rdj ON sjd.\"job_id\" = rdj.\"job_id\" WHERE NOT rdj.\"salary_year_avg\" IS NULL GROUP BY t3.\"skill_id\") SELECT ROUND(CAST(AVG(avg_salary) AS DECIMAL), 1) AS \"OVERALL_AVG_SALARY\" FROM skill_avg_salary") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_local168_eq_2_3
