#!/bin/bash
#SBATCH --job-name=hhsearch
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=64G
#SBATCH -o logs/hhsearch_%j.out
#SBATCH -e logs/hhsearch_%j.err
# -----------------------------------------------------------------------------
# HHsearch
#
# Runs on directory full of a3m files against 4 databases
#
# sbatch hhsearch.sh <sample_id>
# -----------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/labs/Hird/usr/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"
activate_env "$HHSEARCH_ENV"

A3M_DIR="${WORKDIR}/a3m_build/a3m"
OUT_DIR="${WORKDIR}/hhsearch"
[[ -d "$A3M_DIR" ]] || { echo "missing dir ${A3M_DIR}" >&2; exit 1; }
mkdir -p "$OUT_DIR"

shopt -s nullglob
A3M_FILES=("$A3M_DIR"/*.a3m)
(( ${#A3M_FILES[@]} )) || { echo "no .a3m files in ${A3M_DIR}" >&2; exit 1; }

N=0
for A3M in "$A3M_DIR"/*.a3m; do
    NAME=$(basename "${A3M%.a3m}")
    hhsearch -i "$A3M" \
        -d "$HHPFAM_DB" -d "$HHPHROG_DB" -d "$HHVIR_DB" -d "$HHNCBICD_DB" \
        -o "${OUT_DIR}/${NAME}.hhr" \
        -cpu "$THREADS"
    N=$((N+1))
    echo "[${N}] ${NAME}"
done

run_info hhsearch
echo "done ${SAMPLE_ID} - ${N} protein(s) ${OUT_DIR}"
