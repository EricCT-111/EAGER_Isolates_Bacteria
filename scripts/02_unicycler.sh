#!/bin/bash
#SBATCH --job-name=unicycler
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=64G
#SBATCH -o logs/unicycler_%A_%a.out
#SBATCH -e logs/unicycler_%A_%a.err
# -----------------------------------------------------------------------------
# Illumina de-novo assembler
#
# Requires filtered reads in the following format:
#     ${WORKDIR}/${SAMPLE_ID}_1.fastq.gz
#     ${WORKDIR}/${SAMPLE_ID}_2.fastq.gz
#
# Run one sample: sbatch unicycler.sh <sample_id>
# Run whole batch: sbatch --array=1-15 unicycler.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/path/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"

case "$PLATFORM" in
    ilm) ;;
    hybrid|ont)
        echo "[skip] ${SAMPLE_ID} is ${PLATFORM}"
        exit 0 ;;
esac

activate_env "$ASSEMBLY_ENV"

# check filtered reads
R1_FILT="${WORKDIR}/${SAMPLE_ID}_1.fastq.gz"
R2_FILT="${WORKDIR}/${SAMPLE_ID}_2.fastq.gz"
for f in "$R1_FILT" "$R2_FILT"; do
    [[ -f "$f" ]] || { echo "${SAMPLE_ID} filtered reads missing $f" >&2; exit 1; }
done

UNI_OUT="${WORKDIR}/unicycler"
mkdir -p "$UNI_OUT"

unicycler \
    -1 "$R1_FILT" \
    -2 "$R2_FILT" \
    -o "$UNI_OUT" \
    -t "$THREADS"

# check output
ASM="${UNI_OUT}/assembly.fasta"
[[ -s "$ASM" ]] || { echo "${SAMPLE_ID} assembly missing or empty" >&2; exit 1; }

# pull .gfa graph for use in bandage
if [[ -s "${UNI_OUT}/assembly.gfa" ]]; then
    cp "${UNI_OUT}/assembly.gfa" "${WORKDIR}/${SAMPLE_ID}_assembly.gfa"
fi
# unpolished assembly kept separate, post polishing makes it final_assembly.fna
run_info unicycler
echo "done ${SAMPLE_ID} unpolished assembly at ${ASM}, graph at ${WORKDIR}/${SAMPLE_ID}_assembly.gfa"
