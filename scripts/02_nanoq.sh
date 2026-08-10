#!/bin/bash
#SBATCH --job-name=nanoq
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=8G
#SBATCH -o logs/nanoq_%A_%a.out
#SBATCH -e logs/nanoq_%A_%a.err
# -----------------------------------------------------------------------------
# Nanoq ONT Read Metrics Reporting
#
# Run before and/or after hybracter
#
# Inputs:
#   raw : ont_reads path from samples.csv
#   filtered : ${WORKDIR}/${SAMPLE_ID}_filt_trim.fastq.gz
#
# Run one sample: sbatch nanoq.sh <sample_id>
# Run whole batch: sbatch --array=1-15 nanoq.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/labs/Hird/usr/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"

if [[ "$PLATFORM" == "ilm" ]]; then
    echo "skip ${SAMPLE_ID} - bad platform"
    exit 0
fi

resolve_reads
activate_env "$QC_ENV"

REPORTDIR="${WORKDIR}/qc_reports"
mkdir -p "$REPORTDIR"

FILTERED="${WORKDIR}/${SAMPLE_ID}_filt_trim.fastq.gz"

# for nanoplot like results
NANOQ_FLAGS=(-f -s -t 5 -vvv)
run_nanoq() {
    local label="$1" infile="$2" out="$3"
    echo "nanoq ${label}: $(basename "$infile")"
    nanoq -i "$infile" "${NANOQ_FLAGS[@]}" > "$out"
    [[ -s "$out" ]] || { echo "nanoq output missing for ${label}" >&2; exit 1; }
    echo "${label}"
    cat "$out"
    echo ""
}

# $1 raw (string), $2 read path, $3 out path
run_nanoq "RAW" "$ONT" "${REPORTDIR}/${SAMPLE_ID}_nanoq_raw.txt"

# filtered read
if [[ -s "$FILTERED" ]]; then
    run_nanoq "FILTERED" "$FILTERED" "${REPORTDIR}/${SAMPLE_ID}_nanoq_filtered.txt"
else
    echo "filtered reads missing"
fi

run_info nanoq
echo "done ${SAMPLE_ID} - reports in ${REPORTDIR}"
