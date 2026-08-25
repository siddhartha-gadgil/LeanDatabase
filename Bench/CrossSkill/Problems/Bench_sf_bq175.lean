import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq175 — crossskill equivalence(s)

Question: Identify cytoband names on chromosome 1 in the TCGA-KIRC segment allelic dataset where the frequency of amplifications, gains, and heterozygous deletions each rank within the top 11. Calculate these rankings based on the maximum copy number observed across various genomic studies of kidney cancer, reflecting the severity of genetic alterations.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq175

CREATE TABLE CYTOBANDS_HG38 («chromosome» STRING, «cytoband_name» STRING, «hg38_start» INT, «hg38_stop» INT)
CREATE TABLE COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 («project_short_name» STRING, «case_barcode» STRING, «primary_site» STRING, «sample_barcode» STRING, «aliquot_barcode» STRING, «chromosome» STRING, «start_pos» INT, «end_pos» INT, «copy_number» INT, «major_copy_number» INT, «minor_copy_number» INT, «case_gdc_id» STRING, «sample_gdc_id» STRING, «aliquot_gdc_id» STRING, «file_gdc_id» STRING)

-- eq_0_1: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_1 : ∀ t,
    (sql%([CYTOBANDS_HG38_schema, COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23_schema]) "WITH sample_cytoband_max AS (/* For each sample and cytoband on chr1 in TCGA-KIRC, get the max copy number */ SELECT c.\"cytoband_name\", s.\"sample_barcode\", MAX(s.\"copy_number\") AS max_cn FROM \"TCGA_MITELMAN\".\"PROD\".\"CYTOBANDS_HG38\" AS c JOIN \"TCGA_MITELMAN\".\"TCGA_VERSIONED\".\"COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23\" AS s ON s.\"chromosome\" = c.\"chromosome\" AND s.\"start_pos\" < c.\"hg38_stop\" AND s.\"end_pos\" > c.\"hg38_start\" WHERE c.\"chromosome\" = 'chr1' AND s.\"project_short_name\" = 'TCGA-KIRC' GROUP BY c.\"cytoband_name\", s.\"sample_barcode\"), classified AS (/* Classify each sample-cytoband by CNV category based on max copy number */ SELECT \"cytoband_name\", CASE WHEN max_cn >= 4 THEN 'amplification' WHEN max_cn = 3 THEN 'gain' WHEN max_cn = 1 THEN 'heterozygous_deletion' END AS cnv_category FROM sample_cytoband_max), freq_per_cytoband AS (/* Count frequency of each CNV category per cytoband */ SELECT \"cytoband_name\", cnv_category, COUNT(*) AS frequency FROM classified WHERE NOT cnv_category IS NULL GROUP BY \"cytoband_name\", cnv_category), ranked AS (/* Rank cytobands by frequency within each CNV category */ SELECT \"cytoband_name\", cnv_category, frequency, RANK() OVER (PARTITION BY cnv_category ORDER BY frequency DESC) AS rnk FROM freq_per_cytoband) /* Return cytobands where ALL 3 categories rank within top 11 */ SELECT \"cytoband_name\" FROM ranked WHERE rnk <= 11 GROUP BY \"cytoband_name\" HAVING COUNT(DISTINCT cnv_category) = 3 ORDER BY \"cytoband_name\"") t ~= (sql%([CYTOBANDS_HG38_schema, COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23_schema]) "WITH segment_cytoband AS (SELECT b.\"cytoband_name\", c.\"copy_number\", c.\"case_barcode\" FROM \"TCGA_MITELMAN\".\"TCGA_VERSIONED\".\"COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23\" AS c JOIN \"TCGA_MITELMAN\".\"PROD\".\"CYTOBANDS_HG38\" AS b ON c.\"chromosome\" = b.\"chromosome\" AND c.\"start_pos\" < b.\"hg38_stop\" AND c.\"end_pos\" > b.\"hg38_start\" WHERE c.\"project_short_name\" = 'TCGA-KIRC' AND c.\"chromosome\" = 'chr1'), cytoband_case_max AS (SELECT \"cytoband_name\", \"case_barcode\", MAX(\"copy_number\") AS max_cn FROM segment_cytoband GROUP BY \"cytoband_name\", \"case_barcode\"), frequencies AS (SELECT \"cytoband_name\", SUM(CASE WHEN max_cn > 3 THEN 1 ELSE 0 END) AS amp_freq, SUM(CASE WHEN max_cn = 3 THEN 1 ELSE 0 END) AS gain_freq, SUM(CASE WHEN max_cn = 1 THEN 1 ELSE 0 END) AS het_del_freq FROM cytoband_case_max GROUP BY \"cytoband_name\"), ranked AS (SELECT \"cytoband_name\", RANK() OVER (ORDER BY amp_freq DESC) AS amp_rank, RANK() OVER (ORDER BY gain_freq DESC) AS gain_rank, RANK() OVER (ORDER BY het_del_freq DESC) AS het_del_rank FROM frequencies) SELECT \"cytoband_name\" AS OUTPUT FROM ranked WHERE amp_rank <= 11 AND gain_rank <= 11 AND het_del_rank <= 11 ORDER BY \"cytoband_name\" ASC") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq175
