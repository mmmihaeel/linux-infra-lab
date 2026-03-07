#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/bootstrap.sh [--no-build] [--skip-wait]

Options:
  --no-build   Start services without rebuilding images
  --skip-wait  Skip endpoint readiness checks
  -h, --help   Show help
EOF
}

wait_for_url() {
  local name="$1"
  local url="$2"
  local timeout_seconds="$3"
  local elapsed=0

  until curl -fsS --max-time "${HEALTHCHECK_TIMEOUT}" "${url}" >/dev/null; do
    sleep 2
    elapsed=$((elapsed + 2))
    if ((elapsed >= timeout_seconds)); then
      die "${name} did not become ready within ${timeout_seconds}s (${url})"
    fi
  done

  log_info "${name} is ready"
}

main() {
  local no_build="false"
  local skip_wait="false"
  local up_flags=(-d --remove-orphans)

  while (($# > 0)); do
    case "$1" in
    --no-build)
      no_build="true"
      shift
      ;;
    --skip-wait)
      skip_wait="true"
      shift
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
  done

  require_compose
  require_command curl

  if [[ ! -f "${ENV_FILE}" ]]; then
    cp "${ROOT_DIR}/.env.example" "${ENV_FILE}"
    log_info "Created .env from .env.example"
  fi

  load_env

  ensure_dirs \
    "${ROOT_DIR}/backups/mysql" \
    "${ROOT_DIR}/backups/postgres" \
    "${ROOT_DIR}/logs/apache" \
    "${ROOT_DIR}/logs/cron"

  touch "${ROOT_DIR}/logs/cron/healthcheck.log" "${ROOT_DIR}/logs/cron/maintenance.log"

  if [[ "${no_build}" == "false" ]]; then
    up_flags+=(--build)
  fi

  log_info "Starting docker compose services"
  compose up "${up_flags[@]}"

  if [[ "${skip_wait}" == "false" ]]; then
    wait_for_url "Apache -> Node health" "http://localhost:${APACHE_PORT}/node/health" 90
    wait_for_url "Apache -> PHP health" "http://localhost:${APACHE_PORT}/php/health" 90
  fi

  log_info "Bootstrap complete"
  printf 'Apache gateway: http://localhost:%s\n' "${APACHE_PORT}"
  printf 'Node direct:    http://localhost:%s/health\n' "${NODE_PORT}"
  printf 'PHP direct:     http://localhost:%s/health\n' "${PHP_PORT}"
}

main "$@"
