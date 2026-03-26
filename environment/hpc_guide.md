# Setting Up `binf_6310_final` on an HPC

## Prerequisites

- Git and Conda available on the HPC (most HPCs have these via `module load`)

---

## Step 1: SSH into the HPC and request compute node

```bash
ssh <username>@login.explorer.neu.edu
si 
# or however you request interactive job 
```

---

## Step 2: Check for Git and Conda

```bash
git --version
conda --version
```

If not found, try loading them as modules:

```bash
module load git
module load anaconda3 
```

---

## Step 3: Navigate to Your Scratch/Work Directory

Avoid cloning into your home directory — use scratch for large data.

```bash
cd /scratch/<username>/

```


---

## Step 4: Clone the Repo

```bash
git clone https://github.com/zanemilo/binf_6310_final
cd binf_6310_final
```

Verify contents:

```bash
ls
```

---

## Step 5: Set Up the Conda Environment

```bash
conda env create -f environment/environment.yml
conda activate venv_conda
```

This installs: Python, STAR, sra-tools, samtools, FastQC, subread, R.

> **Note:** The first time you activate the env, it will take upwards of 15 minutes, depending on the compute power you requested. Conda may error at the end and tell you to run: 
```bash
conda init
```
 If requested, run command and you will be all set. From that point, every time you enter a new compute node and you're doing project work, you will run the activate command (runs instantly.)

Verify the environment:

```bash
bash environment/verify.sh
```
You should see all packages displayed. 

---

## Step 7: Set Environment Variables for Data Paths

Point all large data output to scratch, not the repo directory:

```bash
export SCRATCH_DIR=/scratch/<username>/binf_6310_final

export OUTDIR="${SCRATCH_DIR}/results/raw_fastq"
export SRA_CACHE_DIR="${SCRATCH_DIR}/results/sra_cache"
export LOGDIR="${SCRATCH_DIR}/logs"
export THREADS=8
```

> **Tip:** Add these exports to a `~/.bashrc` or a dedicated `env.sh` file in the repo so you don't have to re-enter them each session.

---

## Step 8: Test with 2 Samples First

Before running all 54 samples, do a small test:

```bash
export MAX_SAMPLES=2
bash workflow/01_download_sra.sh config/test_samples.tsv
bash workflow/02_fastqc_raw.sh config/test_samples.tsv
```

Check output:

```bash
ls $OUTDIR
ls $SCRATCH_DIR/results/qc/raw
```

---

## Step 9: Pull Updates from GitHub

When teammates push changes, sync your HPC copy:

```bash
cd /scratch/<username>/binf_6310_final
git pull origin master
```

> **Important:** Only pull if you haven't made local changes. Check first with `git status`. This is the mistake I made which overwrote all my changes. 

---

## Directory Structure Overview

```
/scratch/<username>/
└── binf_6310_final/          ← repo (scripts, configs)
    ├── config/
    │   └── samples.tsv
    ├── workflow/
    │   ├── 01_download_sra.sh
    │   ├── 02_fastqc_raw.sh
    │   └── ...
    └── environment/

/scratch/<username>/binf_6310_final/results/    ← all large data lives here
    ├── raw_fastq/
    ├── sra_cache/
    ├── qc/
    └── logs/
```

---

## Quick Reference Cheatsheet

| Task | Command |
|---|---|
| Load modules | `module load conda git` |
| Activate env | `conda activate venv_conda` |
| Pull latest code | `git pull origin master` |
| Test run (2 samples) | `MAX_SAMPLES=2 bash workflow/01_download_sra.sh config/test_samples.tsv` |
