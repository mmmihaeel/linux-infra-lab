#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/log-summary.sh [--tail N] [--since WINDOW] [--service NAME]

Examples:
  ./scripts/log-summary.sh
  ./scripts/log-summary.sh --tail 100 --since 1h
  ./scripts/log-summary.sh --service apache
EOF
}

print_file_tail() {
  local label="$1"
  local file_path="$2"
  local tail_lines="$3"

  echo "== ${label} (${file_path}) =="
  if [[ -f "${file_path}" ]]; then
    tail -n "${tail_lines}" "${file_path}"
  else
    echo "No log file found."
  fi
  echo
}

main() {
  local tail_lines=40
  local since_window="15m"
  local service_filter=""
  local services=(apache node-demo php-demo mysql postgres redis)
  local service
  local output
  local line_count
  local error_count

  while (($# > 0)); do
    case "$1" in
    --tail)
      shift
      [[ $# -gt 0 ]] || die "--tail requires a numeric argument"
      tail_lines="$1"
      ;;
    --since)
      shift
      [[ $# -gt 0 ]] || die "--since requires an argument like 10m or 1h"
      since_window="$1"
      ;;
    --service)
      shift
      [[ $# -gt 0 ]] || die "--service requires a service name"
      service_filter="$1"
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

  require_compose

  if [[ -n "${service_filter}" ]]; then
    services=("${service_filter}")
  fi

  echo "Log summary timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "== Log storage usage =="
  du -sh "${ROOT_DIR}/logs" 2>/dev/null || true
  echo

  print_file_tail "Apache access" "${ROOT_DIR}/logs/apache/access.log" "${tail_lines}"
  print_file_tail "Apache error" "${ROOT_DIR}/logs/apache/error.log" "${tail_lines}"

  for service in "${services[@]}"; do
    echo "== docker compose logs: ${service} (since ${since_window}, tail ${tail_lines}) =="
    if output="$(compose logs --since "${since_window}" --tail "${tail_lines}" "${service}" 2>/dev/null)"; then
      if [[ -z "${output}" ]]; then
        echo "No container logs in selected range."
      else
        printf '%s\n' "${output}"
      fi
      line_count="$(printf '%s\n' "${output}" | grep -c '.*' || true)"
      error_count="$(printf '%s\n' "${output}" | grep -Eic 'error|exception|failed|panic' || true)"
      printf 'Summary: lines=%s suspicious=%s\n' "${line_count}" "${error_count}"
    else
      echo "Unable to read logs for service: ${service}"
    fi
    echo
  done
}

main "$@"
