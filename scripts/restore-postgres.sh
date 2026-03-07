#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/restore-postgres.sh <backup.sql|backup.sql.gz>
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

  log_info "Restoring PostgreSQL database ${POSTGRES_DB} from ${backup_file}"

  if [[ "${backup_file}" == *.gz ]]; then
    require_command gzip
    gzip -dc "${backup_file}" | compose exec -T postgres \
      psql --set ON_ERROR_STOP=1 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"
  else
    compose exec -T postgres \
      psql --set ON_ERROR_STOP=1 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" <"${backup_file}"
  fi

  log_info "PostgreSQL restore completed"
}

main "$@"
