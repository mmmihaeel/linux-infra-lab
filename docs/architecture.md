# Architecture

`linux-infra-lab` is designed around operator workflows first: every component exists to support setup, verification, diagnosis, backup/restore, and recovery operations.

## Core services

- `apache` (httpd:2.4-alpine): edge entrypoint and reverse proxy
- `node-demo`: lightweight backend with health/readiness probes
- `php-demo`: lightweight backend with health/readiness probes
- `postgres`: relational store used in backup/restore workflows
- `mysql`: relational store used in backup/restore workflows
- `redis`: dependency target for readiness checks

## Design objectives

1. Keep local setup reproducible and deterministic.
2. Demonstrate realistic ops scripts with strict Bash practices.
3. Include health checks at both service and platform levels.
4. Keep troubleshooting practical by exposing meaningful logs and runbooks.
5. Ensure all key workflows can be validated in CI.

## Service interactions

- Apache proxies `/node/*` to `node-demo`.
- Apache proxies `/php/*` to `php-demo`.
- `node-demo` readiness depends on TCP reachability to PostgreSQL and Redis.
- `php-demo` readiness depends on TCP reachability to MySQL and Redis.
- Database init SQL seeds baseline tables used by validation workflows.

## Reliability decisions

- Compose `depends_on` with `service_healthy` ensures stable startup order.
- Container-level `healthcheck` is configured for every service.
- Bash scripts fail fast (`set -euo pipefail`) and validate inputs.
- Backup scripts emit timestamped artifacts and enforce retention cleanup.

## Scope boundaries

- The current setup is designed for local infrastructure workflows and controlled lab environments.
- TLS termination and centralized secret management are intentionally outside the scope of this iteration.
- Backup retention is currently implemented as a local filesystem policy, with remote archival left as a future extension.
- Apache server-status is enabled for local diagnostics and should be restricted in public environments.
