#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

FAILURES=0

assert_http_contains() {
  local label="$1"
  local url="$2"
  local token="$3"
  local body

  if body="$(curl -fsS --max-time "${HEALTHCHECK_TIMEOUT}" "${url}")"; then
    if grep -q "${token}" <<<"${body}"; then
      printf '[PASS] %s (%s)\n' "${label}" "${url}"
    else
      printf '[FAIL] %s token not found: %s\n' "${label}" "${token}" >&2
      printf '       body: %s\n' "${body}" >&2
      FAILURES=$((FAILURES + 1))
    fi
  else
    printf '[FAIL] %s request failed (%s)\n' "${label}" "${url}" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

main() {
  require_compose
  require_command curl
  load_env

  compose config -q

  assert_http_contains "Node direct /health" "http://localhost:${NODE_PORT}/health" '"service":"node-demo"'
  assert_http_contains "PHP direct /health" "http://localhost:${PHP_PORT}/health" '"service":"php-demo"'
  assert_http_contains "Node proxied /node/health" "http://localhost:${APACHE_PORT}/node/health" '"service":"node-demo"'
  assert_http_contains "PHP proxied /php/health" "http://localhost:${APACHE_PORT}/php/health" '"service":"php-demo"'
  assert_http_contains "Apache /healthz alias" "http://localhost:${APACHE_PORT}/healthz" '"service":"node-demo"'
  assert_http_contains "Apache /server-status" "http://localhost:${APACHE_PORT}/server-status?auto" 'ServerVersion'

  if compose exec -T postgres pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" >/dev/null 2>&1; then
    echo "[PASS] PostgreSQL responds to pg_isready"
  else
    echo "[FAIL] PostgreSQL pg_isready check failed" >&2
    FAILURES=$((FAILURES + 1))
  fi

  if compose exec -T mysql mysqladmin ping -h 127.0.0.1 -uroot -p"${MYSQL_ROOT_PASSWORD}" --silent >/dev/null 2>&1; then
    echo "[PASS] MySQL responds to mysqladmin ping"
  else
    echo "[FAIL] MySQL mysqladmin ping check failed" >&2
    FAILURES=$((FAILURES + 1))
  fi

  if [[ "$(compose exec -T redis redis-cli ping 2>/dev/null | tr -d '\r')" == "PONG" ]]; then
    echo "[PASS] Redis responds to PING"
  else
    echo "[FAIL] Redis PING check failed" >&2
    FAILURES=$((FAILURES + 1))
  fi

  if ((FAILURES > 0)); then
    log_error "Smoke tests failed: ${FAILURES} checks"
    exit 1
  fi

  log_info "Smoke tests passed"
}

main "$@"
