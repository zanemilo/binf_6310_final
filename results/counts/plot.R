setwd("/Users/zanemilodeso/Documents/NEU_Local/BINF_6310/final_project/final_project/results/counts")

library(readr)
library(dplyr)
library(ggplot2)

combined_res <- read_csv("combined_tissue_deseq_results.csv")

plot_df <- combined_res %>%
  filter(!is.na(log2FoldChange), !is.na(padj)) %>%
  filter(padj < 0.05, abs(log2FoldChange) >= 1) %>%
  mutate(
    direction = if_else(log2FoldChange > 0, "Up", "Down"),
    tissue = factor(tissue, levels = c("TIP", "BIP", "RA", "LD", "PMM", "SOL", "GAS", "EDL", "TA"))
  )

count_df <- plot_df %>%
  group_by(tissue, direction) %>%
  summarise(n = n(), .groups = "drop")

up_counts <- count_df %>%
  filter(direction == "Up") %>%
  mutate(y = 7)

down_counts <- count_df %>%
  filter(direction == "Down") %>%
  mutate(y = -7)

p <- ggplot(plot_df, aes(x = tissue, y = log2FoldChange, color = tissue)) +
  geom_jitter(width = 0.22, alpha = 0.5, size = 1.2, show.legend = FALSE) +
  geom_hline(yintercept = 0, linetype = "solid") +
  geom_text(data = up_counts, aes(x = tissue, y = y, label = paste0("n = ", n)),
            inherit.aes = FALSE, size = 3) +
  geom_text(data = down_counts, aes(x = tissue, y = y, label = paste0("n = ", n)),
            inherit.aes = FALSE, size = 3) +
  labs(
    title = "Differentially Expressed Genes by Tissue",
    x = NULL,
    y = "log2(Fold Change)"
  ) +
  coord_cartesian(ylim = c(-8, 8)) +
  theme_minimal()

print(p)

ggsave("tissue_up_down_plot.png", plot = p, width = 10, height = 6, dpi = 300)