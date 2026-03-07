#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

FAILURES=0

check_http() {
  local label="$1"
  local url="$2"
  local body

  if body="$(curl -fsS --max-time "${HEALTHCHECK_TIMEOUT}" "${url}")"; then
    printf '[PASS] %s (%s)\n' "${label}" "${url}"
    printf '       %s\n' "${body}"
  else
    printf '[FAIL] %s (%s)\n' "${label}" "${url}" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

main() {
  require_compose
  require_command curl
  load_env

  printf 'Healthcheck timestamp: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "== Docker compose status =="
  compose ps

  echo
  echo "== HTTP checks =="
  check_http "Node direct health" "http://localhost:${NODE_PORT}/health"
  check_http "PHP direct health" "http://localhost:${PHP_PORT}/health"
  check_http "Node via Apache" "http://localhost:${APACHE_PORT}/node/health"
  check_http "PHP via Apache" "http://localhost:${APACHE_PORT}/php/health"
  check_http "Apache server-status" "http://localhost:${APACHE_PORT}/server-status?auto"

  echo
  echo "== Data service checks =="
  if compose exec -T postgres pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" >/dev/null 2>&1; then
    echo "[PASS] PostgreSQL is ready"
  else
    echo "[FAIL] PostgreSQL readiness check failed" >&2
    FAILURES=$((FAILURES + 1))
  fi

  if compose exec -T mysql mysqladmin ping -h 127.0.0.1 -uroot -p"${MYSQL_ROOT_PASSWORD}" --silent >/dev/null 2>&1; then
    echo "[PASS] MySQL is ready"
  else
    echo "[FAIL] MySQL readiness check failed" >&2
    FAILURES=$((FAILURES + 1))
  fi

  if [[ "$(compose exec -T redis redis-cli ping 2>/dev/null | tr -d '\r')" == "PONG" ]]; then
    echo "[PASS] Redis is ready"
  else
    echo "[FAIL] Redis readiness check failed" >&2
    FAILURES=$((FAILURES + 1))
  fi

  echo
  if ((FAILURES > 0)); then
    log_error "Healthcheck completed with ${FAILURES} failure(s)"
    exit 1
  fi

  log_info "All health checks passed"
}

main "$@"
