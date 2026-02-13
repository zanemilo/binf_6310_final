## Environment (Conda + Bioconda)

This project uses a Conda environment to install command-line bioinformatics tools (STAR, FastQC, samtools, etc.).
Most analysis is done in **R** (e.g., DESeq2). Python may be used for small utilities, but it is not the primary
analysis language.

### 1) Install Conda (recommended: Miniforge)
Install Miniforge/Conda, then restart your terminal.

### 2) Create the environment
From the repo root:

```bash
conda env create -f environment/environment.yml
````

### 3) Activate the environment

```bash
conda activate venv_conda
```

### 4) Quick checks

```bash
R --version
fastqc --version
samtools --version
STAR --version
```

### Notes

* If you already created the env and just want to update it:

  ```bash
  conda env update -f env/environment.yml --prune
  ```

* The `prefix:` field (machine-specific path) should NOT be in a shared `environment.yml`.

```

