#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
PROJECT_NAME="linux-infra-lab"

log_info() {
  printf '[INFO] %s\n' "$*"
}

log_warn() {
  printf '[WARN] %s\n' "$*" >&2
}

log_error() {
  printf '[ERROR] %s\n' "$*" >&2
}

die() {
  log_error "$*"
  exit 1
}

require_command() {
  local cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || die "Required command not found: ${cmd}"
}

require_compose() {
  require_command docker
  docker compose version >/dev/null 2>&1 || die "Docker Compose plugin is required."
}

load_env() {
  if [[ -f "${ENV_FILE}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${ENV_FILE}"
    set +a
  fi

  : "${APACHE_PORT:=8084}"
  : "${NODE_PORT:=3006}"
  : "${PHP_PORT:=8000}"
  : "${MYSQL_PORT:=3307}"
  : "${POSTGRES_PORT:=5438}"
  : "${REDIS_PORT:=6385}"
  : "${MYSQL_DATABASE:=infra_lab}"
  : "${MYSQL_USER:=app}"
  : "${MYSQL_PASSWORD:=app}"
  : "${MYSQL_ROOT_PASSWORD:=root}"
  : "${POSTGRES_DB:=infra_lab}"
  : "${POSTGRES_USER:=app}"
  : "${POSTGRES_PASSWORD:=app}"
  : "${BACKUP_RETENTION_DAYS:=14}"
  : "${LOG_RETENTION_DAYS:=7}"
  : "${HEALTHCHECK_TIMEOUT:=5}"
}

compose() {
  if [[ -f "${ENV_FILE}" ]]; then
    docker compose \
      --project-name "${PROJECT_NAME}" \
      --project-directory "${ROOT_DIR}" \
      --env-file "${ENV_FILE}" \
      "$@"
  else
    docker compose \
      --project-name "${PROJECT_NAME}" \
      --project-directory "${ROOT_DIR}" \
      "$@"
  fi
}

ensure_dirs() {
  local path
  for path in "$@"; do
    mkdir -p "${path}"
  done
}

timestamp_utc() {
  date -u +%Y%m%dT%H%M%SZ
}
