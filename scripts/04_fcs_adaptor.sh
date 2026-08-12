#!/bin/bash
#SBATCH --job-name=fcs_adaptor_screen
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=16G
#SBATCH -o logs/fcs_screen_%A_%a.out
#SBATCH -e logs/fcs_screen_%A_%a.err
# -----------------------------------------------------------------------------
# NCBI FCS-adaptor: Screen only (doesn't remove anything)
#
# Produces ${WORKDIR}/fcs_adaptor/fcs_adaptor_report.txt
# Read it and decide to run fcs_clean.sh
#
# Run one sample: sbatch fcs_screen.sh <sample_id>
# Run whole batch: sbatch --array=1-15 fcs_screen.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/path/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
require_assembly

# check container and singularity
FCS_RUNNER="${CONTAINERS}/run_fcsadaptor.sh"
command -v singularity &>/dev/null || { echo "singularity not on PATH" >&2; exit 1; }
[[ -x "$FCS_RUNNER" ]] || { echo "not executable ${FCS_RUNNER}" >&2; exit 1; }
[[ -f "$FCS_ADAPTOR_SIF" ]] || { echo "missing ${FCS_ADAPTOR_SIF}" >&2; exit 1; }

FCSDIR="${WORKDIR}/fcs_adaptor"
mkdir -p "$FCSDIR"

"$FCS_RUNNER" \
    --fasta-input "$ASSEMBLY" \
    --output-dir "$FCSDIR" \
    --prok \
    --container-engine singularity \
    --image "$FCS_ADAPTOR_SIF"

run_info
echo "done ${SAMPLE_ID} ${REPORT}"
