import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq044 — a proven cross-skill equivalence

Question: For bladder cancer patients who have mutations in the CDKN2A (cyclin-dependent kinase inhibitor 2A) gene, using clinical data from the Genomic Data Commons Release 39, what types of mutations are they, what is their gender, vital status, and days to death - and for four downstream genes (MDM2 (MDM2 proto-oncogene), TP53 (tumor protein p53), CDKN1A (cyclin-dependent kinase inhibitor 1A), and CCNE1 (Cyclin E1)), what are the gene expression levels for each patient?

Two independently-written SQL answers to the same question, proved equivalent for *all*
table contents by `sql_equiv` (not just on one instance).
-/

namespace P_sf_bq044

CREATE TABLE SOMATIC_MUTATION_HG19_DCC_2017_02 («project_short_name» STRING, «case_barcode» STRING, «Variant_Type» STRING, «Hugo_Symbol» STRING)
CREATE TABLE RNASEQ_HG19_GDC_2017_02 («project_short_name» STRING, «case_barcode» STRING, «HGNC_gene_symbol» STRING, «normalized_count» FLOAT)
CREATE TABLE CLINICAL_GDC_2019_06 («case_barcode» STRING, «project_short_name» STRING, «days_to_death» INT, «gender» STRING, «vital_status» STRING)
CREATE TABLE CLINICAL_GDC_R39 («submitter_id» STRING, «demo__gender» STRING, «demo__vital_status» STRING, «demo__days_to_death» INT)

/-- Variant A:  SELECT m."case_barcode" AS "case_barcode", r."HGNC_gene_symbol" AS "HGNC_gene_symbol", m."Variant_Type" AS "Variant_Type", c."demo__gender" AS "GENDER", c."demo
    Variant B:  SELECT sm."case_barcode", rna."HGNC_gene_symbol", sm."Variant_Type", c."demo__gender" AS "GENDER", c."demo__vital_status" AS "vital_status", c."demo__days_to_de -/
theorem equivalent :
    sql%([SOMATIC_MUTATION_HG19_DCC_2017_02_schema, RNASEQ_HG19_GDC_2017_02_schema, CLINICAL_GDC_2019_06_schema, CLINICAL_GDC_R39_schema]) "SELECT m.\"case_barcode\" AS \"case_barcode\", r.\"HGNC_gene_symbol\" AS \"HGNC_gene_symbol\", m.\"Variant_Type\" AS \"Variant_Type\", c.\"demo__gender\" AS \"GENDER\", c.\"demo__vital_status\" AS \"vital_status\", c.\"demo__days_to_death\" AS \"days_to_death\", r.\"normalized_count\" AS \"normalized_count\" FROM \"TCGA\".\"TCGA_VERSIONED\".\"SOMATIC_MUTATION_HG19_DCC_2017_02\" AS m JOIN \"TCGA\".\"TCGA_VERSIONED\".\"CLINICAL_GDC_R39\" AS c ON m.\"case_barcode\" = c.\"submitter_id\" JOIN \"TCGA\".\"TCGA_VERSIONED\".\"RNASEQ_HG19_GDC_2017_02\" AS r ON m.\"case_barcode\" = r.\"case_barcode\" WHERE m.\"Hugo_Symbol\" = 'CDKN2A' AND m.\"project_short_name\" = 'TCGA-BLCA' AND r.\"HGNC_gene_symbol\" IN ('MDM2', 'TP53', 'CDKN1A', 'CCNE1') ORDER BY m.\"case_barcode\", r.\"HGNC_gene_symbol\""
      = sql%([SOMATIC_MUTATION_HG19_DCC_2017_02_schema, RNASEQ_HG19_GDC_2017_02_schema, CLINICAL_GDC_2019_06_schema, CLINICAL_GDC_R39_schema]) "SELECT sm.\"case_barcode\", rna.\"HGNC_gene_symbol\", sm.\"Variant_Type\", c.\"demo__gender\" AS \"GENDER\", c.\"demo__vital_status\" AS \"vital_status\", c.\"demo__days_to_death\" AS \"days_to_death\", rna.\"normalized_count\" FROM \"TCGA\".\"TCGA_VERSIONED\".\"SOMATIC_MUTATION_HG19_DCC_2017_02\" AS sm JOIN \"TCGA\".\"TCGA_VERSIONED\".\"CLINICAL_GDC_R39\" AS c ON sm.\"case_barcode\" = c.\"submitter_id\" JOIN \"TCGA\".\"TCGA_VERSIONED\".\"RNASEQ_HG19_GDC_2017_02\" AS rna ON sm.\"case_barcode\" = rna.\"case_barcode\" AND rna.\"HGNC_gene_symbol\" IN ('MDM2', 'TP53', 'CDKN1A', 'CCNE1') WHERE sm.\"Hugo_Symbol\" = 'CDKN2A' AND sm.\"project_short_name\" = 'TCGA-BLCA' ORDER BY sm.\"case_barcode\", rna.\"normalized_count\" DESC" := by sql_equiv

end P_sf_bq044
