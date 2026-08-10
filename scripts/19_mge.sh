#!/bin/bash
#SBATCH --job-name=mge
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=32G
#SBATCH -o logs/mge_%A_%a.out
#SBATCH -e logs/mge_%A_%a.err
# -----------------------------------------------------------------------------
# Mobile genetic element detection:
# ISEScan + IntegronFinder.
#
# Run one sample: sbatch mge.sh <sample_id>
# Run whole batch: sbatch --array=1-15 mge.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/labs/Hird/usr/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
activate_env "$MGE_ENV"

# bakta.fna as input
NUC="${WORKDIR}/bakta/${SAMPLE_ID}.fna"
[[ -s "$NUC" ]] || { echo "${SAMPLE_ID} bakta fna missing" >&2; exit 1; }

MGEDIR="${WORKDIR}/mge"
mkdir -p "$MGEDIR"

# illumina samples were fragmented, so treat platform as linear
[[ "$PLATFORM" == "ilm" ]] && TOPO=(--linear) || TOPO=(--circ)

RC_IS=0; RC_IF=0

# ISEScan
isescan.py \
    --seqfile "$NUC" \
    --output "${MGEDIR}/isescan" \
    --nthread "$THREADS" || RC_IS=$?
(( RC_IS == 0 )) || echo "isescan exited ${RC_IS}" >&2

# IntegronFinder
    "${TOPO[@]}" \
    --pdf \
    --outdir "${MGEDIR}/integron_finder" \
    --cpu "$THREADS" \
    "$NUC" || RC_IF=$?
(( RC_IF == 0 )) || echo "integron_finder exited ${RC_IF}" >&2

run_info isescan.py integron_finder

# fail only if both tools failed
if (( RC_IS != 0 && RC_IF != 0 )); then
    echo "both MGE tools failed" >&2; exit 1
fi
echo "done ${SAMPLE_ID} - ${MGEDIR}"
