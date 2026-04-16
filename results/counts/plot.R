library(readr)
library(dplyr)
library(ggplot2)
library(UpSetR)

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


deg_df <- combined_res %>%
  filter(!is.na(log2FoldChange), !is.na(padj)) %>%
  filter(padj < 0.05, abs(log2FoldChange) >= 1)

regions <- c("TIP", "BIP", "RA", "LD", "PMM", "SOL", "GAS", "EDL", "TA")
region_colors <- c(
  "TIP" = "darkgreen", "BIP" = "olivedrab", "RA" = "salmon",
  "LD" = "tomato", "PMM" = "darkred", "GAS" = "royalblue",
  "SOL" = "cyan3", "EDL" = "forestgreen", "TA" = "navy"
)
# --- Fig 4b: Upregulated DEGs ---
up_df <- deg_df %>% filter(log2FoldChange > 0)

up_list <- lapply(setNames(regions, regions), function(r) {
  up_df %>% filter(tissue == r) %>% pull(gene)  # replace 'gene' with your gene ID column name
})

# --- Fig 4c: Downregulated DEGs ---
down_df <- deg_df %>% filter(log2FoldChange < 0)

down_list <- lapply(setNames(regions, regions), function(r) {
  down_df %>% filter(tissue == r) %>% pull(gene)
})

queries <- lapply(seq_along(regions), function(i) {
  list(query = intersects, params = list(regions[i]), 
       color = region_colors[regions[i]], active = TRUE)
})

png("fig4b_upset_up.png", width = 2400, height = 1600, res = 300)
upset(
  fromList(up_list),
  order.by = "freq",
  nsets = 9,
  nintersects = 10,
  sets.bar.color = region_colors[regions],
  mainbar.y.label = "Intersect Gene Number",
  sets.x.label = "Gene Number",
  text.scale = 1.3
)
dev.off()

png("fig4c_upset_down.png", width = 2400, height = 1600, res = 300)
upset(fromList(down_list), order.by = "freq", nsets = 9,
      mainbar.y.label = "Intersection Size",
      sets.x.label = "DEGs per Region")
dev.off()
