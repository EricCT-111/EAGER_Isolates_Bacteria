#!/bin/bash
#SBATCH --job-name=fcs_gx
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=160G
#SBATCH -o logs/fcs_gx_%j.out
#SBATCH -e logs/fcs_gx_%j.err
# -----------------------------------------------------------------------------
# NCBI FCS-GX contamination screen
#
# Tax id required for run and entered manually
#
# Run one sample: sbatch fcs_gx.sh <sample_id> <tax_id>
# No array option - individual taxid needed
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/path/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
TAXID="${2:-}"
pipeline_init "${1:-}"
require_assembly
activate_env "$FCS_GX_ENV"

[[ -n "$TAXID" ]] || { echo "no tax id given" >&2; exit 2; }
[[ "$TAXID" =~ ^[0-9]+$ ]] || { echo "bad tax id, must be numeric" >&2; exit 2; }
[[ -d "$FCS_GX_DB" ]] || { echo "missing database" >&2; exit 1; }

FCS_OUT="${WORKDIR}/fcs_gx"
mkdir -p "$FCS_OUT"
export GX_NUM_CORES="$THREADS"

run_gx.py \
    --fasta "$ASSEMBLY" \
    --tax-id "$TAXID" \
    --gx-db "${FCS_GX_DB}/all" \
    --out-dir "$FCS_OUT"

run_info
echo "done ${SAMPLE_ID} ${FCS_OUT}"
