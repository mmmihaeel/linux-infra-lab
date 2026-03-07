# Local Development

## Prerequisites

- Docker Engine with Compose plugin
- Bash and curl
- Optional: shellcheck and shfmt (or run `bash ./scripts/lint.sh` with Docker fallback)

## First-time setup

```bash
cp .env.example .env
bash ./scripts/bootstrap.sh
```

## Service endpoints (defaults)

- Apache gateway: `http://localhost:8084`
- Node direct: `http://localhost:3006`
- PHP direct: `http://localhost:8000`
- MySQL: `localhost:3307`
- PostgreSQL: `localhost:5438`
- Redis: `localhost:6385`

## High-value commands

```bash
bash ./scripts/healthcheck.sh
bash ./scripts/smoke-test.sh
bash ./scripts/log-summary.sh --since 30m --tail 100
bash ./scripts/backup-postgres.sh
bash ./scripts/backup-mysql.sh
bash ./scripts/test-backup-restore.sh
bash ./scripts/reset-env.sh --force
```

## Compose operations

```bash
docker compose config -q
docker compose ps
docker compose logs -f apache
docker compose up -d --build
docker compose down -v
```

## Keeping local state clean

- Remove stale logs:
  ```bash
  bash ./scripts/log-cleanup.sh --days 7
  ```
- Reset full environment:
  ```bash
  bash ./scripts/reset-env.sh --force
  ```
