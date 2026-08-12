#!/bin/bash
#SBATCH --job-name=quast
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=16G
#SBATCH -o logs/quast_%A_%a.out
#SBATCH -e logs/quast_%A_%a.err
# -----------------------------------------------------------------------------
# QUAST assembly metrics
#
# --min-contig set to 200
#       QUAST default is 500, but NCBI compliant is only 200 bp
#
# Run one sample: sbatch quast.sh <sample_id>
# Run whole batch: sbatch --array=1-15 quast.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/path/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
require_assembly
activate_env "$FINAL_QC_ENV"

MINLEN="${MIN_CONTIG_LENGTH:-200}"
QUASTDIR="${WORKDIR}/quast"
mkdir -p "$QUASTDIR"

quast.py -o "$QUASTDIR" -t "$THREADS" --min-contig "$MINLEN" --labels "$SAMPLE_ID" "$ASSEMBLY"

run_info quast
echo "${SAMPLE_ID} - QUAST output in ${QUASTDIR}"
