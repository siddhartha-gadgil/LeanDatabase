import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq148_eq_0_1

CREATE TABLE RNASEQ_HG38_GDC_R35 («project_short_name» STRING, «primary_site» STRING, «case_barcode» STRING, «sample_barcode» STRING, «aliquot_barcode» STRING, «gene_name» STRING, «gene_type» STRING, «Ensembl_gene_id» STRING, «Ensembl_gene_id_v» STRING, «unstranded» INT, «stranded_first» INT, «stranded_second» INT, «tpm_unstranded» FLOAT, «fpkm_unstranded» FLOAT, «fpkm_uq_unstranded» FLOAT, «sample_type_name» STRING, «case_gdc_id» STRING, «sample_gdc_id» STRING, «aliquot_gdc_id» STRING, «file_gdc_id» STRING, «platform» STRING)

theorem eq (t0 : TableRel RNASEQ_HG38_GDC_R35_schema) :
    (sql%([RNASEQ_HG38_GDC_R35_schema]) "SELECT \"Ensembl_gene_id_v\", VAR_SAMP(\"fpkm_uq_unstranded\") AS VAR_FPKM FROM \"TCGA\".\"TCGA_VERSIONED\".\"RNASEQ_HG38_GDC_R35\" WHERE \"project_short_name\" = 'TCGA-BRCA' AND \"sample_type_name\" = 'Solid Tissue Normal' AND \"gene_type\" = 'protein_coding' GROUP BY \"Ensembl_gene_id_v\" ORDER BY VAR_FPKM DESC LIMIT 5") t0
  = (sql%([RNASEQ_HG38_GDC_R35_schema]) "SELECT \"Ensembl_gene_id_v\", VAR_SAMP(\"fpkm_uq_unstranded\") AS \"VAR_FPKM\" FROM \"TCGA\".\"TCGA_VERSIONED\".\"RNASEQ_HG38_GDC_R35\" WHERE \"project_short_name\" = 'TCGA-BRCA' AND \"gene_type\" = 'protein_coding' AND \"sample_type_name\" = 'Solid Tissue Normal' AND \"case_barcode\" IN (SELECT DISTINCT \"case_barcode\" FROM \"TCGA\".\"TCGA_VERSIONED\".\"RNASEQ_HG38_GDC_R35\" WHERE \"project_short_name\" = 'TCGA-BRCA' AND \"sample_type_name\" = 'Solid Tissue Normal') GROUP BY \"Ensembl_gene_id_v\" ORDER BY \"VAR_FPKM\" DESC NULLS LAST LIMIT 5") t0
  := by first | sql_equiv | sorry

end N_sf_bq148_eq_0_1
