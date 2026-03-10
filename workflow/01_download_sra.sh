#!/usr/bin/env bash
set -euo pipefail

SAMPLES_TSV="${1:-config/samples.tsv}"
MAX_SAMPLES="${MAX_SAMPLES:-0}"     # 0 means all
OUTDIR="${OUTDIR:-results/raw_fastq}"
LOGDIR="${LOGDIR:-logs}"
THREADS="${THREADS:-8}"
TMPROOT="${TMPROOT:-/tmp/sra_tmp}"
SRA_CACHE_DIR="${SRA_CACHE_DIR:-results/sra_cache}"

mkdir -p "$OUTDIR" "$LOGDIR" "$TMPROOT" "$SRA_CACHE_DIR"

count=0

while IFS=$'\t' read -r sample_id run_accession genotype region replicate layout; do
  [[ "$sample_id" == "sample_id" ]] && continue

  if [[ "$MAX_SAMPLES" -gt 0 && "$count" -ge "$MAX_SAMPLES" ]]; then
    break
  fi

  r1_gz="${OUTDIR}/${sample_id}_R1.fastq.gz"
  r2_gz="${OUTDIR}/${sample_id}_R2.fastq.gz"

  if [[ -s "$r1_gz" && -s "$r2_gz" ]]; then
    echo "[skip] $sample_id already done"
    continue
  fi

  echo "[start] $sample_id ($run_accession)"

  sample_tmp="${TMPROOT}/${run_accession}_tmp"
  mkdir -p "$sample_tmp"

  # 1) Download SRA accession into controlled cache location
  prefetch "$run_accession" \
    --output-directory "$SRA_CACHE_DIR" \
    >> "${LOGDIR}/prefetch.log" 2>&1

  # Path where prefetch usually stores the accession directory
  accession_path="${SRA_CACHE_DIR}/${run_accession}"

  # 2) Convert to FASTQ
  fasterq-dump "$accession_path" \
    --split-files \
    --threads "$THREADS" \
    --outdir "$OUTDIR" \
    --temp "$sample_tmp" \
    >> "${LOGDIR}/fasterq_dump.log" 2>&1

  # 3) Rename from run accession to sample_id
  mv "${OUTDIR}/${run_accession}_1.fastq" "${OUTDIR}/${sample_id}_R1.fastq"
  mv "${OUTDIR}/${run_accession}_2.fastq" "${OUTDIR}/${sample_id}_R2.fastq"

  # 4) Compress to save space
  gzip -f "${OUTDIR}/${sample_id}_R1.fastq"
  gzip -f "${OUTDIR}/${sample_id}_R2.fastq"

  # 5) Cleanup temp + prefetched SRA only after success
  rm -rf "$sample_tmp"
  rm -rf "$accession_path"

  echo "[done] $sample_id"
  count=$((count + 1))

done < "$SAMPLES_TSV"
