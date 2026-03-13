# Security

This repository is a local-first infrastructure lab, not a hardened internet-facing deployment. The security value is in the discipline of the defaults, the clarity of the boundaries, and the fact that sensitive workflows such as backups and restore drills are treated explicitly.

## Current Security Posture

- Services are isolated on a dedicated Docker bridge network.
- Apache exposes only the routes needed for the lab.
- Application containers run as non-root users.
- Bash scripts use strict mode and validate inputs before destructive actions.
- Backup files are permission-restricted where the host allows it.

## Controls Present in the Implementation

| Control | Where it exists | Why it matters |
| --- | --- | --- |
| Bridge-network isolation | `docker-compose.yml` | Keeps service-to-service traffic inside a dedicated local network |
| Read-only mounts for Apache config | `docker-compose.yml` | Reduces accidental in-container config drift |
| Defensive Apache headers | `apache/vhosts/default.conf` | Adds baseline response hardening for proxied traffic |
| Non-root app containers | `services/node-demo/Dockerfile`, `services/php-demo/Dockerfile` | Avoids running demo services as root |
| Strict Bash mode | `scripts/*.sh` | Prevents common shell scripting failure modes |
| Backup file permission attempt | `backup-postgres.sh`, `backup-mysql.sh` | Tries to apply `chmod 600` to generated SQL dumps |
| Explicit reset confirmation | `scripts/reset-env.sh` | Reduces accidental destructive cleanup when `--force` is omitted |

## Sensitive Artifacts

| Artifact | Why it is sensitive | Handling expectation |
| --- | --- | --- |
| `.env` | Contains local database credentials and port settings | Keep local and do not commit it |
| `backups/postgres/*.sql` | Can contain full PostgreSQL data | Treat as sensitive operational data |
| `backups/mysql/*.sql` | Can contain full MySQL data | Treat as sensitive operational data |
| `logs/apache/*` and `logs/cron/*` | May include request metadata and operational context | Retain only as long as needed |

## Safe Operating Practices

- Never treat the lab credentials as reusable beyond this repository.
- Clean up old logs and backups on a schedule that fits the host.
- Restrict or disable `/server-status` before exposing Apache beyond a local environment.
- Reset the environment after large credential or schema changes instead of layering uncertain state on top of old volumes.
- Assume any SQL dump should be stored and transferred like a secret.

## Hardening Priorities Before Any Shared Environment

| Priority | Recommendation |
| --- | --- |
| Secrets | Replace local `.env` handling with a secret-management workflow |
| Transport | Add TLS termination and redirect plain HTTP to HTTPS |
| Exposure | Restrict inbound access to database ports and Apache status endpoints |
| Auditability | Ship logs to a central destination with retention controls |
| Image and dependency hygiene | Add vulnerability scanning for images and dependency surfaces |

## Security Boundaries and Non-Goals

The repository does not currently claim:

- production-ready secret management
- internet-facing Apache hardening by default
- TLS termination
- remote encrypted backup storage
- multi-tenant isolation

## Related Documents

- [Architecture](architecture.md)
- [Deployment Notes](deployment-notes.md)
- [Runbooks](runbooks.md)
