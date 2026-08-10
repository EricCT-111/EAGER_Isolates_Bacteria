#!/bin/bash
#SBATCH --job-name=a3m_jackhmmer
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 12
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=142G
#SBATCH -o logs/a3m_jackhmmer_%j.out
#SBATCH -e logs/a3m_jackhmmer_%j.err

###############################################################################
# Build a3m MSAs on unresolved proteins (for later HHsearch)
#
###############################################################################
set -euo pipefail

source /labs/Hird/usr/miniforge3/etc/profile.d/conda.sh
conda activate /labs/Hird/usr/EAGER_sequences/project_tools/hhsearch_env

# inputs / config
# requires prior step using seqkit to create target protein fasta
TARGETS_FAA="/labs/Hird/usr/EAGER_sequences/ont_analysis/barcode13_88879g10/phage_targets.faa"
REF_UNIREF50="/isg/shared/databases/uniprot/v2025.06/uniref50.fasta" #DB for jackhmmer
CPU=12
N_ITER=5 # jackhmmer iterations

OUTDIR="/labs/Hird/usr/EAGER_sequences/ont_analysis/barcode13_88879g10/a3m_build"
mkdir -p "$OUTDIR"/{split,msa,a3m,logs}

# split protein fasta into individual files
awk -v d="$OUTDIR/split" '
    /^>/{ id=substr($1,2); gsub(/[^A-Za-z0-9_.-]/,"_",id); f=d"/"id".faa" }
    { print > f }
' "$TARGETS_FAA"

# jackhmmer to sto to a3m
for faa in "$OUTDIR"/split/*.faa; do
    id=$(basename "$faa" .faa)
    sto="$OUTDIR/msa/${id}.sto"
    a3m="$OUTDIR/a3m/${id}.a3m"

    echo ">>> $id"
    jackhmmer -N "$N_ITER" --cpu "$CPU" \
        -E 0.001 --incE 1e-4 --incdomE 1e-5 \
        -A "$sto" \
        --tblout "$OUTDIR/logs/${id}.tblout" \
        -o /dev/null \
        "$faa" "$REF_UNIREF50"

    reformat.pl sto a3m "$sto" "$a3m"
done

echo "done a3m files: $OUTDIR/a3m/*.a3m"
