# Runbooks

## Bootstrap and first verification

1. Copy environment file:
   ```bash
   cp .env.example .env
   ```
2. Start stack:
   ```bash
   bash ./scripts/bootstrap.sh
   ```
3. Verify runtime:
   ```bash
   bash ./scripts/healthcheck.sh
   bash ./scripts/smoke-test.sh
   ```

## Daily operator check

```bash
bash ./scripts/healthcheck.sh
bash ./scripts/log-summary.sh --since 15m --tail 60
docker compose ps
```

## Database backup runbook

1. PostgreSQL backup:
   ```bash
   bash ./scripts/backup-postgres.sh
   ```
2. MySQL backup:
   ```bash
   bash ./scripts/backup-mysql.sh
   ```
3. Validate artifact presence:
   ```bash
   ls -1 backups/postgres
   ls -1 backups/mysql
   ```

## Database restore runbook

1. Restore PostgreSQL:
   ```bash
   bash ./scripts/restore-postgres.sh backups/postgres/<backup>.sql
   ```
2. Restore MySQL:
   ```bash
   bash ./scripts/restore-mysql.sh backups/mysql/<backup>.sql
   ```
3. Post-restore verification:
   ```bash
   bash ./scripts/healthcheck.sh
   ```

## Backup/restore validation runbook

Use this to verify both backup and restore workflows against seeded tables.

```bash
bash ./scripts/test-backup-restore.sh
```

## Incident triage runbook

1. Confirm container state:
   ```bash
   docker compose ps
   ```
2. Inspect recent logs:
   ```bash
   bash ./scripts/log-summary.sh --since 30m --tail 100
   ```
3. Check Apache routing endpoints:
   ```bash
   curl -fsS http://localhost:8084/node/health
   curl -fsS http://localhost:8084/php/health
   curl -fsS http://localhost:8084/server-status?auto
   ```
4. Check backend direct endpoints:
   ```bash
   curl -fsS http://localhost:3006/ready
   curl -fsS http://localhost:8000/ready
   ```

## Reset and rebuild runbook

```bash
bash ./scripts/reset-env.sh --force
cp .env.example .env
bash ./scripts/bootstrap.sh
bash ./scripts/smoke-test.sh
```

## Cron maintenance runbook

- Cron examples are in `scripts/cron/maintenance.cron`.
- Set `REPO_ROOT` to the deployed path before installing cron entries.
- Cron jobs cover periodic health checks, nightly backups, and weekly log cleanup.
