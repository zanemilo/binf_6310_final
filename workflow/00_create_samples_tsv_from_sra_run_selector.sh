#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   bash workflow/00_make_samples_tsv.sh path/to/sra_run_selector.csv config/samples.tsv
#
# Example:
#   bash workflow/00_make_samples_tsv.sh results/metadata/sra_run_selector_raw.csv config/samples.tsv

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <input_sra_csv> <output_samples_tsv>" >&2
  exit 1
fi

INPUT_CSV="$1"
OUTPUT_TSV="$2"

if [[ ! -f "$INPUT_CSV" ]]; then
  echo "Error: input CSV not found: $INPUT_CSV" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_TSV")"

python3 - <<'PY' "$INPUT_CSV" "$OUTPUT_TSV"
import csv
import re
import sys
from pathlib import Path

input_csv = Path(sys.argv[1])
output_tsv = Path(sys.argv[2])

required_headers = {"Run", "Sample Name", "tissue", "LibraryLayout"}

rows_out = []
seen_sample_ids = set()
seen_runs = set()

with input_csv.open("r", encoding="utf-8-sig", newline="") as f:
    reader = csv.DictReader(f)

    headers = set(reader.fieldnames or [])
    missing = required_headers - headers
    if missing:
        raise SystemExit(
            f"Error: missing required column(s) in CSV: {', '.join(sorted(missing))}\n"
            f"Found headers: {', '.join(reader.fieldnames or [])}"
        )

    for row in reader:
        run = (row.get("Run") or "").strip()
        sample_name = (row.get("Sample Name") or "").strip()
        tissue = (row.get("tissue") or "").strip()
        layout_raw = (row.get("LibraryLayout") or "").strip().upper()

        if not run or not sample_name:
            continue

        # Normalize layout
        if layout_raw == "PAIRED":
            layout = "PE"
        elif layout_raw == "SINGLE":
            layout = "SE"
        else:
            layout = layout_raw

        # Parse replicate from trailing _<n>
        rep_match = re.search(r"_([0-9]+)$", sample_name)
        if not rep_match:
            raise SystemExit(f"Error: could not parse replicate from sample name: {sample_name}")
        replicate = rep_match.group(1)

        # Genotype normalization
        if "_WT_" in sample_name:
            genotype = "WT"
        elif "_ZBED6_KO_" in sample_name:
            genotype = "KO"
        else:
            raise SystemExit(f"Error: could not infer genotype from sample name: {sample_name}")

        # Region:
        # Prefer tissue column, otherwise infer from first token in sample name
        region = tissue if tissue else sample_name.split("_")[0]

        sample_id = sample_name

        if sample_id in seen_sample_ids:
            raise SystemExit(f"Error: duplicate sample_id detected: {sample_id}")
        if run in seen_runs:
            raise SystemExit(f"Error: duplicate run_accession detected: {run}")

        seen_sample_ids.add(sample_id)
        seen_runs.add(run)

        rows_out.append({
            "sample_id": sample_id,
            "run_accession": run,
            "genotype": genotype,
            "region": region,
            "replicate": replicate,
            "layout": layout,
        })

# Sort by region, genotype, replicate, sample_id
rows_out.sort(key=lambda r: (r["region"], r["genotype"], int(r["replicate"]), r["sample_id"]))

with output_tsv.open("w", encoding="utf-8", newline="") as f:
    fieldnames = ["sample_id", "run_accession", "genotype", "region", "replicate", "layout"]
    writer = csv.DictWriter(f, fieldnames=fieldnames, delimiter="\t")
    writer.writeheader()
    writer.writerows(rows_out)

# Summary / sanity checks
n_rows = len(rows_out)
regions = sorted({r["region"] for r in rows_out})
layouts = sorted({r["layout"] for r in rows_out})

print(f"Wrote: {output_tsv}")
print(f"Rows: {n_rows}")
print(f"Regions ({len(regions)}): {', '.join(regions)}")
print(f"Layouts: {', '.join(layouts)}")

# Count check by region/genotype
counts = {}
for r in rows_out:
    key = (r["region"], r["genotype"])
    counts[key] = counts.get(key, 0) + 1

print("\nCounts by region/genotype:")
for region in regions:
    wt = counts.get((region, "WT"), 0)
    ko = counts.get((region, "KO"), 0)
    print(f"  {region}: WT={wt}, KO={ko}")

# Strong expectations for this dataset
if n_rows != 54:
    print(f"\nWarning: expected 54 rows for this study, found {n_rows}", file=sys.stderr)

for region in regions:
    wt = counts.get((region, "WT"), 0)
    ko = counts.get((region, "KO"), 0)
    if wt != 3 or ko != 3:
        print(
            f"Warning: region {region} does not have expected WT=3 and KO=3 "
            f"(found WT={wt}, KO={ko})",
            file=sys.stderr
        )
PY
