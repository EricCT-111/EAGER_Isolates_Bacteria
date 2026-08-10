#!/bin/bash
#SBATCH --job-name=hybracter
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=64G
#SBATCH -o logs/hybracter_%A_%a.out
#SBATCH -e logs/hybracter_%A_%a.err
# ------------------------------------------------------------------------------------
# Hybracter qc, assembly, polishing
#
# ONT only and Hybrid samples handled
#   - hybrid sample - hybracter hybrid-single (ONT + Illumina polishing)
#   - ont sample - hybracter long-single (ONT only, Medaka polishing)
#
# Run one sample: sbatch hybracter.sh <sample_id>
# Run whole batch: sbatch --array=1-15 hybracter.sh
#
# **The filtered ont and illumina reads are not copied to WORKDIR, do this manually**
# -------------------------------------------------------------------------------------
PIPELINE_DIR="${PIPELINE_DIR:-/labs/Hird/usr/EAGER_sequences/scripts}"
source "${PIPELINE_DIR}/lib.sh"
pipeline_init "$@"

# check platform
if [[ "$PLATFORM" == "ilm" ]]; then
    echo "skip ${SAMPLE_ID} - bad platform"
    exit 0
fi

resolve_reads
activate_env "$HYBRACTER_ENV"

[[ -d "$HYBRACTER_DB" ]] || { echo "midding db" >&2; exit 1; }

# conda >=24.7.1 is required
HYBRACTER_OUT="${WORKDIR}/hybracter"
mkdir -p "$HYBRACTER_OUT"

case "$PLATFORM" in
    hybrid)
        echo "hybracter hybrid-single on ${SAMPLE_ID}"
        hybracter hybrid-single \
            -l "$ONT" \
            -1 "$R1" \
            -2 "$R2" \
            -s "$SAMPLE_ID" \
            -o "$HYBRACTER_OUT" \
            --flyeModel --nano-hq \
            --auto \
            -t "$THREADS" \
            --force
        ;;
    ont)
        echo "hybracter long-single on ${SAMPLE_ID}"
        hybracter long-single \
            -l "$ONT" \
            -s "$SAMPLE_ID" \
            -o "$HYBRACTER_OUT" \
            --flyeModel --nano-hq \
            --auto \
            --databases "$PLASSEMBLER_DB" \
            -t "$THREADS" \
            --force
        ;;
esac

# copy the final assembly to WORKDIR
FINAL_SRC=""
for state in complete incomplete; do
    cand="${HYBRACTER_OUT}/FINAL_OUTPUT/${state}/${SAMPLE_ID}_final.fasta"
    if [[ -s "$cand" ]]; then
        FINAL_SRC="$cand"
        COMPLETENESS="$state"
        break
    fi
done

cp "$FINAL_SRC" "$ASSEMBLY"

run_info hybracter
echo "done ${SAMPLE_ID} - ${ASSEMBLY}"
