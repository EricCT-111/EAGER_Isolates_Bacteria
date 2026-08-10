# ---------------------------------------------------------------------------
# One-time Conda Setup
#
# Why: 
#  The shared module (miniconda/311_23.11.0-2) is conda 23.11.0 (out of date)
#    - Can cause issues for environment downloads
#    - Doesnt have integrated libmamba
#    - Do not module load miniconda alongside the new download
# ---------------------------------------------------------------------------

# 1. Install Miniforge (current conda + the libmamba solver)
cd /labs/Hird/usr
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh -b -p /labs/Hird/usr/miniforge3
rm Miniforge3-Linux-x86_64.sh

# 2. Put it ahead of the hpc conda
echo 'export PATH="/labs/Hird/usr/miniforge3/condabin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 3. Make sure this path is set in env_install.sh and paths.config

# 4. Verify it worked
which -a conda # should be miniforge you just installed
bash -c 'conda --version' # newer version, not hpc module version
