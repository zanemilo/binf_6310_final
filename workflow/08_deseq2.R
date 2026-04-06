library(DESeq2)


count_matrix <- read.csv('../results/counts/all_sample_counts.csv', row.names=1)
metadata <- read.csv('../results/counts/count_metadata.csv', row.names=1)
dataset <- DESeqDataSetFromMatrix(countData = count_matrix,
                       colData = metadata,
                       design = ~condition)
result <- DESeq(dataset)
res <- results(result)
write.csv(as.data.frame(res), '../results/deseq2/deseq2_results.csv')
