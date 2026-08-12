#!/bin/bash
#SBATCH --job-name=taxmyphage
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=40G
#SBATCH -o logs/taxmyphage_%A_%a.out
#SBATCH -e logs/taxmyphage_%A_%a.err
# -----------------------------------------------------------------------------
# taxMyPhage: Phage taxonomy using ICTV database
#
# Takes the $WORKDIR/$ALL_VIRUSES concatenated in pharokka.sh
#
# Run one sample: sbatch vcontact.sh <sample_id>
# Run whole batch: sbatch --array=1-15 taxmyphage.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/path/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
activate_env "$TAXMYPHAGE_ENV"

[[ -d "$TAXMYPHAGE_DB" ]] || { echo "${SAMPLE_ID} missing taxmyphage db" >&2; exit 1; }

ALL_VIRUSES="${WORKDIR}/all_viruses.fna"

[[ -s "$ALL_VIRUSES" ]] || { echo "${SAMPLE_ID} - no viral sequence" >&2; exit 0; }

TAXOUT="${WORKDIR}/taxmyphage"
mkdir -p "$TAXOUT"

taxmyphage run -i "${ALL_VIRUSES}" -o "${TAXOUT}" -db "${TAXMYPHAGE_DB}"

run_info taxmyphage
echo "done ${SAMPLE_ID} ${TAXOUT}"
