#!/bin/bash
#SBATCH --job-name=vcontact
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=40G
#SBATCH -o logs/vcontact_%A_%a.out
#SBATCH -e logs/vcontact_%A_%a.err
# -----------------------------------------------------------------------------
# vConTACT3: Viral taxonomy based on proteomic clustering using refseq database
#
# Takes the $WORKDIR/$ALL_VIRUSES concatenated in pharokka.sh
#
# Run one sample: sbatch vcontact.sh <sample_id>
# Run whole batch: sbatch --array=1-15 vcontact.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/labs/Hird/usr/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
activate_env "$VCONTACT3_ENV"

[[ -d "$VCONTACT3_DB" ]] || { echo "${SAMPLE_ID} missing vcontact db" >&2; exit 1; }

ALL_VIRUSES="${WORKDIR}/all_viruses.fna"

[[ -s "$ALL_VIRUSES" ]] || { echo "${SAMPLE_ID} - no viral sequence" >&2; exit 0; }

VOUT="${WORKDIR}/vcontact"
mkdir -p "$VOUT"
# QT fail when running newick tree
export QT_QPA_PLATFORM=offscreen
vcontact3 run -n "$ALL_VIRUSES" \
              -o "$VOUT" \
              --db-domain "prokaryotes" \
              --db-version 230 \
              -d "$VCONTACT3_DB" \
              -e centroids profiles ani newick completeness \
              -t "$THREADS" \
              --force-overwrite

run_info vcontact3
echo "done ${SAMPLE_ID} ${VOUT}"
