#!/bin/bash
#SBATCH --job-name=pharokka
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=40G
#SBATCH -o logs/pharokka_%A_%a.out
#SBATCH -e logs/pharokka_%A_%a.err
# -----------------------------------------------------------------------------
# Pharokka: viral annotation
#
# Concatenates CheckV $WORKDIR/viruses_clean.fna and proviruses_clean
#
# Run one sample: sbatch pharokka.sh <sample_id>
# Run whole batch: sbatch --array=1-15 pharokka.sh
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/path/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
activate_env "$PHAGE_ENV"

VIRUS="${WORKDIR}/viruses_clean.fna"
PROVIRUS="${WORKDIR}/proviruses_clean.fna"
ALL_VIRUSES="${WORKDIR}/all_viruses.fna"

# concatenate the viruses.fna and proviruses.fna outputs from checkv
vtypes=()
[[ -s "$VIRUS" ]] && vtypes+=("$VIRUS")
[[ -s "$PROVIRUS" ]] && vtypes+=("$PROVIRUS")

if [[ ${#vtypes[@]} -eq 0 ]]; then
    echo "both files empty or missing" >&2
    exit 1
fi
cat "${vtypes[@]}" > "$ALL_VIRUSES"

PHAROKDIR="${WORKDIR}/pharokka"
mkdir -p "$PHAROKDIR"

# -m is needed for multiple genomes concatenated but it fails the run for single phage genome
n_phages=$(grep -c '^>' "$ALL_VIRUSES")
args=(
    -i "$ALL_VIRUSES"
    -o "$PHAROKDIR"
    -p "$SAMPLE_ID"
    -d "$PHAROKKA_DB"
    -t "$THREADS"
    --force
)
[[ "$n_phages" -gt 1 ]] && args+=(-m)
# current version warns that pharokka.py will move to pharokka run soon
pharokka.py "${args[@]}"

run_info pharokka
echo "done ${SAMPLE_ID} ${PHAROKDIR}"
