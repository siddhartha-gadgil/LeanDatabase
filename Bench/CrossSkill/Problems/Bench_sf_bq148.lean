import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq148 — crossskill equivalence(s)

Question: Could you identify the top five protein-coding genes that exhibit the highest variance in their expression levels (measured as fpkm_uq_unstranded) specifically within 'Solid Tissue Normal' samples? Please limit the analysis to TCGA-BRCA project cases that include at least one 'Solid Tissue Normal' sample type.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq148

CREATE TABLE RNASEQ_HG38_GDC_R35 («project_short_name» STRING, «primary_site» STRING, «case_barcode» STRING, «sample_barcode» STRING, «aliquot_barcode» STRING, «gene_name» STRING, «gene_type» STRING, «Ensembl_gene_id» STRING, «Ensembl_gene_id_v» STRING, «unstranded» INT, «stranded_first» INT, «stranded_second» INT, «tpm_unstranded» FLOAT, «fpkm_unstranded» FLOAT, «fpkm_uq_unstranded» FLOAT, «sample_type_name» STRING, «case_gdc_id» STRING, «sample_gdc_id» STRING, «aliquot_gdc_id» STRING, «file_gdc_id» STRING, «platform» STRING)

theorem eq_0_1 :
    sql%([RNASEQ_HG38_GDC_R35_schema]) "SELECT \"Ensembl_gene_id_v\", VARIANCE(\"fpkm_uq_unstranded\") as VAR_FPKM\nFROM \"TCGA\".\"TCGA_VERSIONED\".\"RNASEQ_HG38_GDC_R35\"\nWHERE \"project_short_name\" = 'TCGA-BRCA' \nAND \"sample_type_name\" = 'Solid Tissue Normal'\nAND \"gene_type\" = 'protein_coding'\nGROUP BY \"Ensembl_gene_id_v\"\nORDER BY VAR_FPKM DESC\nLIMIT 5;" = sql%([RNASEQ_HG38_GDC_R35_schema]) "SELECT\n  \"Ensembl_gene_id_v\",\n  VARIANCE(\"fpkm_uq_unstranded\") AS \"VAR_FPKM\"\nFROM \"TCGA\".\"TCGA_VERSIONED\".\"RNASEQ_HG38_GDC_R35\"\nWHERE \"project_short_name\" = 'TCGA-BRCA'\n  AND \"gene_type\" = 'protein_coding'\n  AND \"sample_type_name\" = 'Solid Tissue Normal'\n  AND \"case_barcode\" IN (\n    SELECT DISTINCT \"case_barcode\"\n    FROM \"TCGA\".\"TCGA_VERSIONED\".\"RNASEQ_HG38_GDC_R35\"\n    WHERE \"project_short_name\" = 'TCGA-BRCA'\n      AND \"sample_type_name\" = 'Solid Tissue Normal'\n  )\nGROUP BY \"Ensembl_gene_id_v\"\nORDER BY \"VAR_FPKM\" DESC NULLS LAST\nLIMIT 5;" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : RNASEQ_HG38_GDC_R35 "\"project_short_name\" = 'TCGA-BRCA'"
HYPOTHESIS hyp0_2_1 : RNASEQ_HG38_GDC_R35 "\"sample_type_name\" = 'Solid Tissue Normal'"
HYPOTHESIS hyp0_2_2 : RNASEQ_HG38_GDC_R35 "\"gene_type\" = 'protein_coding'"
theorem eq_0_2 (t : TableRel RNASEQ_HG38_GDC_R35_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) (h2 : hyp0_2_2 t) :
    (sql%([RNASEQ_HG38_GDC_R35_schema]) "SELECT \"Ensembl_gene_id_v\", VARIANCE(\"fpkm_uq_unstranded\") as VAR_FPKM\nFROM \"TCGA\".\"TCGA_VERSIONED\".\"RNASEQ_HG38_GDC_R35\"\nWHERE \"project_short_name\" = 'TCGA-BRCA' \nAND \"sample_type_name\" = 'Solid Tissue Normal'\nAND \"gene_type\" = 'protein_coding'\nGROUP BY \"Ensembl_gene_id_v\"\nORDER BY VAR_FPKM DESC\nLIMIT 5;") t = (sql%([RNASEQ_HG38_GDC_R35_schema]) "SELECT\n    r.\"Ensembl_gene_id_v\",\n    VARIANCE(r.\"fpkm_uq_unstranded\") AS \"VAR_FPKM\"\nFROM \"TCGA\".\"TCGA_VERSIONED\".\"RNASEQ_HG38_GDC_R35\" r\nWHERE r.\"project_short_name\" = 'TCGA-BRCA'\n  AND r.\"sample_type_name\" = 'Solid Tissue Normal'\n  AND r.\"gene_type\" = 'protein_coding'\nGROUP BY r.\"Ensembl_gene_id_v\"\nORDER BY \"VAR_FPKM\" DESC\nLIMIT 5;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : RNASEQ_HG38_GDC_R35 "\"project_short_name\" = 'TCGA-BRCA'"
HYPOTHESIS hyp1_2_1 : RNASEQ_HG38_GDC_R35 "\"gene_type\" = 'protein_coding'"
HYPOTHESIS hyp1_2_2 : RNASEQ_HG38_GDC_R35 "\"sample_type_name\" = 'Solid Tissue Normal'"
theorem eq_1_2 (t : TableRel RNASEQ_HG38_GDC_R35_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) (h2 : hyp1_2_2 t) :
    (sql%([RNASEQ_HG38_GDC_R35_schema]) "SELECT\n  \"Ensembl_gene_id_v\",\n  VARIANCE(\"fpkm_uq_unstranded\") AS \"VAR_FPKM\"\nFROM \"TCGA\".\"TCGA_VERSIONED\".\"RNASEQ_HG38_GDC_R35\"\nWHERE \"project_short_name\" = 'TCGA-BRCA'\n  AND \"gene_type\" = 'protein_coding'\n  AND \"sample_type_name\" = 'Solid Tissue Normal'\n  AND \"case_barcode\" IN (\n    SELECT DISTINCT \"case_barcode\"\n    FROM \"TCGA\".\"TCGA_VERSIONED\".\"RNASEQ_HG38_GDC_R35\"\n    WHERE \"project_short_name\" = 'TCGA-BRCA'\n      AND \"sample_type_name\" = 'Solid Tissue Normal'\n  )\nGROUP BY \"Ensembl_gene_id_v\"\nORDER BY \"VAR_FPKM\" DESC NULLS LAST\nLIMIT 5;") t = (sql%([RNASEQ_HG38_GDC_R35_schema]) "SELECT\n    r.\"Ensembl_gene_id_v\",\n    VARIANCE(r.\"fpkm_uq_unstranded\") AS \"VAR_FPKM\"\nFROM \"TCGA\".\"TCGA_VERSIONED\".\"RNASEQ_HG38_GDC_R35\" r\nWHERE r.\"project_short_name\" = 'TCGA-BRCA'\n  AND r.\"sample_type_name\" = 'Solid Tissue Normal'\n  AND r.\"gene_type\" = 'protein_coding'\nGROUP BY r.\"Ensembl_gene_id_v\"\nORDER BY \"VAR_FPKM\" DESC\nLIMIT 5;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq148
