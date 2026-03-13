# Local Development

This repository is optimized for local iteration with production-style operating habits. The main loop is simple: bring the stack up, verify both direct and proxied health, inspect logs when behavior changes, and use reset or restore workflows when the local state stops being trustworthy.

## Prerequisites

- Docker Engine with the Compose plugin
- Bash
- `curl`
- Optional local `shellcheck` and `shfmt` if you do not want the lint script to use Docker images for those tools

## Quick Start

```bash
cp .env.example .env
bash ./scripts/bootstrap.sh
bash ./scripts/healthcheck.sh
bash ./scripts/smoke-test.sh
```

## Endpoint Reference

| Endpoint | Purpose |
| --- | --- |
| `http://localhost:8084/` | Apache-served landing page |
| `http://localhost:8084/node/health` | Node service through Apache |
| `http://localhost:8084/php/health` | PHP service through Apache |
| `http://localhost:8084/healthz` | Short Apache-level health alias |
| `http://localhost:8084/server-status?auto` | Apache runtime status |
| `http://localhost:3006/health` | Direct Node liveness |
| `http://localhost:3006/ready` | Direct Node dependency readiness |
| `http://localhost:8000/health` | Direct PHP liveness |
| `http://localhost:8000/ready` | Direct PHP dependency readiness |

## Command Map

| Task | Command |
| --- | --- |
| Bootstrap the lab | `bash ./scripts/bootstrap.sh` |
| Rebuild all services | `docker compose up -d --build` |
| Check health | `bash ./scripts/healthcheck.sh` |
| Run smoke checks | `bash ./scripts/smoke-test.sh` |
| Summarize logs | `bash ./scripts/log-summary.sh --since 30m --tail 100` |
| Back up both databases | `bash ./scripts/backup-postgres.sh` and `bash ./scripts/backup-mysql.sh` |
| Validate restoreability | `bash ./scripts/test-backup-restore.sh` |
| Reset the lab | `bash ./scripts/reset-env.sh --force` |
| Lint shell and Compose config | `bash ./scripts/lint.sh` |

## Iteration Notes

- Apache config and the static landing page are bind-mounted into the Apache container. After changing files under `apache/`, restarting or recreating `apache` is enough.
- Node and PHP demo service code is built into images. After changing files under `services/`, rebuild the relevant services with `docker compose up -d --build node-demo php-demo`.
- Database schema seeds live under `docker/mysql/init` and `docker/postgres/init`. Those seed files apply on fresh volume initialization, so a reset is usually required to replay them.

## Useful Compose Commands

```bash
docker compose config -q
docker compose ps
docker compose logs -f apache
docker compose logs -f node-demo
docker compose logs -f php-demo
docker compose down
```

## Generated Runtime State

Bootstrap creates local directories for:

- `backups/mysql`
- `backups/postgres`
- `logs/apache`
- `logs/cron`

Those directories are part of the working lab state and can be cleaned up through the provided scripts.

## Related Documents

- [Runbooks](runbooks.md)
- [Topology](topology.md)
- [Troubleshooting](troubleshooting.md)
