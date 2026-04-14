\#Install Kallisto v0.44.0

conda activate binf6310

conda install -c bioconda kallisto=0.44.0 -y \&\& echo "DONE - Kallisto installed"



\#pig transcriptome FASTA file to build the Kallisto index

\#different from what we used for STAR — we need the transcript sequences, not the genome sequence

\#download it from Ensembl release 113 to match our GTF



mkdir -p /scratch/polyak.i/ildiko\_pipeline\_automatic/reference/kallisto

cd /scratch/polyak.i/ildiko\_pipeline\_automatic/reference/kallisto



wget -c "https://ftp.ensembl.org/pub/release-113/fasta/sus\_scrofa/cdna/Sus\_scrofa.Sscrofa11.1.cdna.all.fa.gz" \\

&#x20;   -O Sus\_scrofa.Sscrofa11.1.cdna.all.fa.gz \&\& echo "DONE - transcriptome downloaded"



\#Build Kallisto Index

kallisto index \\

&#x20;   -i /scratch/polyak.i/ildiko\_pipeline\_automatic/reference/kallisto/Sus\_scrofa.Sscrofa11.1.cdna.all.index \\

&#x20;   Sus\_scrofa.Sscrofa11.1.cdna.all.fa.gz \\

&#x20;   2>\&1 | tee /scratch/polyak.i/ildiko\_pipeline\_automatic/logs/kallisto\_index.log \&\& echo "DONE - Kallisto index complete"



\#Write Kallisto batch script

\#1.  download each sample FASTQ file since they were deleted after featureCounts

\#2.  run Kallisto quant to get TPM values

\#3.  clean up FASTQ files after to save space



nano /scratch/polyak.i/ildiko\_pipeline\_automatic/kallisto\_pipeline.sh



\#!/usr/bin/env bash

\#SBATCH --job-name=kallisto\_pipeline

\#SBATCH --partition=courses

\#SBATCH --nodes=1

\#SBATCH --ntasks=1

\#SBATCH --cpus-per-task=46

\#SBATCH --mem=128G

\#SBATCH --time=20:00:00

\#SBATCH --output=/scratch/polyak.i/ildiko\_pipeline\_automatic/logs/kallisto\_pipeline\_%j.log



export PATH=/home/polyak.i/micromamba/envs/binf6310/bin:$PATH



set -euo pipefail



SCRATCH\_DIR=/scratch/polyak.i/ildiko\_pipeline\_automatic

SRA\_CACHE\_DIR="${SCRATCH\_DIR}/results/sra\_cache"

KALLISTO\_OUT="${SCRATCH\_DIR}/results/kallisto"

LOGDIR="${SCRATCH\_DIR}/logs"

INDEX="${SCRATCH\_DIR}/reference/kallisto/Sus\_scrofa.Sscrofa11.1.cdna.all.index"

THREADS=46

SAMPLES\_TSV="${1:-}"



if \[\[ -z "$SAMPLES\_TSV" ]]; then

&#x20;   echo "ERROR: No samples TSV file provided."

&#x20;   echo "Usage: sbatch kallisto\_pipeline.sh all\_samples.tsv"

&#x20;   exit 1

fi



mkdir -p "$SRA\_CACHE\_DIR" "$KALLISTO\_OUT" "$LOGDIR"



echo "Starting Kallisto pipeline..."



while IFS=$'\\t' read -r sample\_id run\_accession genotype region replicate layout; do



&#x20;   \[\[ "$sample\_id" == "sample\_id" ]] \&\& continue



&#x20;   echo ""

&#x20;   echo "Processing: $sample\_id ($run\_accession)"



&#x20;   SAMPLE\_OUT="${KALLISTO\_OUT}/${sample\_id}"



&#x20;   if \[\[ -f "${SAMPLE\_OUT}/abundance.tsv" ]]; then

&#x20;       echo "\[skip] Kallisto output already exists for $sample\_id"

&#x20;       continue

&#x20;   fi



&#x20;   mkdir -p "$SAMPLE\_OUT"



&#x20;   # Step 1: Download

&#x20;   echo "\[step 1] Downloading $run\_accession..."

&#x20;   prefetch "$run\_accession" \\

&#x20;       --output-directory "$SRA\_CACHE\_DIR" \\

&#x20;       2>\&1 | tee "$LOGDIR/prefetch\_kallisto\_${sample\_id}.log"



&#x20;   # Step 2: Convert to FASTQ

&#x20;   echo "\[step 2] Converting to FASTQ..."

&#x20;   fasterq-dump "${SRA\_CACHE\_DIR}/${run\_accession}" \\

&#x20;       --split-files \\

&#x20;       --threads "$THREADS" \\

&#x20;       --outdir "$SAMPLE\_OUT" \\

&#x20;       --temp /tmp \\

&#x20;       2>\&1 | tee "$LOGDIR/fasterq\_kallisto\_${sample\_id}.log"



&#x20;   # Step 3: Run Kallisto

&#x20;   echo "\[step 3] Running Kallisto..."

&#x20;   kallisto quant \\

&#x20;       -i "$INDEX" \\

&#x20;       -o "$SAMPLE\_OUT" \\

&#x20;       -t "$THREADS" \\

&#x20;       "${SAMPLE\_OUT}/${run\_accession}\_1.fastq" \\

&#x20;       "${SAMPLE\_OUT}/${run\_accession}\_2.fastq" \\

&#x20;       2>\&1 | tee "$LOGDIR/kallisto\_${sample\_id}.log"

&#x20;   echo "DONE - Kallisto complete for $sample\_id"



&#x20;   # Step 4: Cleanup

&#x20;   echo "\[step 4] Cleaning up..."

&#x20;   rm -f "${SAMPLE\_OUT}/${run\_accession}\_1.fastq"

&#x20;   rm -f "${SAMPLE\_OUT}/${run\_accession}\_2.fastq"

&#x20;   rm -rf "${SRA\_CACHE\_DIR}/${run\_accession}"

&#x20;   echo "DONE - Cleanup complete for $sample\_id"



&#x20;   echo "COMPLETED: $sample\_id"



done < "$SAMPLES\_TSV"



echo ""

echo "All samples complete."

echo "Kallisto output: $KALLISTO\_OUT"







\#Submit the job

chmod +x /scratch/polyak.i/ildiko\_pipeline\_automatic/kallisto\_pipeline.sh



sbatch /scratch/polyak.i/ildiko\_pipeline\_automatic/kallisto\_pipeline.sh \\

&#x20;   /scratch/polyak.i/ildiko\_pipeline\_automatic/all\_samples.tsv



\#Check that it's running

squeue -u polyak.i



\#Watch the log to confirm it's running

tail -f /scratch/polyak.i/ildiko\_pipeline\_automatic/logs/kallisto\_pipeline\_5925523.log



\#Let the script run overnight and confirm in the morning



\#check if the job is done

ssh explorer

squeue -u polyak.i



\#check all 54 folders are there

ls /scratch/polyak.i/ildiko\_pipeline\_automatic/results/kallisto/ | wc -l



\#look at EDL\_WT\_1's TPM output

head -20 /scratch/polyak.i/ildiko\_pipeline\_automatic/results/kallisto/EDL\_WT\_1/abundance.tsv



\#check the Kallisto run log for EDL\_WT\_1 and see how many reads were pseudoaligned

cat /scratch/polyak.i/ildiko\_pipeline\_automatic/logs/kallisto\_EDL\_WT\_1.log



\#key is to look for pseudoalignment rate and for all other samples expect around 90%

\#Kallisto pseudoalignment rate for EDL\_WT\_1:

\#processed 23,585,303 reads

\#pseudoalignment 17,589,296 reads

\#rate = 17,589,296 / 23,585,202 x 100 = 74.6%

\#Kallisto's pseudoalignment rate of 74.6% is lower than STAR's alignment rate of 79.49% on the raw unfiltered reads.  This makes sense because Kallisto aligns against the transcriptome only, so rRNA reads that don't match any transcript fail to pseudoalign.



\#compare EDL\_WT\_1 to other samples to see if it is an outlier



\#check pseudoaligned read counts

for f in /scratch/polyak.i/ildiko\_pipeline\_automatic/logs/kallisto\_\*.log; do

&#x20;   sample=$(basename $f .log | sed 's/kallisto\_//')

&#x20;   rate=$(grep "reads pseudoaligned" $f | awk '{print $4, $5, $6, $7, $8}')

&#x20;   echo "$sample: $rate"

done





\#check total processed reads to calculate percentages

for f in /scratch/polyak.i/ildiko\_pipeline\_automatic/logs/kallisto\_\*.log; do

&#x20;   sample=$(basename $f .log | sed 's/kallisto\_//')

&#x20;   line=$(grep "reads pseudoaligned" $f)

&#x20;   processed=$(echo $line | awk '{print $3}' | tr -d ',')

&#x20;   aligned=$(echo $line | awk '{print $5}' | tr -d ',')

&#x20;   if \[\[ -n "$processed" \&\& "$processed" -gt 0 ]]; then

&#x20;       pct=$(echo "scale=1; $aligned \* 100 / $processed" | bc)

&#x20;       echo "$sample: $pct%"

&#x20;   fi

done



\#ALL 53 SAMPLES HAVE PSEUDOALIGNMENT RATES 84.4% - 91.0% (MATCHES PAPER) EXCEPT FOR EDL\_WT\_1 IS 74.5%

\#This confirms that the rRNA contamination in EDL\_WT\_1 affects Kallisto pseudoalignment just as it affected STAR alignment.  The 10 percentage point drop is consistent with the 21% rRNA contamination identified earlier in STAR, not all rRNA reads fail pseudoalignment, some partially match transcript



**#1. The Kallisto pseudoalignment rate for EDL\_WT\_1 was 74.5% compared to 84-91% for all other 53 samples, consistent with the rRNA contamination identified in FastQC and STAR alignment analysis.**

**#2. Since the paper does not report Kallisto pseudoalignment rates, we can't directly confirm whether the authos observed a similar drop for EDL\_WT\_1.  However, if rRNA filtering was not applied prior to Kallisto, the TPM values for EDL\_WT\_1 would be derived from a contaminated dataset, potentially affecting the TPM based figures including t-SNE, Spearman correlation, and the expression heatmap**

**#3. The lower pseudoalignment rate for EDL\_WT\_1 provides additional evidence that an undocumented preprocessing step was applied by the authors.  If no rRNA filtering had been performed, a similar pseudoalignment rate reduction would be expected in the paper's own Kallisto results, yet Figure 2a suggests all samples achieved consistent mapping rates.**



**#Suggest making 2 versions of Figure 2a for final report to directly demonstrate impact of undocumented preprocessing step:
#Version 1:  All 54 samples unfiltered - EDL\_WT\_1 drops below 95% line**

**#Version 2:  All 54 samples with EDL\_WT\_1 rRNA filtered - all samples above 95%**

**#Need STAR alignment rates for all 54 samples and the cleaned up SortMeRNA reads**





\#ALL 53 SAMPLES HAVE PSEUDOALIGNMENT RATES 84.4% - 91.0% (MATCHES PAPER) EXCEPT FOR EDL\_WT\_1 IS 74.5%

\#This confirms that the rRNA contamination in EDL\_WT\_1 affects Kallisto pseudoalignment just as it affected STAR alignment.  The 10 percentage point drop is consistent with the 21% rRNA contamination identified earlier in STAR, not all rRNA reads fail pseudoalignment, some partially match transcript



**#1. The Kallisto pseudoalignment rate for EDL\_WT\_1 was 74.5% compared to 84-91% for all other 53 samples, consistent with the rRNA contamination identified in FastQC and STAR alignment analysis.**

**#2. Since the paper does not report Kallisto pseudoalignment rates, we can't directly confirm whether the authos observed a similar drop for EDL\_WT\_1.  However, if rRNA filtering was not applied prior to Kallisto, the TPM values for EDL\_WT\_1 would be derived from a contaminated dataset, potentially affecting the TPM based figures including t-SNE, Spearman correlation, and the expression heatmap**

**#3. The lower pseudoalignment rate for EDL\_WT\_1 provides additional evidence that an undocumented preprocessing step was applied by the authors.  If no rRNA filtering had been performed, a similar pseudoalignment rate reduction would be expected in the paper's own Kallisto results, yet Figure 2a suggests all samples achieved consistent mapping rates.**



**#Suggest making 2 versions of Figure 2a for final report to directly demonstrate impact of undocumented preprocessing step:
#Version 1:  All 54 samples unfiltered - EDL\_WT\_1 drops below 95% line**

**#Version 2:  All 54 samples with EDL\_WT\_1 rRNA filtered - all samples above 95%**

**#Need STAR alignment rates for all 54 samples and the cleaned up SortMeRNA reads**





\#Kallisto Cleanup:  run Kallisto on the rRNA-filtered EDL\_WT\_1 reads from SortMeRNA that we ran earlier for STAR

&#x20;

\#Check if it's still there
ls -lh /scratch/polyak.i/ildiko\_pipeline\_automatic/results/sortmerna/EDL\_WT\_1/



\#Run Kallisto on the reads as a batch job

nano /scratch/polyak.i/ildiko\_pipeline\_automatic/kallisto\_EDL\_WT\_1\_filtered.sh



\#!/usr/bin/env bash

\#SBATCH --job-name=kallisto\_EDL\_filtered

\#SBATCH --partition=courses

\#SBATCH --nodes=1

\#SBATCH --ntasks=1

\#SBATCH --cpus-per-task=46

\#SBATCH --mem=128G

\#SBATCH --time=01:00:00

\#SBATCH --output=/scratch/polyak.i/ildiko\_pipeline\_automatic/logs/kallisto\_EDL\_WT\_1\_filtered\_%j.log



export PATH=/home/polyak.i/micromamba/envs/binf6310/bin:$PATH



INDEX=/scratch/polyak.i/ildiko\_pipeline\_automatic/reference/kallisto/Sus\_scrofa.Sscrofa11.1.cdna.all.index

FWD=/scratch/polyak.i/ildiko\_pipeline\_automatic/results/sortmerna/EDL\_WT\_1/EDL\_WT\_1\_clean\_fwd.fq.gz

REV=/scratch/polyak.i/ildiko\_pipeline\_automatic/results/sortmerna/EDL\_WT\_1/EDL\_WT\_1\_clean\_rev.fq.gz

OUT=/scratch/polyak.i/ildiko\_pipeline\_automatic/results/kallisto/EDL\_WT\_1\_filtered



mkdir -p "$OUT"



kallisto quant \\

&#x20;   -i "$INDEX" \\

&#x20;   -o "$OUT" \\

&#x20;   -t 46 \\

&#x20;   "$FWD" "$REV" \\

&#x20;   2>\&1 \&\& echo "DONE - Kallisto filtered EDL\_WT\_1 complete"







\#Run the job and check job ID
chmod +x /scratch/polyak.i/ildiko\_pipeline\_automatic/kallisto\_EDL\_WT\_1\_filtered.sh

sbatch /scratch/polyak.i/ildiko\_pipeline\_automatic/kallisto\_EDL\_WT\_1\_filtered.sh



\#Check results

cat /scratch/polyak.i/ildiko\_pipeline\_automatic/logs/kallisto\_EDL\_WT\_1\_filtered\_5934038.log



\#Calculate the rates

\#Version		Reads Processed	Pseudoaligned	Rate

\#Unfiltered (raw)	23,585,303	17,589,296	74.5%

\#rRNA-filtered		18,329,254	15,804,010	86.2%

\#Other 53 samples					84-91%



\#After rRNA filtering, EDL\_WT\_1 pseudoalignment rate of 86.2% falls withing the normal range for other samples and TPM values from filtered run are now comparable and reliable	



\#Keep both clean and raw-unfiltered versions, clearly labeled

cp /scratch/polyak.i/ildiko\_pipeline\_automatic/results/kallisto/EDL\_WT\_1/abundance.tsv \\

&#x20;  /scratch/polyak.i/ildiko\_pipeline\_automatic/results/kallisto/EDL\_WT\_1/abundance\_unfiltered.tsv



cp /scratch/polyak.i/ildiko\_pipeline\_automatic/results/kallisto/EDL\_WT\_1\_filtered/abundance.tsv \\

&#x20;  /scratch/polyak.i/ildiko\_pipeline\_automatic/results/kallisto/EDL\_WT\_1/abundance\_filtered.tsv



\#Verify both files
ls -lh /scratch/polyak.i/ildiko\_pipeline\_automatic/results/kallisto/EDL\_WT\_1/



\#Replace main abundance.tsv with filtered version

cp /scratch/polyak.i/ildiko\_pipeline\_automatic/results/kallisto/EDL\_WT\_1/abundance\_filtered.tsv \\

&#x20;  /scratch/polyak.i/ildiko\_pipeline\_automatic/results/kallisto/EDL\_WT\_1/abundance.tsv



\#Verify file

ls -lh /scratch/polyak.i/ildiko\_pipeline\_automatic/results/kallisto/EDL\_WT\_1/




#sync GitHub

cd /scratch/polyak.i/final\_temp/binf\_6310\_final/

git pull origin master

git status



\#create kallisto folder in results

mkdir -p results/kallisto

touch results/kallisto/.gitkeep



\#Copy 54 sample abundance files

for dir in /scratch/polyak.i/ildiko\_pipeline\_automatic/results/kallisto/\*/; do

&#x20;   sample=$(basename $dir)

&#x20;   if \[\[ "$sample" != "EDL\_WT\_1\_filtered" ]]; then

&#x20;       mkdir -p results/kallisto/$sample

&#x20;       cp $dir/abundance.tsv results/kallisto/$sample/abundance.tsv

&#x20;   fi

done



\#Verify

ls results/kallisto/ | wc -l



\#Commit and push to GitHub

git add results/kallisto/

git commit -m "Add Kallisto TPM abundance files for all 54 samples (EDL\_WT\_1 rRNA-filtered)"

git push origin master




#Make new folder for unfiltered EDL\_WT\_1 sample

mkdir -p results/kallisto\_unfiltered/EDL\_WT\_1

cp /scratch/polyak.i/ildiko\_pipeline\_automatic/results/kallisto/EDL\_WT\_1/abundance\_unfiltered.tsv \\

&#x20;  results/kallisto\_unfiltered/EDL\_WT\_1/abundance.tsv



\#Commit and push to GitHub

git add results/kallisto\_unfiltered/

git commit -m "Add EDL\_WT\_1 unfiltered Kallisto abundance in separate folder for comparison figures"

git push origin master

























