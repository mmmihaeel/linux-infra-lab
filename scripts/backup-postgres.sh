#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

main() {
  local timestamp
  local out_dir
  local out_file

  require_compose
  load_env

  out_dir="${ROOT_DIR}/backups/postgres"
  ensure_dirs "${out_dir}"

  timestamp="$(timestamp_utc)"
  out_file="${out_dir}/postgres_${POSTGRES_DB}_${timestamp}.sql"

  log_info "Creating PostgreSQL backup: ${out_file}"
  compose exec -T postgres \
    pg_dump \
    --clean \
    --if-exists \
    --no-owner \
    --no-privileges \
    -U "${POSTGRES_USER}" \
    "${POSTGRES_DB}" >"${out_file}"

  chmod 600 "${out_file}" 2>/dev/null || true

  find "${out_dir}" -type f -name '*.sql' -mtime "+${BACKUP_RETENTION_DAYS}" -delete
  log_info "PostgreSQL backup complete"
  printf '%s\n' "${out_file}"
}

main "$@"
