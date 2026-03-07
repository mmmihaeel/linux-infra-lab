# linux-infra-lab

`linux-infra-lab` is a practical infrastructure and service-operations lab focused on Linux-oriented operator workflows.  
It demonstrates Apache reverse proxying, Docker Compose orchestration, defensive Bash automation, health checks, database backup/restore operations, log diagnostics, and incident runbooks.

## Why this project exists

This repository is built as an operations-first portfolio project: the core value is not framework complexity, but the quality of infrastructure workflows and operational discipline.

## Feature highlights

- Apache reverse proxy with clear routing to two backend services
- Docker Compose orchestration for Apache, Node.js, PHP, MySQL, PostgreSQL, and Redis
- Health endpoints and operator-facing health summary script
- Timestamped PostgreSQL and MySQL backup scripts
- Argument-validated restore workflows for PostgreSQL and MySQL
- Log inspection and cleanup workflows
- Safe environment reset/rebuild workflow
- Cron maintenance examples for recurring checks and backups
- CI checks for shell quality, Compose validation, and runtime smoke tests

## Stack

- Linux
- Bash
- Apache HTTP Server
- Docker / Docker Compose
- Node.js
- PHP
- MySQL
- PostgreSQL
- Redis
- GitHub Actions

## Architecture summary

Client traffic enters Apache (`:8084` by default). Apache reverse proxies requests to:

- `node-demo` for `/node/*`
- `php-demo` for `/php/*`

Data services:

- PostgreSQL for SQL backup/restore workflows and readiness dependencies
- MySQL for SQL backup/restore workflows and readiness dependencies
- Redis for dependency checks in application readiness endpoints

## Reverse proxy routing

- `/node/health` -> Node service health
- `/node/ready` -> Node dependency readiness
- `/php/health` -> PHP service health
- `/php/ready` -> PHP dependency readiness
- `/healthz` -> Node health alias
- `/server-status?auto` -> Apache runtime status

## Quick start

### Prerequisites

- Docker Engine 24+
- Docker Compose plugin (`docker compose`)
- Bash
- curl

### Bootstrap

```bash
cp .env.example .env
bash ./scripts/bootstrap.sh
```

### Verify

```bash
bash ./scripts/healthcheck.sh
bash ./scripts/smoke-test.sh
```

## Operational workflows

### Daily health and diagnostics

```bash
bash ./scripts/healthcheck.sh
bash ./scripts/log-summary.sh --since 30m --tail 80
```

### Backup and restore

```bash
bash ./scripts/backup-postgres.sh
bash ./scripts/backup-mysql.sh

bash ./scripts/restore-postgres.sh backups/postgres/<file>.sql
bash ./scripts/restore-mysql.sh backups/mysql/<file>.sql
```

### Validate backup/restore correctness

```bash
bash ./scripts/test-backup-restore.sh
```

### Reset local lab state

```bash
bash ./scripts/reset-env.sh --force
```

## Validation and quality checks

```bash
bash ./scripts/lint.sh
docker compose config -q
bash ./scripts/smoke-test.sh
bash ./scripts/test-backup-restore.sh
```

## Repository structure

```text
apache/                  Apache base config and virtual hosts
backups/                 Generated SQL backups (gitkept directories)
docker/                  Database initialization SQL
docs/                    Architecture, runbooks, troubleshooting, security notes
logs/                    Apache and cron log directories
scripts/                 Operator automation scripts
services/node-demo/      Node backend service
services/php-demo/       PHP backend service
.github/workflows/       CI checks
docker-compose.yml       Full local lab topology
```

## Security notes

- Credentials in `.env` are for local lab use only.
- Backups may contain sensitive data and should be handled as secrets.
- Apache `/server-status` is intentionally exposed for local diagnostics; restrict it in public environments.
- Services run on an isolated Docker bridge network by default.

## Documentation index

- [Architecture](docs/architecture.md)
- [Topology](docs/topology.md)
- [Runbooks](docs/runbooks.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Security](docs/security.md)
- [Local development](docs/local-development.md)
- [Deployment notes](docs/deployment-notes.md)
- [Roadmap](docs/roadmap.md)

## Future improvements

- TLS termination and certificate automation
- Centralized log shipping and retention policies
- Remote backup targets with encryption
- Runtime metrics and alerting integration
