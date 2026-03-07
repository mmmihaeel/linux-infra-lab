# Troubleshooting

## 1) Apache container is unhealthy

Symptoms:
- `docker compose ps` shows `apache` as `unhealthy` or restarting.

Checks:
```bash
docker compose logs apache --tail 200
tail -n 200 logs/apache/error.log
curl -fsS http://localhost:8084/server-status?auto
```

Likely causes:
- Invalid Apache config syntax
- Upstream backend unavailable
- Log directory permission issue

Resolution:
1. Validate Compose and restart stack:
   ```bash
   docker compose config -q
   docker compose up -d --build apache
   ```
2. Confirm backend health:
   ```bash
   curl -fsS http://localhost:3006/health
   curl -fsS http://localhost:8000/health
   ```

## 2) Reverse proxy route fails but backend is healthy

Checks:
```bash
curl -i http://localhost:8084/node/health
curl -i http://localhost:8084/php/health
docker compose logs apache --tail 200
```

Focus areas:
- `apache/vhosts/default.conf` route definitions
- trailing slash behavior (`/node` vs `/node/`)
- upstream service names and ports (`node-demo:3006`, `php-demo:8000`)

## 3) Healthcheck script reports DB failures

Checks:
```bash
docker compose ps
docker compose logs postgres --tail 100
docker compose logs mysql --tail 100
```

Verify readiness directly:
```bash
docker compose exec -T postgres pg_isready -U app -d infra_lab
docker compose exec -T mysql mysqladmin ping -h 127.0.0.1 -uroot -proot --silent
```

Common causes:
- data service still initializing
- changed credentials in `.env` not matching running containers
- stale volumes after env changes

## 4) Backup script fails

Checks:
```bash
bash ./scripts/healthcheck.sh
bash ./scripts/backup-postgres.sh
bash ./scripts/backup-mysql.sh
```

If backup fails:
1. Confirm target container is running.
2. Confirm credentials in `.env`.
3. Inspect DB logs for permission/authentication errors.
4. Recreate environment if credentials changed:
   ```bash
   bash ./scripts/reset-env.sh --force
   bash ./scripts/bootstrap.sh
   ```

## 5) Restore script fails

Checks:
- File path and permissions
- File format (`.sql` or `.sql.gz`)
- DB container health

Commands:
```bash
ls -l backups/postgres
ls -l backups/mysql
bash ./scripts/restore-postgres.sh backups/postgres/<file>.sql
bash ./scripts/restore-mysql.sh backups/mysql/<file>.sql
```

## 6) Logs not being written

Checks:
```bash
ls -la logs/apache
ls -la logs/cron
bash ./scripts/log-summary.sh
```

Action:
- Run a request through Apache to generate traffic:
  ```bash
  curl -fsS http://localhost:8084/node/health
  ```
- Re-run `bash ./scripts/log-summary.sh`.

## 7) Full recovery

If multiple services are in a bad state:
```bash
bash ./scripts/reset-env.sh --force
cp .env.example .env
bash ./scripts/bootstrap.sh
bash ./scripts/smoke-test.sh
bash ./scripts/test-backup-restore.sh
```
