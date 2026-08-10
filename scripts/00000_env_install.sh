#!/bin/bash
#SBATCH --job-name=install_env
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=32G

set -eo pipefail

###############################################################################
# Install a single conda environment from a YAML file
#
# How to use:
#	- Create <env_name>.yml in ENV_YAML_DIR
#	- sbatch env_install.sh <env_name>
#
# Notes:
#	- One env at a time
#	- Fails if the env already exists - remove the directory to reinstall
#	- Uses mamba (miniforge) as the solver
#	- Install output goes to install_env_logs/
#	- Tool versions recorded in <env_path>/installed_versions.txt
###############################################################################

# =============================================================================
# Configuration -- edit paths for new project
# =============================================================================
CONDA_BASE="/labs/Hird/usr/miniforge3" # conda install root
ENV_YAML_DIR="/labs/Hird/usr/EAGER_sequences/scripts/envs" # holds <env_name>.yml
ENV_INSTALL_ROOT="/labs/Hird/usr/EAGER_sequences/project_tools" # envs created here
LOG_DIR="/labs/Hird/usr/EAGER_sequences/scripts/install_env_logs" # per-env install logs
# =============================================================================
# file check, strip path
list_available() {
    echo "available yaml in ${ENV_YAML_DIR}:"
    local found=0 f
    for f in "${ENV_YAML_DIR}"/*.yml; do
        [[ -e "$f" ]] || continue
        found=1
        basename "${f%.yml}"
    done
    (( found )) || echo "none"
}

# only take one env
[[ $# -eq 1 ]] || { echo "$(basename "$0") <env_name>" >&2; list_available >&2; exit 2; }
SELECTED_ENV="$1"

# force env_name only
[[ "$SELECTED_ENV" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "bad env name, must be env_name ${SELECTED_ENV}" >&2; exit 2; }

# conda setup
CONDA_SH="${CONDA_BASE}/etc/profile.d/conda.sh"
[[ -f "$CONDA_SH" ]] || { echo "conda.sh not found at ${CONDA_SH}" >&2; exit 1; }
# conda.sh references unset vars
source "$CONDA_SH"
set -u

# check path
YAML="${ENV_YAML_DIR}/${SELECTED_ENV}.yml"
if [[ ! -f "$YAML" ]]; then
    echo "no yaml found for ${SELECTED_ENV} in ${ENV_YAML_DIR}" >&2
    list_available >&2
    exit 1
fi

mkdir -p "$LOG_DIR" "$ENV_INSTALL_ROOT"
ENV_PATH="${ENV_INSTALL_ROOT}/${SELECTED_ENV}"
LOG_FILE="${LOG_DIR}/${SELECTED_ENV}_install.log"

# install
[[ ! -d "$ENV_PATH" ]] || { echo "${ENV_PATH} already exists - remove it to reinstall" >&2; exit 1; }

if ! mamba env create -f "$YAML" -p "$ENV_PATH" &> "$LOG_FILE"; then
    echo "${SELECTED_ENV} install failed - full log at ${LOG_FILE}" >&2
    echo "last 30 lines" >&2
    tail -n 30 "$LOG_FILE" >&2
    exit 1
fi

# install record
{
    echo "# ${SELECTED_ENV} - $(date -u +%FT%TZ) - ${YAML}"
    conda list -p "$ENV_PATH"
} > "${ENV_PATH}/installed_versions.txt"

echo "done ${SELECTED_ENV} - ${ENV_PATH}"
