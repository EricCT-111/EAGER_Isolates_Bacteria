#!/bin/bash
#SBATCH --job-name=polish
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=32G
#SBATCH -o logs/polish_%A_%a.out
#SBATCH -e logs/polish_%A_%a.err
# -----------------------------------------------------------------------------
# Polishing Unicycler Assembly
#
# Output: ${WORKDIR}/final_assembly.fna
#
# Run one sample: sbatch polish.sh <sample_id>
# Run whole batch: sbatch --array=1-15 run_polish.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/path/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"

case "$PLATFORM" in
    ilm) ;;
    hybrid|ont)
        echo "skip ${SAMPLE_ID} - bad platform"
        exit 0 ;;
esac

require_assembly
activate_env "$POLISH_ENV"

# inputs
DRAFT="${WORKDIR}/unicycler/assembly.fasta"
R1_FILT="${WORKDIR}/${SAMPLE_ID}_1.fastq.gz"
R2_FILT="${WORKDIR}/${SAMPLE_ID}_2.fastq.gz"

for f in "$R1_FILT" "$R2_FILT"; do
    [[ -f "$f" ]] || { echo "${SAMPLE_ID} missing reads $f" >&2; exit 1; }
done

POLDIR="${WORKDIR}/polish"
mkdir -p "$POLDIR"

# POLYPOLISH
IDX="${POLDIR}/${SAMPLE_ID}.bwaidx"
bwa-mem2 index -p "$IDX" "$DRAFT"
bwa-mem2 mem -t "$THREADS" -a "$IDX" "$R1_FILT" > "${POLDIR}/aln_1.sam"
bwa-mem2 mem -t "$THREADS" -a "$IDX" "$R2_FILT" > "${POLDIR}/aln_2.sam"

polypolish filter \
    --in1 "${POLDIR}/aln_1.sam" --in2 "${POLDIR}/aln_2.sam" \
    --out1 "${POLDIR}/filt_1.sam" --out2 "${POLDIR}/filt_2.sam"

echo "polypolish polishing"
POLYPOLISH_OUT="${POLDIR}/${SAMPLE_ID}_polypolish.fasta"
polypolish polish "$DRAFT" "${POLDIR}/filt_1.sam" "${POLDIR}/filt_2.sam" \
    > "$POLYPOLISH_OUT" 2> "${POLDIR}/polypolish.log"

[[ -s "$POLYPOLISH_OUT" ]] || { echo "${SAMPLE_ID} polypolish output missing/empty" >&2; exit 1; }

# remove intermediate SAM files
rm -f "${POLDIR}"/aln_*.sam "${POLDIR}"/filt_*.sam "${IDX}"*

# PYPOLCA
echo "pypolca polishing"
pypolca run \
    -a "$POLYPOLISH_OUT" \
    -1 "$R1_FILT" -2 "$R2_FILT" \
    -t "$THREADS" \
    -o "${POLDIR}/pypolca" \
    -p "$SAMPLE_ID" \
    --force

PYPOLCA_OUT="${POLDIR}/pypolca/${SAMPLE_ID}_corrected.fasta"
[[ -s "$PYPOLCA_OUT" ]] || { echo "${SAMPLE_ID} corrected assembly not produced" >&2; exit 1; }

# Copy to $WORKDIR/final_assembly.fna
cp "$PYPOLCA_OUT" "$ASSEMBLY"

run_info polypolish pypolca
echo "done ${SAMPLE_ID} final ${ASSEMBLY}"
