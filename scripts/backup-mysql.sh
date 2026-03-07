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

  out_dir="${ROOT_DIR}/backups/mysql"
  ensure_dirs "${out_dir}"

  timestamp="$(timestamp_utc)"
  out_file="${out_dir}/mysql_${MYSQL_DATABASE}_${timestamp}.sql"

  log_info "Creating MySQL backup: ${out_file}"
  compose exec -T mysql \
    env MYSQL_PWD="${MYSQL_PASSWORD}" \
    mysqldump \
    --single-transaction \
    --quick \
    --routines \
    --triggers \
    --no-tablespaces \
    --set-gtid-purged=OFF \
    -u"${MYSQL_USER}" \
    "${MYSQL_DATABASE}" >"${out_file}"

  chmod 600 "${out_file}" 2>/dev/null || true

  find "${out_dir}" -type f -name '*.sql' -mtime "+${BACKUP_RETENTION_DAYS}" -delete
  log_info "MySQL backup complete"
  printf '%s\n' "${out_file}"
}

main "$@"
