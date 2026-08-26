#!/bin/bash
#SBATCH --job-name=mob_recon
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=32G
#SBATCH -o logs/mob_recon_%A_%a.out
#SBATCH -e logs/mob_recon_%A_%a.err
# -----------------------------------------------------------------------------
# Mob_recon: Reconstruct plasmids from fragmented assemblies and run typing
#
# Run one sample: sbatch mob_recon.sh <sample_id>
# Run whole batch: sbatch --array=1-15 mob_recon.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/path/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
# branched fragmentation based on illumina samples, project specific
if [[ "$PLATFORM" != "ilm" ]]; then
    echo "skip ${SAMPLE_ID} - bad platform"
    exit 0
fi

[[ -d "$MOBSUITE_DB" ]] || { echo "missing db" >&2; exit 1; }

activate_env "$MOBSUITE_ENV"

# Bakta .fna causes mob_recon to stop at __tmp files, might be header issues with [strain=...]
NUC="${WORKDIR}/final_assembly.fna"
MOBDIR="${WORKDIR}/mobsuite"

mob_recon \
    --infile "$NUC" \
    --outdir "${MOBDIR}/recon" \
    -d "$MOBSUITE_DB" \
    --num_threads "$THREADS" \
    --force

run_info mob_recon
echo "done ${SAMPLE_ID} - ${MOBDIR}/recon"
