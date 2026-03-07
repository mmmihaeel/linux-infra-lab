#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/log-cleanup.sh [--days N]
EOF
}

main() {
  local retention_days=""
  local target
  local removed=0
  local file
  local targets=("${ROOT_DIR}/logs/apache" "${ROOT_DIR}/logs/cron")

  load_env
  retention_days="${LOG_RETENTION_DAYS}"

  while (($# > 0)); do
    case "$1" in
    --days)
      shift
      [[ $# -gt 0 ]] || die "--days requires a numeric value"
      retention_days="$1"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage
      die "Unknown argument: $1"
      ;;
    esac
    shift
  done

  log_info "Removing *.log files older than ${retention_days} day(s)"

  for target in "${targets[@]}"; do
    [[ -d "${target}" ]] || continue
    while IFS= read -r file; do
      rm -f "${file}"
      removed=$((removed + 1))
      printf 'Removed %s\n' "${file}"
    done < <(find "${target}" -type f -name '*.log' -mtime "+${retention_days}")
  done

  log_info "Log cleanup complete. Files removed: ${removed}"
}

main "$@"
