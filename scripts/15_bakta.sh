#!/bin/bash
#SBATCH --job-name=bakta
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=32G
#SBATCH -o logs/bakta_%A_%a.out
#SBATCH -e logs/bakta_%A_%a.err
# -----------------------------------------------------------------------------
# Bakta annotation
#
# Handling samples.csv parameters
#       replicons.csv - uses it if present in $WORKDIR
#       strain - name required in samples.csv
# Can build in logic for adding locus_tags, none in here right now
#
# Run one sample: sbatch bakta.sh <sample_id> # optional <replicons.csv>
# Run whole batch: sbatch --array=1-15 bakta.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/path/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
require_assembly
activate_env "$BAKTA_ENV"

[[ -d "$BAKTA_DB" ]] || { echo "bakta database not found" >&2; exit 1; }

OUTDIR="${WORKDIR}/bakta"
mkdir -p "$OUTDIR"

# optional replicon table
REPLICONS="${WORKDIR}/replicons.csv"
REP_ARGS=()
if [[ -s "$REPLICONS" ]]; then
    REP_ARGS=(--replicons "$REPLICONS")
    echo "using replicons.csv from $(basename "$REPLICONS")"
else
    echo "replicons.csv missing"
fi

bakta --db "$BAKTA_DB" \
      --compliant \
      --strain "$STRAIN" \
      --prefix "$SAMPLE_ID" \
      --output "$OUTDIR" \
      --threads "$THREADS" \
      "${REP_ARGS[@]}" \
      --force \
      "$ASSEMBLY"

run_info bakta
echo "done ${SAMPLE_ID} - annotation in ${OUTDIR}"
