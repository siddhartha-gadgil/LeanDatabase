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
    (sql%([CYTOBANDS_HG38_schema, COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23_schema]) "WITH sample_cytoband_max AS (\n  -- For each sample and cytoband on chr1 in TCGA-KIRC, get the max copy number\n  SELECT \n    c.\"cytoband_name\",\n    s.\"sample_barcode\",\n    MAX(s.\"copy_number\") AS max_cn\n  FROM \"TCGA_MITELMAN\".\"PROD\".\"CYTOBANDS_HG38\" c\n  JOIN \"TCGA_MITELMAN\".\"TCGA_VERSIONED\".\"COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23\" s\n    ON s.\"chromosome\" = c.\"chromosome\"\n    AND s.\"start_pos\" < c.\"hg38_stop\"\n    AND s.\"end_pos\" > c.\"hg38_start\"\n  WHERE c.\"chromosome\" = 'chr1'\n    AND s.\"project_short_name\" = 'TCGA-KIRC'\n  GROUP BY c.\"cytoband_name\", s.\"sample_barcode\"\n),\nclassified AS (\n  -- Classify each sample-cytoband by CNV category based on max copy number\n  SELECT \n    \"cytoband_name\",\n    CASE \n      WHEN max_cn >= 4 THEN 'amplification'\n      WHEN max_cn = 3 THEN 'gain'\n      WHEN max_cn = 1 THEN 'heterozygous_deletion'\n    END AS cnv_category\n  FROM sample_cytoband_max\n),\nfreq_per_cytoband AS (\n  -- Count frequency of each CNV category per cytoband\n  SELECT \n    \"cytoband_name\",\n    cnv_category,\n    COUNT(*) AS frequency\n  FROM classified\n  WHERE cnv_category IS NOT NULL\n  GROUP BY \"cytoband_name\", cnv_category\n),\nranked AS (\n  -- Rank cytobands by frequency within each CNV category\n  SELECT \n    \"cytoband_name\",\n    cnv_category,\n    frequency,\n    RANK() OVER (PARTITION BY cnv_category ORDER BY frequency DESC) AS rnk\n  FROM freq_per_cytoband\n)\n-- Return cytobands where ALL 3 categories rank within top 11\nSELECT \"cytoband_name\"\nFROM ranked\nWHERE rnk <= 11\nGROUP BY \"cytoband_name\"\nHAVING COUNT(DISTINCT cnv_category) = 3\nORDER BY \"cytoband_name\";") t ~= (sql%([CYTOBANDS_HG38_schema, COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23_schema]) "WITH segment_cytoband AS (\n    SELECT \n        b.\"cytoband_name\",\n        c.\"copy_number\",\n        c.\"case_barcode\"\n    FROM \"TCGA_MITELMAN\".\"TCGA_VERSIONED\".\"COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23\" c\n    JOIN \"TCGA_MITELMAN\".\"PROD\".\"CYTOBANDS_HG38\" b\n        ON c.\"chromosome\" = b.\"chromosome\"\n        AND c.\"start_pos\" < b.\"hg38_stop\" \n        AND c.\"end_pos\" > b.\"hg38_start\"\n    WHERE c.\"project_short_name\" = 'TCGA-KIRC' \n      AND c.\"chromosome\" = 'chr1'\n),\ncytoband_case_max AS (\n    SELECT \n        \"cytoband_name\",\n        \"case_barcode\",\n        MAX(\"copy_number\") AS max_cn\n    FROM segment_cytoband\n    GROUP BY \"cytoband_name\", \"case_barcode\"\n),\nfrequencies AS (\n    SELECT \n        \"cytoband_name\",\n        SUM(CASE WHEN max_cn > 3 THEN 1 ELSE 0 END) AS amp_freq,\n        SUM(CASE WHEN max_cn = 3 THEN 1 ELSE 0 END) AS gain_freq,\n        SUM(CASE WHEN max_cn = 1 THEN 1 ELSE 0 END) AS het_del_freq\n    FROM cytoband_case_max\n    GROUP BY \"cytoband_name\"\n),\nranked AS (\n    SELECT \n        \"cytoband_name\",\n        RANK() OVER (ORDER BY amp_freq DESC) AS amp_rank,\n        RANK() OVER (ORDER BY gain_freq DESC) AS gain_rank,\n        RANK() OVER (ORDER BY het_del_freq DESC) AS het_del_rank\n    FROM frequencies\n)\nSELECT \"cytoband_name\" AS OUTPUT\nFROM ranked\nWHERE amp_rank <= 11 \n  AND gain_rank <= 11 \n  AND het_del_rank <= 11\nORDER BY \"cytoband_name\" ASC") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq175
