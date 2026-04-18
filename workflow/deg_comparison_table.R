library(ggplot2)

regions  <- c("TIP","BIP","RA","LD","PMM","SOL","GAS","EDL","TA")
paper_up <- c(255,175,201,400,160,245,444,213,167)
ours_up  <- c(278,168,227,431,154,259,485,233,161)
paper_dn <- c(160,156,306,291,187, 82,121,120,131)
ours_dn  <- c(187,181,299,376,221,116,128,149,155)

df <- data.frame(
  region   = factor(rep(regions, 2), levels = regions),
  paper    = c(paper_up, paper_dn),
  ours     = c(ours_up,  ours_dn),
  diff     = c(ours_up - paper_up, ours_dn - paper_dn),
  direction = rep(c("Upregulated","Downregulated"), each = 9)
)

html <- '<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<style>
  body { font-family: Arial, sans-serif; padding: 30px; background: white; }
  h2 { font-size: 16px; font-weight: bold; margin-bottom: 4px; }
  p  { font-size: 12px; color: #666; margin-top: 0; margin-bottom: 16px; }
  table { border-collapse: collapse; width: 100%; font-size: 13px; }
  th { padding: 8px 12px; text-align: center; font-weight: bold; border-bottom: 2px solid #333; }
  th.region { text-align: left; }
  td { padding: 7px 12px; text-align: center; border-bottom: 1px solid #e0e0e0; }
  td.region { text-align: left; font-weight: bold; }
  .up    { color: #c0392b; }
  .dn    { color: #1a5276; }
  .pos   { color: #1e8449; font-size: 12px; }
  .neg   { color: #c0392b; font-size: 12px; }
  .divider { border-left: 1px solid #ccc; }
  .section { font-size: 11px; color: #888; }
</style></head><body>
<h2>DEG counts: reproduced vs. published</h2>
<p>KO vs WT per muscle region &mdash; FDR &lt; 0.05, |log2FC| &ge; 1</p>
<table>
<thead>
  <tr>
    <th class="region" rowspan="2">Region</th>
    <th colspan="3" class="up">Upregulated</th>
    <th colspan="3" class="dn divider">Downregulated</th>
  </tr>
  <tr>
    <th class="section">Paper</th>
    <th class="section">Ours</th>
    <th class="section">Diff</th>
    <th class="section divider">Paper</th>
    <th class="section">Ours</th>
    <th class="section">Diff</th>
  </tr>
</thead>
<tbody>'

for (i in seq_along(regions)) {
  r  <- regions[i]
  pu <- paper_up[i]; ou <- ours_up[i]; du <- ours_up[i] - paper_up[i]
  pd <- paper_dn[i]; od <- ours_dn[i]; dd <- ours_dn[i] - paper_dn[i]
  du_str <- ifelse(du > 0, paste0('+', du), as.character(du))
  dd_str <- ifelse(dd > 0, paste0('+', dd), as.character(dd))
  du_cls <- ifelse(du > 0, 'pos', ifelse(du < 0, 'neg', 'section'))
  dd_cls <- ifelse(dd > 0, 'pos', ifelse(dd < 0, 'neg', 'section'))
  html <- paste0(html, '\n<tr>',
    '<td class="region">', r, '</td>',
    '<td class="up">', pu, '</td>',
    '<td class="up">', ou, '</td>',
    '<td class="', du_cls, '">', du_str, '</td>',
    '<td class="dn divider">', pd, '</td>',
    '<td class="dn">', od, '</td>',
    '<td class="', dd_cls, '">', dd_str, '</td>',
    '</tr>')
}

html <- paste0(html, '\n</tbody></table></body></html>')

writeLines(html, "/scratch/polyak.i/binf_6310_final/results/figures/deg_comparison_table.html")
message("Done: deg_comparison_table.html")
