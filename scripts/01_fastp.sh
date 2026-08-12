#!/bin/bash
#SBATCH --job-name=fastp
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=16G
#SBATCH -o logs/fastp_%A_%a.out
#SBATCH -e logs/fastp_%A_%a.err
# -----------------------------------------------------------------------------
# Illumina read filtering with fastp
#
# Reads the raw Illumina paths from samples.csv (ilm_r1 / ilm_r2) columns
# Writes filtered reads into the sample's $WORKDIR under
#     ${WORKDIR}/${SAMPLE_ID}_1.fastq.gz
#     ${WORKDIR}/${SAMPLE_ID}_2.fastq.gz
#
# Filtering parameters come from $FASTP_OPTS in run.config.
#
# Run one sample: sbatch fastp.sh <sample_id>
# Run whole batch: sbatch --array=1-15 fastp.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/path/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"

case "$PLATFORM" in
    ilm) ;;
    hybrid)
        echo "${SAMPLE_ID} - bad platform"
        exit 0 ;;
    ont)
        echo "${SAMPLE_ID} - bad platform"
        exit 0 ;;
esac

resolve_reads
activate_env "$QC_ENV"

REPORTDIR="${WORKDIR}/qc_reports"
mkdir -p "$REPORTDIR"

OUT_R1="${WORKDIR}/${SAMPLE_ID}_1.fastq.gz"
OUT_R2="${WORKDIR}/${SAMPLE_ID}_2.fastq.gz"

# FASTP_OPTS is intentionally unquoted so it word splits into separate flags.
fastp \
    -i "$R1" -I "$R2" \
    -o "$OUT_R1" -O "$OUT_R2" \
    $FASTP_OPTS \
    --thread "$THREADS" \
    --json "${REPORTDIR}/${SAMPLE_ID}_fastp.json" \
    --html "${REPORTDIR}/${SAMPLE_ID}_fastp.html"

run_info fastp
echo "done ${SAMPLE_ID} - filtered reads in ${WORKDIR}, reports in ${REPORTDIR}"
