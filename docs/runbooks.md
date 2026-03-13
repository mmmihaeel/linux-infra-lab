# Runbooks

This document is the operating playbook for the repository: bootstrap, verify, back up, restore, inspect, clean up, and reset. The commands here are intentionally close to the scripts that implement the behavior.

## Runbook Index

| Objective | Primary command | Use it when... |
| --- | --- | --- |
| Bootstrap the stack | `bash ./scripts/bootstrap.sh` | Bringing up the lab from a fresh checkout or after a reset |
| Check current health | `bash ./scripts/healthcheck.sh` | You want a single summary of edge, app, and data-service status |
| Prove route wiring | `bash ./scripts/smoke-test.sh` | You changed routing, app behavior, or startup order |
| Create backups | `bash ./scripts/backup-postgres.sh` and `bash ./scripts/backup-mysql.sh` | You want fresh SQL dumps before a change or drill |
| Prove restoreability | `bash ./scripts/test-backup-restore.sh` | You need evidence that backups can recreate known data |
| Summarize logs | `bash ./scripts/log-summary.sh --since 30m --tail 80` | You are triaging recent behavior |
| Clean up logs | `bash ./scripts/log-cleanup.sh --days 14` | Local log files are no longer useful |
| Reset the lab | `bash ./scripts/reset-env.sh --force` | You want a clean baseline |

## Bootstrap and First Verification

```bash
cp .env.example .env
bash ./scripts/bootstrap.sh
bash ./scripts/healthcheck.sh
bash ./scripts/smoke-test.sh
```

What bootstrap does:

- Creates `.env` from `.env.example` if the file is missing.
- Ensures `backups/` and `logs/` directories exist.
- Starts the Compose stack, optionally rebuilding images.
- Waits for proxied Node and PHP health endpoints before reporting success.

Useful flags:

- `--no-build` starts services without rebuilding images.
- `--skip-wait` skips the proxied endpoint readiness wait.

## Daily Operator Checks

| Goal | Command | Expected signal |
| --- | --- | --- |
| Confirm containers are up | `docker compose ps` | All services show `running` or `healthy` states |
| See consolidated health | `bash ./scripts/healthcheck.sh` | PASS output for direct, proxied, and data-service checks |
| Review recent logs | `bash ./scripts/log-summary.sh --since 15m --tail 60` | Apache file logs plus recent container log snapshots |
| Inspect Apache internals | `curl -fsS http://localhost:8084/server-status?auto` | A current `mod_status` response |

## Backup and Restore Drill

The restore drill is the most important runbook in the repository because it proves that the backups are operational, not ceremonial.

```mermaid
flowchart LR
    Seed["Seeded DB tables"] --> Insert["Insert sentinel rows"]
    Insert --> Backup["Create SQL backups"]
    Backup --> Remove["Delete sentinel rows"]
    Remove --> Restore["Restore SQL backups"]
    Restore --> Verify["Verify sentinel rows returned"]
```

### Create backups

```bash
bash ./scripts/backup-postgres.sh
bash ./scripts/backup-mysql.sh
```

### Restore specific artifacts

```bash
bash ./scripts/restore-postgres.sh backups/postgres/<backup>.sql
bash ./scripts/restore-mysql.sh backups/mysql/<backup>.sql
```

### Validate the full round-trip

```bash
bash ./scripts/test-backup-restore.sh
```

What the validation script proves:

- PostgreSQL backups contain the `service_events` table state, including the inserted sentinel row.
- MySQL backups contain the `maintenance_runs` table state, including the inserted sentinel row.
- Restoring those artifacts recreates the sentinel rows after they have been deleted.

## Log Inspection and Cleanup

Summarize recent logs:

```bash
bash ./scripts/log-summary.sh --since 30m --tail 100
```

Filter to one service:

```bash
bash ./scripts/log-summary.sh --service apache --since 30m --tail 100
```

Clean up old log files:

```bash
bash ./scripts/log-cleanup.sh --days 14
```

The script reads Apache access and error logs from `logs/apache` and combines that view with recent `docker compose logs` output for `apache`, `node-demo`, `php-demo`, `mysql`, `postgres`, and `redis`.

## Reset and Rebuild

Full reset:

```bash
bash ./scripts/reset-env.sh --force
```

Preserve `.env` during reset:

```bash
bash ./scripts/reset-env.sh --force --preserve-env
```

Preserve backups during reset:

```bash
bash ./scripts/reset-env.sh --force --keep-backups
```

Recommended rebuild sequence after a reset:

```bash
bash ./scripts/bootstrap.sh
bash ./scripts/healthcheck.sh
bash ./scripts/smoke-test.sh
```

## Scheduled Maintenance

Example cron entries live in `scripts/cron/maintenance.cron`.

They currently cover:

- health snapshots every 15 minutes
- nightly PostgreSQL and MySQL backups
- weekly log cleanup

Before installing the cron file on a Linux host:

1. Set `REPO_ROOT` to the deployed repository path.
2. Confirm the cron user can run Docker commands.
3. Confirm the cron user can write `logs/cron`.

## Related Documents

- [Architecture](architecture.md)
- [Troubleshooting](troubleshooting.md)
- [Local Development](local-development.md)
- [Deployment Notes](deployment-notes.md)
