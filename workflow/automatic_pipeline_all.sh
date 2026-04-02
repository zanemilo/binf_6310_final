#!/usr/bin/env bash
#SBATCH --job-name=auto_pipeline_all
#SBATCH --partition=courses
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=46
#SBATCH --mem=128G
#SBATCH --time=20:00:00
#SBATCH --output=/scratch/polyak.i/ildiko_pipeline_automatic/logs/pipeline_all_%j.log

export PATH=/home/polyak.i/micromamba/envs/binf6310/bin:$PATH

set -euo pipefail

# automatic_pipeline_all.sh
# Full RNA-seq pipeline for all 54 samples: Download → FastQC → STAR alignment → featureCounts
# Based on Liu et al. 2025 reproducibility study
# USAGE: sbatch automatic_pipeline_all.sh all_samples.tsv

# Configuration
SCRATCH_DIR=/scratch/polyak.i/ildiko_pipeline_automatic
OUTDIR="${SCRATCH_DIR}/results/raw_fastq"
SRA_CACHE_DIR="${SCRATCH_DIR}/results/sra_cache"
QC_DIR="${SCRATCH_DIR}/results/qc/raw"
STAR_INDEX="${SCRATCH_DIR}/results/star_index"
ALIGN_DIR="${SCRATCH_DIR}/results/star_aligned"
COUNTS_DIR="${SCRATCH_DIR}/results/counts"
LOGDIR="${SCRATCH_DIR}/logs"
REF_DIR="${SCRATCH_DIR}/reference"
THREADS=46

GENOME_FA="${REF_DIR}/Sus_scrofa.Sscrofa11.1.dna.toplevel.fa"
GTF="${REF_DIR}/Sus_scrofa.Sscrofa11.1.113.gtf"

# Input
SAMPLES_TSV="${1:-}"

if [[ -z "$SAMPLES_TSV" ]]; then
    echo "ERROR: No samples TSV file provided."
    echo "Usage: sbatch automatic_pipeline_all.sh all_samples.tsv"
    exit 1
fi

if [[ ! -f "$SAMPLES_TSV" ]]; then
    echo "ERROR: Samples TSV file not found: $SAMPLES_TSV"
    exit 1
fi

# Create directories
echo "Setting up directories..."
mkdir -p "$OUTDIR" "$SRA_CACHE_DIR" "$QC_DIR" "$STAR_INDEX" \
         "$ALIGN_DIR" "$COUNTS_DIR" "$LOGDIR" "$REF_DIR"
echo "DONE - directories ready"

# Check reference genome
echo ""
echo "Checking reference genome..."
if [[ ! -f "$GENOME_FA" ]]; then
    echo "Genome not found. Downloading from Ensembl..."
    wget -c "https://ftp.ensembl.org/pub/release-113/fasta/sus_scrofa/dna/Sus_scrofa.Sscrofa11.1.dna.toplevel.fa.gz" \
        -O "${GENOME_FA}.gz" \
        2>&1 | tee "$LOGDIR/genome_download.log"
    echo "Decompressing genome (required for STAR v2.7.6a)..."
    gunzip "${GENOME_FA}.gz" && echo "DONE - genome decompressed"
else
    echo "Genome already exists, skipping download."
fi

# Check GTF
echo ""
echo "Checking GTF annotation..."
if [[ ! -f "$GTF" ]]; then
    echo "GTF not found. Downloading from Ensembl..."
    wget -c "https://ftp.ensembl.org/pub/release-113/gtf/sus_scrofa/Sus_scrofa.Sscrofa11.1.113.gtf.gz" \
        -O "${GTF}.gz" \
        2>&1 | tee "$LOGDIR/gtf_download.log"
    echo "Decompressing GTF (required for STAR v2.7.6a)..."
    gunzip "${GTF}.gz" && echo "DONE - GTF decompressed"
else
    echo "GTF already exists, skipping download."
fi

# Check STAR index
echo ""
echo "Checking STAR index..."
if [[ ! -f "${STAR_INDEX}/SA" ]]; then
    echo "STAR index not found. Building now (this takes ~15-30 minutes)..."
    STAR \
        --runMode genomeGenerate \
        --runThreadN "$THREADS" \
        --genomeDir "$STAR_INDEX" \
        --genomeFastaFiles "$GENOME_FA" \
        --sjdbGTFfile "$GTF" \
        --sjdbOverhang 149 \
        2>&1 | tee "$LOGDIR/star_index.log"
    echo "DONE - STAR index complete"
else
    echo "STAR index already exists, skipping build."
fi

# Process each sample
echo ""
echo "Starting sample processing..."

while IFS=$'\t' read -r sample_id run_accession genotype region replicate layout; do

    [[ "$sample_id" == "sample_id" ]] && continue

    echo ""
    echo "Processing: $sample_id ($run_accession)"

    R1_GZ="${OUTDIR}/${sample_id}_R1.fastq.gz"
    R2_GZ="${OUTDIR}/${sample_id}_R2.fastq.gz"

    # Step 1: Download
    if [[ -s "$R1_GZ" && -s "$R2_GZ" ]]; then
        echo "[skip] FASTQ files already exist for $sample_id"
    else
        echo "[step 1] Downloading $run_accession..."
        prefetch "$run_accession" \
            --output-directory "$SRA_CACHE_DIR" \
            2>&1 | tee "$LOGDIR/prefetch_${sample_id}.log"
        echo "DONE - prefetch complete for $sample_id"

        # Step 2: Convert to FASTQ
        echo "[step 2] Converting to FASTQ..."
        fasterq-dump "${SRA_CACHE_DIR}/${run_accession}" \
            --split-files \
            --threads "$THREADS" \
            --outdir "$OUTDIR" \
            --temp /tmp \
            2>&1 | tee "$LOGDIR/fasterq_dump_${sample_id}.log"
        echo "DONE - fasterq-dump complete for $sample_id"

        # Step 3: Rename
        echo "[step 3] Renaming files..."
        mv "${OUTDIR}/${run_accession}_1.fastq" "${OUTDIR}/${sample_id}_R1.fastq"
        mv "${OUTDIR}/${run_accession}_2.fastq" "${OUTDIR}/${sample_id}_R2.fastq"
        echo "DONE - rename complete for $sample_id"

        # Step 4: Compress
        echo "[step 4] Compressing with pigz..."
        pigz -p "$THREADS" "${OUTDIR}/${sample_id}_R1.fastq" && \
            echo "DONE - R1 compression complete for $sample_id"
        pigz -p "$THREADS" "${OUTDIR}/${sample_id}_R2.fastq" && \
            echo "DONE - R2 compression complete for $sample_id"

        # Step 5: Cleanup SRA cache
        echo "[step 5] Cleaning up SRA cache..."
        rm -rf "${SRA_CACHE_DIR}/${run_accession}"
        echo "DONE - SRA cache cleared for $sample_id"
    fi

    # Step 6: FastQC
    R1_HTML="${QC_DIR}/${sample_id}_R1_fastqc.html"
    R2_HTML="${QC_DIR}/${sample_id}_R2_fastqc.html"

    if [[ -f "$R1_HTML" && -f "$R2_HTML" ]]; then
        echo "[skip] FastQC already done for $sample_id"
    else
        echo "[step 6] Running FastQC..."
        fastqc \
            --threads "$THREADS" \
            --outdir "$QC_DIR" \
            "$R1_GZ" "$R2_GZ" \
            2>&1 | tee "$LOGDIR/fastqc_${sample_id}.log"
        echo "DONE - FastQC complete for $sample_id"
    fi

    # Step 7: STAR alignment
    BAM="${ALIGN_DIR}/${sample_id}_Aligned.sortedByCoord.out.bam"

    if [[ -s "$BAM" ]]; then
        echo "[skip] BAM already exists for $sample_id"
    else
        echo "[step 7] Running STAR alignment..."
        STAR \
            --runThreadN "$THREADS" \
            --genomeDir "$STAR_INDEX" \
            --readFilesIn "$R1_GZ" "$R2_GZ" \
            --readFilesCommand zcat \
            --outSAMtype BAM SortedByCoordinate \
            --outSAMattributes NH HI AS NM MD \
            --outFileNamePrefix "${ALIGN_DIR}/${sample_id}_" \
            2>&1 | tee "$LOGDIR/star_align_${sample_id}.log"
        echo "DONE - STAR alignment complete for $sample_id"
        echo "Alignment summary for $sample_id:"
        cat "${ALIGN_DIR}/${sample_id}_Log.final.out"
    fi

    # Step 8: featureCounts
    COUNTS="${COUNTS_DIR}/${sample_id}_counts.txt"

    if [[ -s "$COUNTS" ]]; then
        echo "[skip] Counts already exist for $sample_id"
    else
        echo "[step 8] Running featureCounts..."
        featureCounts \
            -T "$THREADS" \
            -p \
            --countReadPairs \
            -s 0 \
            -a "$GTF" \
            -o "$COUNTS" \
            "$BAM" \
            2>&1 | tee "$LOGDIR/featurecounts_${sample_id}.log"
        echo "DONE - featureCounts complete for $sample_id"

        # Step 9: Delete BAM to save space
        echo "[step 9] Deleting BAM file to save space..."
        rm -f "$BAM"
        rm -f "${ALIGN_DIR}/${sample_id}_Log.progress.out"
        rm -f "${ALIGN_DIR}/${sample_id}__STARtmp" 2>/dev/null || true
        echo "DONE - BAM deleted for $sample_id"
    fi

    echo "COMPLETED: $sample_id"

done < "$SAMPLES_TSV"

echo ""
echo "All samples complete."
echo "FastQC:       $QC_DIR"
echo "Count matrix: $COUNTS_DIR"
echo "Logs:         $LOGDIR"
