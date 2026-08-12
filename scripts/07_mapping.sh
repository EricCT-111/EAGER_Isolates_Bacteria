#!/bin/bash
#SBATCH --job-name=mapping
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=32G
#SBATCH -o logs/mapping_%A_%a.out
#SBATCH -e logs/mapping_%A_%a.err
# -----------------------------------------------------------------------------
# Read mapping + coverage/alignment stats against the final assembly.
#
# Hybrid samples produce results from each platform (ilm/ont)
#
# Uses the filtered reads from hybracter:
#   ONT: ${SAMPLE_ID}_filt_trim.fastq.gz
#   Illumina: ${SAMPLE_ID}_1.fastq.gz ${SAMPLE_ID}_2.fastq.gz
#
# Run one sample: sbatch mapping.sh <sample_id>
# Run whole batch: sbatch --array=1-15 mapping.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/path/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
require_assembly
activate_env "$QC_ENV"

MAPDIR="${WORKDIR}/mapping"
mkdir -p "$MAPDIR"

# filtered read paths
ONT_FILT="${WORKDIR}/${SAMPLE_ID}_filt_trim.fastq.gz"
R1_FILT="${WORKDIR}/${SAMPLE_ID}_1.fastq.gz"
R2_FILT="${WORKDIR}/${SAMPLE_ID}_2.fastq.gz"

# Outputs per platform:
#   *.coverage.tsv per-contig depth (samtools coverage)
#   *.stats.txt full alignment metrics (samtools stats)
# Nanopore mapping
map_ont() {
    local bam="${MAPDIR}/${SAMPLE_ID}.ont.sorted.bam"
    minimap2 -t "$THREADS" -ax map-ont "$ASSEMBLY" "$ONT_FILT" \
        | samtools sort -@ "$THREADS" -o "$bam" -
    samtools index "$bam"
    samtools coverage "$bam" > "${MAPDIR}/${SAMPLE_ID}.ont.coverage.tsv"
    samtools stats -@ "$THREADS" "$bam" > "${MAPDIR}/${SAMPLE_ID}.ont.stats.txt"
    echo "ONT stats + cov done"
}

# Illumina mapping
map_ilm() {
    local bam="${MAPDIR}/${SAMPLE_ID}.ilm.sorted.bam"
    local idx="${MAPDIR}/${SAMPLE_ID}.bwaidx"
    bwa-mem2 index -p "$idx" "$ASSEMBLY"
    bwa-mem2 mem -t "$THREADS" "$idx" "$R1_FILT" "$R2_FILT" \
        | samtools sort -@ "$THREADS" -o "$bam" -
    samtools index "$bam"
    samtools coverage "$bam" > "${MAPDIR}/${SAMPLE_ID}.ilm.coverage.tsv"
    samtools stats -@ "$THREADS" "$bam" > "${MAPDIR}/${SAMPLE_ID}.ilm.stats.txt"
    rm -f "${idx}"* # cleanup
    echo "illumina stats + cov done"
}

# platform branching
case "$PLATFORM" in
    ont)
        "$ONT_FILT"; map_ont ;;
    ilm)
        "$R1_FILT"; _need "$R2_FILT"; map_ilm ;;
    hybrid)
        "$ONT_FILT"; _need "$R1_FILT"; _need "$R2_FILT"
        map_ont
        map_ilm ;;
esac

run_info bwamem2 minimap2 samtools
echo "done ${SAMPLE_ID} - mapping + stats in ${MAPDIR}"
