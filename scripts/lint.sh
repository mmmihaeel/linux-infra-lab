#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

run_shellcheck() {
  local -a files=("$@")

  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "${files[@]}"
    return
  fi

  require_command docker
  docker run --rm \
    -v "${ROOT_DIR}:/work" \
    -w /work \
    koalaman/shellcheck:stable \
    "${files[@]}"
}

run_shfmt() {
  local -a files=("$@")

  if command -v shfmt >/dev/null 2>&1; then
    shfmt -d "${files[@]}"
    return
  fi

  require_command docker
  docker run --rm \
    -v "${ROOT_DIR}:/work" \
    -w /work \
    mvdan/shfmt:v3.8.0 \
    -d "${files[@]}"
}

main() {
  local -a shell_files

  cd "${ROOT_DIR}"
  mapfile -t shell_files < <(find scripts -type f -name '*.sh' | sort)
  [[ "${#shell_files[@]}" -gt 0 ]] || die "No shell files found under scripts/"

  log_info "Running shellcheck"
  run_shellcheck "${shell_files[@]}"

  log_info "Running shfmt diff check"
  run_shfmt "${shell_files[@]}"

  require_compose
  log_info "Validating docker compose configuration"
  compose config -q

  log_info "Lint checks passed"
}

main "$@"
