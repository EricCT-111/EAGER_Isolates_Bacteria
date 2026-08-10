#!/bin/bash
#SBATCH --job-name=gtdbtk
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=150G
#SBATCH -o logs/gtdbtk_%A_%a.out
#SBATCH -e logs/gtdbtk_%A_%a.err
# -----------------------------------------------------------------------------
# GTDB-Tk taxonomic classification
# Uses final_assembly.fna on all platforms
#
# Run one sample: sbatch gtdbtk.sh <sample_id>
# Run whole batch: sbatch --array=1-15 gtdbtk.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/labs/Hird/usr/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
require_assembly
activate_env "$TAXONOMY_ENV"

# GTDB-Tk finds its reference data via this env var.
export GTDBTK_DATA_PATH="$GTDBTK_DATA"
[[ -d "$GTDBTK_DATA_PATH" ]] || { echo "GTDB reference not found - ${GTDBTK_DATA_PATH}" >&2; exit 1; }
echo "GTDBTK_DATA_PATH=${GTDBTK_DATA_PATH}"

GTDBDIR="${WORKDIR}/gtdbtk"
GENOMEDIR="${GTDBDIR}/input"
mkdir -p "$GENOMEDIR"

# classify_wf can use one genome or directory of genomes
cp "$ASSEMBLY" "${GENOMEDIR}/${SAMPLE_ID}.fna"

gtdbtk classify_wf \
    --genome_dir "$GENOMEDIR" \
    --out_dir "$GTDBDIR" \
    --cpus "$THREADS"

run_info gtdbtk
echo "done ${SAMPLE_ID} ${GTDBDIR}"
