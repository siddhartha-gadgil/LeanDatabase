import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq355_eq_0_3

CREATE TABLE PERSON («race_concept_id» INT, «ethnicity_concept_id» INT, «location_id» INT, «provider_id» INT, «care_site_id» INT, «person_source_value» STRING, «gender_source_value» STRING, «gender_source_concept_id» INT, «race_source_value» STRING, «race_source_concept_id» INT, «ethnicity_source_value» STRING, «ethnicity_source_concept_id» INT, «person_id» INT, «gender_concept_id» INT, «year_of_birth» INT, «month_of_birth» INT, «day_of_birth» INT, «birth_datetime» INT)
CREATE TABLE CONCEPT_ANCESTOR («ancestor_concept_id» INT, «descendant_concept_id» INT, «min_levels_of_separation» INT, «max_levels_of_separation» INT)
CREATE TABLE CONCEPT («concept_id» INT, «concept_name» STRING, «domain_id» STRING, «vocabulary_id» STRING, «concept_class_id» STRING, «standard_concept» STRING, «concept_code» STRING, «valid_start_date» STRING, «valid_end_date» STRING, «invalid_reason» STRING)
CREATE TABLE DRUG_EXPOSURE («drug_type_concept_id» INT, «stop_reason» STRING, «refills» INT, «quantity» FLOAT, «days_supply» INT, «sig» STRING, «route_concept_id» INT, «lot_number» STRING, «provider_id» INT, «visit_occurrence_id» INT, «visit_detail_id» INT, «drug_source_value» STRING, «drug_source_concept_id» INT, «route_source_value» STRING, «dose_unit_source_value» STRING, «drug_exposure_id» INT, «person_id» INT, «drug_concept_id» INT, «drug_exposure_start_date» STRING, «drug_exposure_start_datetime» INT, «drug_exposure_end_date» STRING, «drug_exposure_end_datetime» INT, «verbatim_end_date» STRING)

theorem eq (t0 : TableRel PERSON_schema) (t1 : TableRel CONCEPT_ANCESTOR_schema) (t2 : TableRel CONCEPT_schema) (t3 : TableRel DRUG_EXPOSURE_schema) :
    (sql%([PERSON_schema, CONCEPT_ANCESTOR_schema, CONCEPT_schema, DRUG_EXPOSURE_schema]) "WITH quinapril_concept AS (SELECT \"concept_id\" FROM \"CMS_DATA\".\"CMS_SYNTHETIC_PATIENT_DATA_OMOP\".\"CONCEPT\" WHERE \"concept_code\" = '35208' AND \"vocabulary_id\" = 'RxNorm'), related_drugs AS (SELECT DISTINCT ca.\"descendant_concept_id\" AS \"drug_concept_id\" FROM \"CMS_DATA\".\"CMS_SYNTHETIC_PATIENT_DATA_OMOP\".\"CONCEPT_ANCESTOR\" AS ca JOIN quinapril_concept AS qc ON ca.\"ancestor_concept_id\" = qc.\"concept_id\"), quinapril_users AS (SELECT COUNT(DISTINCT de.\"person_id\") AS user_count FROM \"CMS_DATA\".\"CMS_SYNTHETIC_PATIENT_DATA_OMOP\".\"DRUG_EXPOSURE\" AS de JOIN related_drugs AS rd ON de.\"drug_concept_id\" = rd.\"drug_concept_id\"), total_persons AS (SELECT COUNT(*) AS total_count FROM \"CMS_DATA\".\"CMS_SYNTHETIC_PATIENT_DATA_OMOP\".\"PERSON\") SELECT ROUND(CAST((tp.total_count - qu.user_count) * 100.0 AS DOUBLE PRECISION) / tp.total_count, 6) AS \"OUTPUT\" FROM total_persons AS tp CROSS JOIN quinapril_users AS qu") t0 t1 t2 t3
  ~= (sql%([PERSON_schema, CONCEPT_ANCESTOR_schema, CONCEPT_schema, DRUG_EXPOSURE_schema]) "SELECT ROUND(CAST((1 - COUNT(DISTINCT de.\"person_id\") / CAST((SELECT COUNT(*) FROM \"CMS_DATA\".\"CMS_SYNTHETIC_PATIENT_DATA_OMOP\".\"PERSON\") AS DOUBLE PRECISION)) * 100 AS DECIMAL), 6) AS OUTPUT FROM \"CMS_DATA\".\"CMS_SYNTHETIC_PATIENT_DATA_OMOP\".\"DRUG_EXPOSURE\" AS de JOIN \"CMS_DATA\".\"CMS_SYNTHETIC_PATIENT_DATA_OMOP\".\"CONCEPT_ANCESTOR\" AS ca ON de.\"drug_concept_id\" = ca.\"descendant_concept_id\" WHERE ca.\"ancestor_concept_id\" = 1331235") t0 t1 t2 t3
  := by first | sql_equiv | sorry

end N_sf_bq355_eq_0_3
