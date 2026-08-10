#!/bin/bash
#SBATCH --job-name=phold
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=96G
#SBATCH -o logs/phold_%A_%a.out
#SBATCH -e logs/phold_%A_%a.err
# -----------------------------------------------------------------------------
# Phold: fold based viral annotation improvements
#
# Takes the $WORKDIR/pharokka/$SAMPLE_ID.gbk
#   splits into genbank file per phage if more than 1 
#
# Run one sample: sbatch phold.sh <sample_id>
# Run whole batch: sbatch --array=1-15 phold.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/labs/Hird/usr/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
activate_env "$PHOLD_ENV"

[[ -d "$PHOLD_DB" ]] || { echo "no phold db found" >&2; exit 1; }

ALL_VIRUSES="${WORKDIR}/all_viruses.fna"
PHOLDI="${WORKDIR}/pharokka/$SAMPLE_ID.gbk"
[[ -s "$PHOLDI" ]] || { echo "no pharokka gen bank file" >&2; exit 1; }

PHOLD_OUT="${WORKDIR}/phold"
mkdir -p "$PHOLD_OUT"

# if multiple phages, use phold --separate for individual genbank files
n_phages=$(grep -c '^>' "$ALL_VIRUSES")

args=(
    -i "$PHOLDI"
    -o "$PHOLD_OUT"
    -d "$PHOLD_DB"
    -t "$THREADS"
    --force
)
[[ "$n_phages" -gt 1 ]] && args+=(--separate)
phold run "${args[@]}"

run_info phold
echo "done ${SAMPLE_ID}"
