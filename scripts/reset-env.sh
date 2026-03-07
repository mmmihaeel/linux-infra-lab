#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/reset-env.sh [--force] [--keep-backups] [--preserve-env]
EOF
}

main() {
  local force="false"
  local keep_backups="false"
  local preserve_env="false"
  local confirm

  while (($# > 0)); do
    case "$1" in
    --force)
      force="true"
      ;;
    --keep-backups)
      keep_backups="true"
      ;;
    --preserve-env)
      preserve_env="true"
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

  if [[ "${force}" == "false" ]]; then
    read -r -p "This will remove containers, volumes, and generated runtime files. Continue? [y/N] " confirm
    if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
      log_info "Reset aborted"
      exit 0
    fi
  fi

  log_info "Stopping and removing docker compose services and volumes"
  compose down -v --remove-orphans

  find "${ROOT_DIR}/logs" -type f -name '*.log' -delete

  if [[ "${keep_backups}" == "false" ]]; then
    find "${ROOT_DIR}/backups" -type f \( -name '*.sql' -o -name '*.sql.gz' \) -delete
  fi

  if [[ "${preserve_env}" == "false" ]]; then
    rm -f "${ENV_FILE}"
  fi

  log_info "Environment reset complete"
}

main "$@"
