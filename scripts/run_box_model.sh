#!/usr/bin/env bash
#
# Build and run the UKCA box model in a fresh, timestamped run directory.
#
# Before running, this script checks that the ukca submodule is checked out
# at the expected tag and has no local modifications, then (re)builds so the
# executable is guaranteed to have been compiled from that UKCA source.
# Provenance (commits, compiler, inputs) is recorded in the run directory.
#
# Usage:
#   scripts/run_box_model.sh [options]
#
# Options:
#   -t TAG     Expected UKCA tag for the submodule      (default: um13.9)
#   -n         Do not rebuild; use the existing executable
#   -o DIR     Parent directory for run directories     (default: runs)
#   -d LEVEL   Debug level passed to the model          (default: 1)
#   -C DIR     Config directory holding namelist.nml    (default: examples/default)
#   -c FILE    Box model namelist                       (overrides -C)
#   -D         Dump all UKCA API inputs/outputs to ukca_dump.txt in the run
#              directory (sets UKCA_DUMP_FILE; see src/box_dump.F90)
#   -h         Show this help
#
# The namelist's IO section names the other input files (environment
# namelist, initial tracers, initial NTP, offline photolysis rates); relative
# paths are relative to the namelist's directory. The whole directory holding
# the namelist is copied into the run directory, so keep config directories
# for inputs only.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UKCA_DIR="${REPO_DIR}/ukca"
BUILD_DIR="${REPO_DIR}/build"
EXE="${BUILD_DIR}/src/ukca_box_model"

ukca_tag="um13.9"
do_build=true
runs_dir="${REPO_DIR}/runs"
debug_level=1
config_dir="${REPO_DIR}/examples/default"
namelist=""
do_dump=false

usage() { sed -n '2,/^$/s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; }
die() { echo "ERROR: $*" >&2; exit 1; }

while getopts "t:no:d:C:c:Dh" opt; do
  case "${opt}" in
    t) ukca_tag="${OPTARG}" ;;
    n) do_build=false ;;
    o) runs_dir="${OPTARG}" ;;
    d) debug_level="${OPTARG}" ;;
    C) config_dir="${OPTARG}" ;;
    c) namelist="${OPTARG}" ;;
    D) do_dump=true ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done

# Without -c, the namelist is the config directory's namelist.nml
namelist="${namelist:-${config_dir}/namelist.nml}"

# --- 1. Check the UKCA submodule ---------------------------------------------
echo "== Checking UKCA submodule"
expected=$(git -C "${UKCA_DIR}" rev-parse --verify --quiet "${ukca_tag}^{commit}") \
  || die "tag '${ukca_tag}' not found in ${UKCA_DIR} (try: git -C ukca fetch --tags)"
actual=$(git -C "${UKCA_DIR}" rev-parse HEAD)

if [[ "${actual}" != "${expected}" ]]; then
  die "ukca submodule is at ${actual:0:7} ($(git -C "${UKCA_DIR}" describe --tags --always)),
       expected ${ukca_tag} = ${expected:0:7}"
fi

if [[ -n "$(git -C "${UKCA_DIR}" status --porcelain)" ]]; then
  git -C "${UKCA_DIR}" status --short >&2
  die "ukca submodule has local modifications - UKCA source must be unmodified"
fi
echo "   ukca = ${ukca_tag} (${expected:0:7}), clean"

# --- 2. Build ----------------------------------------------------------------
if ${do_build}; then
  echo "== Building"
  [[ -f "${BUILD_DIR}/CMakeCache.txt" ]] || cmake -S "${REPO_DIR}" -B "${BUILD_DIR}"
  cmake --build "${BUILD_DIR}" -j "$(nproc)"
else
  echo "== Skipping build (-n): executable may not match current source"
fi
[[ -x "${EXE}" ]] || die "executable not found: ${EXE}"

# --- 3. Set up the run directory ---------------------------------------------
[[ -f "${namelist}" ]] || die "namelist not found: ${namelist}"
namelist_dir="$(cd "$(dirname "${namelist}")" && pwd)"
namelist_name="$(basename "${namelist}")"

run_dir="${runs_dir}/run_$(date +%Y%m%d_%H%M%S)"
mkdir -p "${run_dir}"
# copy the whole config directory, so relative paths in the namelist's IO
# section still work in the run directory
cp -r "${namelist_dir}/." "${run_dir}/"

{
  echo "date:           $(date -Iseconds)"
  echo "host:           $(hostname)"
  echo "box_model:      $(git -C "${REPO_DIR}" rev-parse HEAD)$( [[ -n "$(git -C "${REPO_DIR}" status --porcelain -- . ':!ukca')" ]] && echo ' (dirty)')"
  echo "ukca_tag:       ${ukca_tag}"
  echo "ukca_commit:    ${actual}"
  echo "executable:     ${EXE}"
  echo "exe_sha256:     $(sha256sum "${EXE}" | cut -d' ' -f1)"
  # the compiler CMake actually used, not whichever gfortran is first on PATH
  fc=$(sed -n 's/^CMAKE_Fortran_COMPILER:[A-Z]*=//p' "${BUILD_DIR}/CMakeCache.txt")
  echo "compiler:       ${fc} ($("${fc}" --version | head -1))"
  echo "debug_level:    ${debug_level}"
  echo "ukca_dump:      ${do_dump}"
  echo "config_dir:     ${namelist_dir}"
  echo "namelist:       ${namelist_name}"
  echo "inputs (copied from config_dir):"
  (cd "${run_dir}" && find . -type f ! -name provenance.txt -print0 | \
    sort -z | xargs -0 sha256sum | sed 's/^/  /')
} > "${run_dir}/provenance.txt"

# --- 4. Run ------------------------------------------------------------------
echo "== Running in ${run_dir}"
cd "${run_dir}"
if ${do_dump}; then
  export UKCA_DUMP_FILE="${run_dir}/ukca_dump.txt"
else
  unset UKCA_DUMP_FILE
fi
set +e
"${EXE}" "${namelist_name}" --debug "${debug_level}" 2>&1 | tee run.log
status=${PIPESTATUS[0]}
set -e

# UKCA's legacy ereport uses a bare STOP on fatal errors, which exits with
# status 0, so also treat a reported UKCA ERROR as a failure.
if [[ "${status}" -eq 0 ]] && grep -q "UKCA ERROR in" run.log; then
  echo "== UKCA ERROR reported (model exited 0):" >&2
  grep "UKCA ERROR in" run.log >&2
  status=1
fi

echo "== Finished with exit code ${status}"
echo "   run dir:    ${run_dir}"
echo "   log:        ${run_dir}/run.log"
# the model logs where it wrote the tracer output (the namelist's output_dir)
output=$(sed -n 's/^UKCA INFO: *Writing tracer output to file: //p' run.log | tail -1)
if [[ -n "${output}" && -f "${output}" ]]; then
  [[ "${output}" = /* ]] || output="${run_dir}/${output}"
  echo "   output:     ${output}"
fi
[[ -f ukca_dump.txt ]] && echo "   dump:       ${run_dir}/ukca_dump.txt"
exit "${status}"
