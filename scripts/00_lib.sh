#!/usr/bin/env bash
# =============================================================================
# lib.sh - shared pipeline source
# =============================================================================
# Initializes conda, sample info, and paths for each script
#
# How it works within a script:
#    PIPELINE_DIR="${PIPELINE_DIR:-/labs/Hird/usr/EAGER_sequences/scripts}"
#    source "${PIPELINE_DIR}/lib.sh"
#    pipeline_init "$@" # config + conda + resolve sample
#    resolve_reads # pre-assembly only: sets R1/R2/ONT
#    OR
#    require_assembly # post-assembly only: checks ASSEMBLY
#    run_info <tool> # records date, time, script, env, and tool version
#
# Running Samples
#	sbatch <script.sh> <sample_id>
#	sbatch --array=1-15 <script.sh>
# =============================================================================

set -Eeuo pipefail
trap 'rc=$?; echo "${SAMPLE_ID:-?} - ${BASH_SOURCE[0]}:${LINENO} exited ${rc}" >&2' ERR

# locate and source the config files
# lib.sh is in $SCRIPTS, alongside the config files
if [[ -n "${PIPELINE_DIR:-}" ]]; then
    _LIB_DIR="$PIPELINE_DIR"
else
    _LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
for _cfg in paths.config run.config; do
    if [[ ! -f "${_LIB_DIR}/${_cfg}" ]]; then
        echo "${_cfg} missing" >&2
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${_LIB_DIR}/${_cfg}"
done

# file must exist and be non-empty
_require_file() {
    [[ -s "$1" ]] || { echo "${SAMPLE_ID:-?} - missing or empty: $1" >&2; return 1; }
}

# conda ensure new miniforge is used over hpc shared module
_conda_setup() {
    export PATH="${CONDA_BASE}/condabin:${PATH}"
    local hook="${CONDA_BASE}/etc/profile.d/conda.sh"
    if [[ ! -f "$hook" ]]; then
        echo "conda.sh not found at ${hook}" >&2
        exit 1
    fi
    set +u
    # shellcheck source=/dev/null
    source "$hook"
    set -u
}

# activate conda env by prefix
activate_env() {
    local env_prefix="$1"
    if [[ ! -d "$env_prefix" ]]; then
        echo "${env_prefix} missing" >&2
        exit 1
    fi
    set +u
    conda activate "$env_prefix"
    set -u
}

# check samples.csv
# data rows = non-header, non-blank lines, header is line 1.
_csv_data_rows() { tail -n +2 "$SAMPLES_CSV" | tr -d '\r' | grep -v '^[[:space:]]*$' || true; }

# resolve the sample id for this run: $1 if given, else the SLURM array index into data rows
_resolve_sample_id() {
    local arg="${1:-}"
    if [[ -n "$arg" ]]; then
        echo "$arg"; return
    fi
    if [[ -n "${SLURM_ARRAY_TASK_ID:-}" ]]; then
        local row
        row="$(_csv_data_rows | sed -n "${SLURM_ARRAY_TASK_ID}p")"
        if [[ -z "$row" ]]; then
            echo "SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID} has no matching row ${SAMPLES_CSV}" >&2
            exit 1
        fi
        echo "$row" | cut -d',' -f1
        return
    fi
    echo "sample id missing" >&2
    exit 1
}

# load samples.csv
_load_sample_row() {
    local row
    row="$(_csv_data_rows | awk -F',' -v id="$SAMPLE_ID" '$1==id{print; exit}')" || true
    if [[ -z "$row" ]]; then
        echo "${SAMPLE_ID} - not found in ${SAMPLES_CSV}" >&2
        exit 1
    fi
    # SAMPLE_ID reassigned from the matched row
    IFS=',' read -r SAMPLE_ID PLATFORM ONT_READS ILM_R1 ILM_R2 STRAIN LOCUS_TAG_PREFIX <<< "$row"
    case "$PLATFORM" in
        ont|ilm|hybrid) ;;
        *) echo "${SAMPLE_ID} - bad platform: ${PLATFORM}" >&2; exit 1 ;;
    esac
    # working directory - where final_assembly.fna, raw, and filtered reads are
    if [[ "$ONT_READS" != "NA" ]]; then
        WORKDIR="$(dirname "$ONT_READS")"
    else
        WORKDIR="$(dirname "$ILM_R1")"
    fi
    if [[ ! -d "$WORKDIR" ]]; then
        echo "${SAMPLE_ID} - workdir is not a directory" >&2
        exit 1
    fi
    ASSEMBLY="${WORKDIR}/final_assembly.fna"
    # THREADS from SLURM allocation
    THREADS="${SLURM_CPUS_PER_TASK:-4}"
    export SAMPLE_ID PLATFORM ONT_READS ILM_R1 ILM_R2 STRAIN LOCUS_TAG_PREFIX WORKDIR ASSEMBLY THREADS
}

# general setup for all scripts
pipeline_init() {
    PIPELINE_CMD="$(basename "${0}") ${*}"
    export PIPELINE_CMD
    _conda_setup
    SAMPLE_ID="$(_resolve_sample_id "${1:-}")"
    _load_sample_row
    echo "[$(date '+%F %T')] sample=${SAMPLE_ID} platform=${PLATFORM} workdir=${WORKDIR} threads=${THREADS}"
}

# for pre-assembly scripts
resolve_reads() {
    local missing=0
    case "$PLATFORM" in
        ont) R1=""; R2=""; ONT="$ONT_READS"; _require_file "$ONT" || missing=1 ;;
        ilm) ONT=""; R1="$ILM_R1"; R2="$ILM_R2"; _require_file "$R1" || missing=1; _require_file "$R2" || missing=1 ;;
        hybrid) ONT="$ONT_READS"; R1="$ILM_R1"; R2="$ILM_R2"; _require_file "$ONT" || missing=1; _require_file "$R1" || missing=1; _require_file "$R2" || missing=1 ;;
    esac
    (( missing == 0 )) || exit 1
    export R1 R2 ONT
}

# for scripts post-assembly
# instead of resolve_reads
require_assembly() {
    _require_file "$ASSEMBLY" || exit 1
}

# records run info for reproducability, use run_info <tool_name>
run_info() {
    local log="${WORKDIR}/.info.log"
    local t v
    {
        echo "----"
        echo "time: $(date -u +%FT%TZ)"
        echo "sample: ${SAMPLE_ID}"
        echo "script: ${SLURM_JOB_NAME:-$(basename "$0")}"
        echo "cmd: ${PIPELINE_CMD:-n/a}"
        echo "job: ${SLURM_JOB_ID:-local}"
        echo "env: ${CONDA_PREFIX:-n/a}"
        for t in "$@"; do
            # </dev/null so a tool that reads stdin (e.g. -v meaning verbose)
            # cannot hang the job
            v="$( { "$t" --version || "$t" -version || "$t" -v; } </dev/null 2>&1 | head -1 || true)"
            echo "tool: ${t} ${v:-n/a}"
        done
    } >> "$log"
}
