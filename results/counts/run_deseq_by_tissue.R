setwd("/Users/zanemilodeso/Documents/NEU_Local/BINF_6310/final_project/final_project/results/counts")

library(DESeq2)
library(readr)
library(dplyr)

counts <- read_csv("all_sample_counts.csv")
meta <- read_csv("count_metadata.csv")

# first column assumed to be gene IDs
counts_mat <- as.data.frame(counts)
rownames(counts_mat) <- counts_mat$Geneid
counts_mat$Geneid <- NULL
counts_mat <- as.matrix(counts_mat)

# make sure counts are integers
storage.mode(counts_mat) <- "integer"

meta <- as.data.frame(meta)

print(dim(counts_mat))
print(dim(meta))
print(head(meta))
print(all(meta$sample_name %in% colnames(counts_mat)))

# make sure sample order in metadata matches count matrix columns when subsetting
tissues <- unique(meta$tissue_type)

all_results <- list()

for (t in tissues) {
  message("Running tissue: ", t)
  
  meta_sub <- meta %>% filter(tissue_type == t)
  
  # keep only the relevant count columns in the same order as metadata
  count_sub <- counts_mat[, meta_sub$sample_name, drop = FALSE]
  
  # rownames of metadata must match count matrix column names
  rownames(meta_sub) <- meta_sub$sample_name
  
  # condition reference level
  meta_sub$condition <- factor(meta_sub$condition, levels = c("wildtype", "knockout"))
  
  # optional but recommended low-count filter
  keep <- rowSums(count_sub >= 10) >= 2
  count_sub <- count_sub[keep, , drop = FALSE]
  
  dds <- DESeqDataSetFromMatrix(
    countData = count_sub,
    colData = meta_sub,
    design = ~ condition
  )
  
  dds <- DESeq(dds)
  
  res <- results(dds, contrast = c("condition", "knockout", "wildtype"))
  
  res_df <- as.data.frame(res)
  res_df$gene <- rownames(res_df)
  res_df$tissue <- t
  
  all_results[[t]] <- res_df
  
  write.csv(res_df, paste0("DESeq2_", t, "_results.csv"), row.names = FALSE)
}

combined_res <- bind_rows(all_results)

write.csv(combined_res, "combined_tissue_deseq_results.csv", row.names = FALSE)