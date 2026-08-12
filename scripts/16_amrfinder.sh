#!/bin/bash
#SBATCH --job-name=amrfinder
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=16G
#SBATCH -o logs/amrfinder_%A_%a.out
#SBATCH -e logs/amrfinder_%A_%a.err
# -----------------------------------------------------------------------------
# AMRFinderPlus
#
# Inputs from Bakta
#   ${WORKDIR}/bakta/${SAMPLE_ID}.fna
#   ${WORKDIR}/bakta/${SAMPLE_ID}.faa
#   ${WORKDIR}/bakta/${SAMPLE_ID}.gff3
#
# Run one sample: sbatch amrfinder.sh <sample_id> # optional <organism>
# Run whole batch: sbatch --array=1-15 amrfinder.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/path/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
ORGANISM="${2:-}"
pipeline_init "${1:-}"

activate_env "$AMRFINDER_ENV"

# take bakta outputs
BAKTADIR="${WORKDIR}/bakta"
NUC="${BAKTADIR}/${SAMPLE_ID}.fna"
PROT="${BAKTADIR}/${SAMPLE_ID}.faa"
GFF="${BAKTADIR}/${SAMPLE_ID}.gff3"
for f in "$NUC" "$PROT" "$GFF"; do
    [[ -s "$f" ]] || { echo "${SAMPLE_ID} bakta output missing: $f" >&2; exit 1; }
done

# database version check
if [[ -d "${AMRFINDER_DB}/latest" ]]; then DB="${AMRFINDER_DB}/latest"
elif [[ -d "$AMRFINDER_DB" ]]; then DB="$AMRFINDER_DB"
else
    echo "missing db" >&2
    exit 1
fi

# optional organism flag
ORG_ARGS=()
if [[ -n "$ORGANISM" ]]; then
    ORG_ARGS=(--organism "$ORGANISM")
    echo "organism - ${ORGANISM}"
else
    echo "organism - none"
fi

OUTDIR="${WORKDIR}/amrfinder"
mkdir -p "$OUTDIR"
OUT="${OUTDIR}/${SAMPLE_ID}_amrfinder.tsv"

amrfinder \
    --nucleotide "$NUC" \
    --protein "$PROT" \
    --gff "$GFF" \
    --annotation_format bakta \
    --plus \
    --database "$DB" \
    --threads "$THREADS" \
    "${ORG_ARGS[@]}" \
    -o "$OUT"

run_info amrfinder
echo "done ${SAMPLE_ID} ${OUT}"
