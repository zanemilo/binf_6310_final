# Environment setup (pip + venv)

This repo starts with a lightweight Python environment using `venv` + `requirements.txt`.
System-installed tools (FastQC, MultiQC, aligners, samtools, etc.) are installed separately
(e.g., Homebrew on macOS or modules/conda on HPC).

## 1) Create and activate a virtual environment

### macOS / Linux
```bash
python3 -m venv .venv
source .venv/bin/activate

Windows (PowerShell)
py -m venv .venv
.venv\Scripts\Activate.ps1

2) Upgrade pip tooling
python -m pip install --upgrade pip setuptools wheel

3) Install Python requirements

From the repo root:

pip install -r environment/requirements.txt
