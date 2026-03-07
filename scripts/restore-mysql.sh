#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/restore-mysql.sh <backup.sql|backup.sql.gz>
EOF
}

main() {
  local backup_file="${1:-}"

  require_compose
  load_env

  if [[ -z "${backup_file}" ]]; then
    usage
    die "Backup file argument is required"
  fi

  if [[ ! -r "${backup_file}" ]]; then
    die "Backup file not found or unreadable: ${backup_file}"
  fi

  log_info "Restoring MySQL database ${MYSQL_DATABASE} from ${backup_file}"

  if [[ "${backup_file}" == *.gz ]]; then
    require_command gzip
    gzip -dc "${backup_file}" | compose exec -T mysql \
      env MYSQL_PWD="${MYSQL_PASSWORD}" \
      mysql --binary-mode=1 -u"${MYSQL_USER}" "${MYSQL_DATABASE}"
  else
    compose exec -T mysql \
      env MYSQL_PWD="${MYSQL_PASSWORD}" \
      mysql --binary-mode=1 -u"${MYSQL_USER}" "${MYSQL_DATABASE}" <"${backup_file}"
  fi

  log_info "MySQL restore completed"
}

main "$@"
