#!/bin/bash
#SBATCH --job-name=genomad
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=64G
#SBATCH -o logs/genomad_%A_%a.out
#SBATCH -e logs/genomad_%A_%a.err
# -----------------------------------------------------------------------------
# geNomad: identify viral / proviral and plasmid sequence in the assembly.
#
# Copies the combined prophage / virus assemblies into
#    $WORKDIR/S$AMPLE_ID_virus.fna
#
# Run one sample: sbatch genomad.sh <sample_id>
# Run whole batch: sbatch --array=1-15 genomad.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/path/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
require_assembly
activate_env "$GENOMAD_ENV"

[[ -d "$GENOMAD_DB" ]] || { echo "missing db" >&2; exit 1; }

GMDIR="${WORKDIR}/genomad"
mkdir -p "$GMDIR"

genomad end-to-end \
    --conservative \
    --enable-score-calibration \
    --threads "$THREADS" \
    "$ASSEMBLY" \
    "$GMDIR" \
    "$GENOMAD_DB"

# copy viral sequence
VIRUS_SRC=$(find "$GMDIR" -name '*_virus.fna' | head -1)
VIRUS_OUT="${WORKDIR}/${SAMPLE_ID}_virus.fna"

if [[ ! -s "$VIRUS_SRC" ]]; then
    echo "${SAMPLE_ID} - virus fasta is empty or missing" >&2
else
    cp "$VIRUS_SRC" "$VIRUS_OUT"
    echo "virus - $(basename "$VIRUS_OUT")"
fi

run_info genomad
echo "done ${SAMPLE_ID} ${GMDIR}"
