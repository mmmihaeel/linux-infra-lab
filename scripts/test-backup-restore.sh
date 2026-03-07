#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

main() {
  local sentinel
  local pg_backup
  local mysql_backup
  local pg_count
  local mysql_count

  require_compose
  load_env

  sentinel="restore_test_$(date +%s)"
  log_info "Running backup/restore validation with sentinel: ${sentinel}"

  compose exec -T postgres \
    psql --set ON_ERROR_STOP=1 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
    -c "INSERT INTO service_events (service_name, event_type, details) VALUES ('backup-validation', '${sentinel}', '{\"origin\":\"test-backup-restore\"}'::jsonb);"

  bash "${SCRIPT_DIR}/backup-postgres.sh" >/dev/null
  pg_backup="$(find "${ROOT_DIR}/backups/postgres" -maxdepth 1 -type f -name 'postgres_*.sql' | sort | tail -n 1)"
  [[ -n "${pg_backup}" ]] || die "PostgreSQL backup file was not created"

  compose exec -T postgres \
    psql --set ON_ERROR_STOP=1 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
    -c "DELETE FROM service_events WHERE event_type='${sentinel}';"

  pg_count="$(compose exec -T postgres psql -tA -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT COUNT(*) FROM service_events WHERE event_type='${sentinel}';" | tr -d '[:space:]')"
  [[ "${pg_count}" == "0" ]] || die "PostgreSQL sentinel row was not removed before restore"

  bash "${SCRIPT_DIR}/restore-postgres.sh" "${pg_backup}" >/dev/null
  pg_count="$(compose exec -T postgres psql -tA -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT COUNT(*) FROM service_events WHERE event_type='${sentinel}';" | tr -d '[:space:]')"
  [[ "${pg_count}" -ge 1 ]] || die "PostgreSQL sentinel row was not restored"
  log_info "PostgreSQL backup/restore validation passed"

  compose exec -T mysql \
    env MYSQL_PWD="${MYSQL_PASSWORD}" \
    mysql -N -B -u"${MYSQL_USER}" "${MYSQL_DATABASE}" \
    -e "INSERT INTO maintenance_runs (task_name, status, details) VALUES ('backup-validation', '${sentinel}', JSON_OBJECT('origin', 'test-backup-restore'));"

  bash "${SCRIPT_DIR}/backup-mysql.sh" >/dev/null
  mysql_backup="$(find "${ROOT_DIR}/backups/mysql" -maxdepth 1 -type f -name 'mysql_*.sql' | sort | tail -n 1)"
  [[ -n "${mysql_backup}" ]] || die "MySQL backup file was not created"

  compose exec -T mysql \
    env MYSQL_PWD="${MYSQL_PASSWORD}" \
    mysql -N -B -u"${MYSQL_USER}" "${MYSQL_DATABASE}" \
    -e "DELETE FROM maintenance_runs WHERE status='${sentinel}';"

  mysql_count="$(compose exec -T mysql env MYSQL_PWD="${MYSQL_PASSWORD}" mysql -N -B -u"${MYSQL_USER}" "${MYSQL_DATABASE}" -e "SELECT COUNT(*) FROM maintenance_runs WHERE status='${sentinel}';" | tr -d '[:space:]')"
  [[ "${mysql_count}" == "0" ]] || die "MySQL sentinel row was not removed before restore"

  bash "${SCRIPT_DIR}/restore-mysql.sh" "${mysql_backup}" >/dev/null
  mysql_count="$(compose exec -T mysql env MYSQL_PWD="${MYSQL_PASSWORD}" mysql -N -B -u"${MYSQL_USER}" "${MYSQL_DATABASE}" -e "SELECT COUNT(*) FROM maintenance_runs WHERE status='${sentinel}';" | tr -d '[:space:]')"
  [[ "${mysql_count}" -ge 1 ]] || die "MySQL sentinel row was not restored"
  log_info "MySQL backup/restore validation passed"
}

main "$@"
