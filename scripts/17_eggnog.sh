#!/bin/bash
#SBATCH --job-name=eggnog
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=96G
#SBATCH -o logs/eggnog_%A_%a.out
#SBATCH -e logs/eggnog_%A_%a.err
# -----------------------------------------------------------------------------
# eggNOG-mapper: functional annotation of the bakta proteins.
#
# Run one sample: sbatch eggnog.sh <sample_id>
# Run whole batch: sbatch --array=1-15 eggnog.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/labs/Hird/usr/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
activate_env "$METABOLISM_ENV"

[[ -d "$EGGNOG_DB" ]] || { echo "database missing" >&2; exit 1; }

BAKTADIR="${WORKDIR}/bakta"
PROT="${BAKTADIR}/${SAMPLE_ID}.faa"
GFF="${BAKTADIR}/${SAMPLE_ID}.gff3"
for f in "$PROT" "$GFF"; do
    [[ -s "$f" ]] || { echo "${SAMPLE_ID} bakta output missing: $f" >&2; exit 1; }
done

OUTDIR="${WORKDIR}/eggnog"
mkdir -p "$OUTDIR"

emapper.py \
    -i "$PROT" \
    --itype proteins \
    -m diamond \
    --sensmode sensitive \
    --data_dir "$EGGNOG_DB" \
    --decorate_gff "$GFF" \
    --decorate_gff_ID_field locus_tag \
    --output "$SAMPLE_ID" \
    --output_dir "$OUTDIR" \
    --cpu "$THREADS" \
    --override

ANN="${OUTDIR}/${SAMPLE_ID}.emapper.annotations"
[[ -s "$ANN" ]] || { echo "missing or empty annotation file" >&2; exit 1; }

run_info eggnog
echo "done ${SAMPLE_ID} ${OUTDIR}"
