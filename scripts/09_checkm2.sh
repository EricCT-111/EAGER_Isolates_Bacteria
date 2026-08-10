#!/bin/bash
#SBATCH --job-name=checkm2
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=32G
#SBATCH -o logs/checkm2_%A_%a.out
#SBATCH -e logs/checkm2_%A_%a.err
# -----------------------------------------------------------------------------
# CheckM2 completeness + contamination
#
# Run one sample: sbatch checkm2.sh <sample_id>
# Run whole batch: sbatch --array=1-15 checkm2.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/labs/Hird/usr/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"

require_assembly
activate_env "$CHECKM2_ENV"

[[ -d "$CHECKM2_DB" ]] || { echo "db missing" >&2; exit 1; }

CM2DIR="${WORKDIR}/checkm2"
mkdir -p "$CM2DIR"

# CheckM2 for single assembly (can also take directory)
checkm2 predict \
    --input "$ASSEMBLY" \
    --output-directory "$CM2DIR" \
    --database_path "$CHECKM2_DB" \
    --threads "$THREADS" \
    --force

run_info checkm2
echo "done ${SAMPLE_ID}"
