## Environment (Conda package manager + Bioconda channel)

This project uses a Conda environment to install command-line bioinformatics tools (STAR, FastQC, samtools, etc.).
Most analysis is done in **R** (e.g., DESeq2). Python may be used for small utilities, but it is not the primary analysis language.

After reading and following this README, we will have installed & verified:

- Git (Version control software)
- Conda (Package/dependecies manager)
- python (programming language)
- star (Alignment/mapping softwarwe)
- sra-tools (Data fetching software)
- samtools (BAM/SAM/CRAM Utilities software)
- fastqc (QC software)
- subread (Read counts software)
- r-base (programming language)


### Setting up

To get started navigate to your Ubuntu shell to access the WSL virtual machine on your windows device. This is needed since most software being used is not compatible with windows operating systems, therefor a Linux distrobution will be used instead. I am assuming WSL or WSL2 is already installed on your machine and operational.


### GIT (Version Control):

Next, since the team has a GitHub repository set up, we will need a way for you to download the project locally to interact with, make updates to, and fetch the latest updates.

Git will be the way you are able to do so.

To install git on your Ubuntu distrobution follow these commands in your shell:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential curl wget git unzip ca-certificates
```

Then verify git is installed with:

```bash
git --version
```

If the version of git is output to your shell, skip to **Git Config**.

Otherwise, please enter these commands into your shell:

```bash
sudo apt install -y git
```

Then Verify with:

```bash
git --version
```

### GIT Config

Now that git is installed, we will need to update the config so when you make updates, we will be able to see it was you who made the updates.

To do so please enter the following into your shell:

```bash
git config --global user.name "<Your Name>"
git config --global user.email "<you@example.com>"
git config --global init.defaultBranch master
```
Note: with the above command, your default branch is named **'master'** and not **'main'**. This is just a simple preference thing but will matter for making updates and uploading those changes to GitHub later if needed.

Confirm your configuration of git with the command:

```bash
git config --global --list
```


### Conda (Package Manager)

Next up we will need to download the package manager. Conda has a few different versions available, such as miniconda, miniforge, and anaconda. After a quick look, it seems miniforge is the most compatible with Linux, so we will install miniforge branch of conda.

conda likes to be installed in the **Home directory**, to get there enter:

```bash
cd ~
```

Next, run the following commands to install miniforge for linux:

```bash
wget -O Miniforge3.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3.sh
```

During install, make sure to accept the license, default install path should be fine in the home directory (~/miniforge3), and choose yes to initialize conda, which adds conda to your ~/.bashrc

The .bashrc file is a hidden shell script located in a user's home directory (~/.bashrc) that configures the Bash environment every time a new interactive terminal session is opened.

Once complete, restart your shell with the following:

```bash
source ~/.bashrc
```

Then verify installation:

```bash
conda --version
which conda
```

### Configure conda channels

Channels are the locations where packages are stored. They serve as the base for hosting and managing packages with conda.

This will allow you to use the channels to install the packages that are required to run the pipeline locally.

Run the following to do configure the conda channels:

```bash
conda config --add channels conda-forge
conda config --add channels bioconda
conda config --add channels defaults
conda config --set channel_priority strict
```

Then verify with:

```bash
conda config --show channels
conda config --show channel_priority
```

#### NOTE: If for wwhatever reason, conda is installed but is not iniatated you may run the following to manually initiate conda:

```bash
conda init bash
source ~/.bashrc
```

## Cloning project repo from GitHub

Next, we will be making a clone of the project code base on your computer locally. This step will help set up the specific conda environment that we will be using, which will contain all of the software packages required for this project so far.

First we navigate to the home directory, then clone the repo locally, and change directory to the freshly downloaded repo with the following commands:

```bash
cd ~
git clone https://github.com/zanemilo/binf_6310_final
cd binf_6310_final
```

verify by listing the project directory content with:

```bash
ls
```


## Create environment

Next up, we will be accessing and running a yaml file, which tells conda what softwares to download, and what the environement name should be. I have curated the software required and it should be all you need to get started.

Enter the following commands:

```bash
conda env create -f environment/environment.yml
conda activate venv_conda  ## NOTE: venv_conda is the name of the environment, pulled from environment.yml
```

Verify install:

```bash
bash environment/verify.sh
```

OR

```bash
conda env list
python --version
R --version
```

and

```bash
STAR --version
fastqc --version
samtools --version
prefetch --version || true
fasterq-dump --version || true
featureCounts -v
```


## All Set

At this point, if everything has installed, been verified, and you ahve not encountered any errors, you should be good to go for interacting with the project and pipeline.

# **!!IMPORTANT!!:**

As we progress with the project and we each make changes to the code, it is incredibly important to communicate about these changes before uploading them to avoid potential lose of code/data etc via merge conflicts, which can be a massively annoying to work around.

So please, until we come up with a collaboration workflow if we are each changing the codebase, let's all chat before uploading our changes to the code base to GitHub.

Also, to get the latest project updates **(IF YOU HAVE NOT MADE ANY CHANGES LOCALLY, OTHERWISE PLEASE REACH OUT)** that are have been uploaded to the GitHub repo, please run the following:

```bash
git pull origin master
```

If you are wanting to make updates to the repo, we can add a working with git guide somewhere.

### Notes

* If you already created the env and just want to update it:

  ```bash
  conda env update -f env/environment.yml --prune
  ```

* The `prefix:` field (machine-specific path) should NOT be in a shared `environment.yml`.

```

