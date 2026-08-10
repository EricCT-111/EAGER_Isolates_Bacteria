#!/bin/bash
#SBATCH --job-name=checkv
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=16G
#SBATCH -o logs/checkv_%A_%a.out
#SBATCH -e logs/checkv_%A_%a.err
# -----------------------------------------------------------------------------
# CheckV: viral completeness and contamination
#
# Takes the $WORKDIR/$SAMPLE_ID_virus.fna from genomad
# Cleaned virus fasta in $WORKDIR/checkv/virus.fna
#
# Run one sample: sbatch checkv.sh <sample_id>
# Run whole batch: sbatch --array=1-15 checkv.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/labs/Hird/usr/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
activate_env "$PHAGE_ENV"

VIRUS="${WORKDIR}/${SAMPLE_ID}_virus.fna"
[[ -s "$VIRUS" ]] || { echo "${SAMPLE_ID} - no viral sequence" >&2; exit 0; }
[[ -d "$CHECKV_DB" ]] || { echo "missing checkv db" >&2; exit 1; }

CVDIR="${WORKDIR}/checkv"
mkdir -p "$CVDIR"

N_VIRUS=$(grep -c '^>' "$VIRUS")

checkv end_to_end "$VIRUS" "$CVDIR" -d "$CHECKVDB" -t "$THREADS"

# copy checkv outputs to $WORKDIR for downstream use
for f in proviruses viruses; do
    SRC="${CVDIR}/${f}.fna"
    DST="${WORKDIR}/${f}_clean.fna"
    if [[ -s "$SRC" ]]; then
        cp "$SRC" "$DST"
        echo "copy ${f}.fna - $(basename "$DST") ($(grep -c '^>' "$DST" || true) seqs)"
    else
        rm -f "$DST"
        echo "no ${f} - removed $(basename "$DST")"
    fi
done

run_info checkv
echo "done ${SAMPLE_ID}"
