import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local168_eq_1_2

CREATE TABLE SKILLS_DIM («skill_id» INT, «skills» STRING, «type» STRING)
CREATE TABLE SKILLS_JOB_DIM («job_id» INT, «skill_id» INT)
CREATE TABLE JOB_POSTINGS_FACT («job_id» INT, «company_id» INT, «job_title_short» STRING, «job_title» STRING, «job_location» STRING, «job_via» STRING, «job_schedule_type» STRING, «job_work_from_home» INT, «search_location» STRING, «job_posted_date» STRING, «job_no_degree_mention» INT, «job_health_insurance» INT, «job_country» STRING, «salary_rate» STRING, «salary_year_avg» FLOAT, «salary_hour_avg» FLOAT)

theorem eq (t0 : TableRel SKILLS_DIM_schema) (t1 : TableRel SKILLS_JOB_DIM_schema) (t2 : TableRel JOB_POSTINGS_FACT_schema) :
    (sql%([SKILLS_DIM_schema, SKILLS_JOB_DIM_schema, JOB_POSTINGS_FACT_schema]) "/* Find the overall average salary for remote Data Analyst jobs */ /* that have any of the top 3 most frequently demanded skills. */ /* Average is computed per distinct job (not per skill-job pair). */ WITH remote_da_jobs AS (SELECT j.\"job_id\", j.\"salary_year_avg\" FROM \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"JOB_POSTINGS_FACT\" AS j WHERE j.\"job_title_short\" = 'Data Analyst' AND NOT j.\"salary_year_avg\" IS NULL AND j.\"job_work_from_home\" = TRUE), top_skills AS (SELECT sd.\"skill_id\" FROM remote_da_jobs AS rdj JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"SKILLS_JOB_DIM\" AS sjd ON rdj.\"job_id\" = sjd.\"job_id\" JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"SKILLS_DIM\" AS sd ON sjd.\"skill_id\" = sd.\"skill_id\" GROUP BY sd.\"skill_id\" ORDER BY COUNT(*) DESC LIMIT 3), jobs_with_top_skills AS (SELECT DISTINCT rdj.\"job_id\", rdj.\"salary_year_avg\" FROM remote_da_jobs AS rdj JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"SKILLS_JOB_DIM\" AS sjd ON rdj.\"job_id\" = sjd.\"job_id\" JOIN top_skills AS ts ON sjd.\"skill_id\" = ts.\"skill_id\") SELECT AVG(\"salary_year_avg\") AS OVERALL_AVG_SALARY FROM jobs_with_top_skills") t0 t1 t2
  = (sql%([SKILLS_DIM_schema, SKILLS_JOB_DIM_schema, JOB_POSTINGS_FACT_schema]) "WITH data_analyst_remote AS (SELECT jp.\"job_id\", jp.\"salary_year_avg\" FROM \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"JOB_POSTINGS_FACT\" AS jp WHERE jp.\"job_title_short\" = 'Data Analyst' AND NOT jp.\"salary_year_avg\" IS NULL AND jp.\"job_work_from_home\" = TRUE), skill_counts AS (SELECT sd.\"skill_id\", sd.\"skills\", COUNT(*) AS skill_demand FROM data_analyst_remote AS dar JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"SKILLS_JOB_DIM\" AS sjd ON dar.\"job_id\" = sjd.\"job_id\" JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"SKILLS_DIM\" AS sd ON sjd.\"skill_id\" = sd.\"skill_id\" GROUP BY sd.\"skill_id\", sd.\"skills\" ORDER BY skill_demand DESC LIMIT 3), top_skill_jobs AS (SELECT DISTINCT dar.\"job_id\", dar.\"salary_year_avg\" FROM data_analyst_remote AS dar JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"SKILLS_JOB_DIM\" AS sjd ON dar.\"job_id\" = sjd.\"job_id\" JOIN skill_counts AS sc ON sjd.\"skill_id\" = sc.\"skill_id\") SELECT ROUND(CAST(AVG(\"salary_year_avg\") AS DECIMAL), 2) AS \"OVERALL_AVG_SALARY\" FROM top_skill_jobs") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_local168_eq_1_2
