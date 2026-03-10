#!/usr/bin/env bash
set -euo pipefail

SAMPLES_TSV="${1:-config/samples.tsv}"
MAX_SAMPLES="${MAX_SAMPLES:-0}"          # 0 = all
RAW_DIR="${RAW_DIR:-results/raw_fastq}"
QC_DIR="${QC_DIR:-results/qc/raw}"
LOGDIR="${LOGDIR:-logs}"
THREADS="${THREADS:-4}"

mkdir -p "$QC_DIR" "$LOGDIR"

# Dependency check
for cmd in fastqc; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Error: required command not found in PATH: $cmd" >&2
    exit 1
  }
done

if [[ ! -f "$SAMPLES_TSV" ]]; then
  echo "Error: samples TSV not found: $SAMPLES_TSV" >&2
  exit 1
fi

count=0

while IFS=$'\t' read -r sample_id run_accession genotype region replicate layout; do
  [[ "$sample_id" == "sample_id" ]] && continue

  if [[ "$MAX_SAMPLES" -gt 0 && "$count" -ge "$MAX_SAMPLES" ]]; then
    break
  fi

  r1="${RAW_DIR}/${sample_id}_R1.fastq.gz"
  r2="${RAW_DIR}/${sample_id}_R2.fastq.gz"

  if [[ ! -f "$r1" ]]; then
    echo "Warning: missing file, skipping: $r1" >&2
    continue
  fi

  if [[ ! -f "$r2" ]]; then
    echo "Warning: missing file, skipping: $r2" >&2
    continue
  fi

  r1_html="${QC_DIR}/${sample_id}_R1_fastqc.html"
  r2_html="${QC_DIR}/${sample_id}_R2_fastqc.html"

  if [[ -f "$r1_html" && -f "$r2_html" ]]; then
    echo "[skip] FastQC already done for $sample_id"
    continue
  fi

  echo "[fastqc] $sample_id"

  fastqc \
    --threads "$THREADS" \
    --outdir "$QC_DIR" \
    "$r1" "$r2" \
    >> "${LOGDIR}/fastqc_raw.log" 2>&1

  echo "[done] $sample_id"
  count=$((count + 1))

done < "$SAMPLES_TSV"

echo "FastQC raw step complete."
