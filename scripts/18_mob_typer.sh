#!/bin/bash
#SBATCH --job-name=mob_typer
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=16G
#SBATCH -o logs/mob_typer_%A_%a.out
#SBATCH -e logs/mob_typer_%A_%a.err
# -----------------------------------------------------------------------------
# Mob_typer
#
# Run one sample: sbatch mob_typer.sh <sample_id>
# Run whole batch: sbatch --array=1-15 mobtyper.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/labs/Hird/usr/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
# branched fragmented/unfragmented by platform, project specific
if [[ "$PLATFORM" == "ilm" ]]; then
    echo "skip ${SAMPLE_ID} - bad platform"
    exit 0
fi

[[ -d "$MOBSUITE_DB" ]] || { echo "missing db" >&2; exit 1; }

activate_env "$MOBSUITE_ENV"

NUC="${WORKDIR}/bakta/${SAMPLE_ID}.fna"
[[ -s "$NUC" ]] || { echo "${SAMPLE_ID} bakta fna missing" >&2; exit 1; }

MOBDIR="${WORKDIR}/mobsuite"
mkdir -p "$MOBDIR"

mob_typer \
    --multi \
    --infile "$NUC" \
    --out_file "${MOBDIR}/${SAMPLE_ID}_mobtyper.txt" \
    --biomarker_report "${MOBDIR}/${SAMPLE_ID}_biomarkers.txt" \
    -g "${MOBDIR}/${SAMPLE_ID}_mge.txt" \
    -d "$MOBSUITE_DB" \
    --num_threads "$THREADS"

run_info mob_typer
echo "done ${SAMPLE_ID} ${MOBDIR}"
