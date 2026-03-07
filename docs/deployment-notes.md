# Deployment Notes

This repository targets local infrastructure operations. The same topology can be adapted for a small Linux VM or homelab host with additional controls.

## Scope boundaries

- The current setup is designed for local infrastructure workflows and controlled lab environments.
- TLS termination and centralized secret management are intentionally outside the scope of this iteration.
- Backup retention is currently implemented as a local filesystem policy, with remote archival left as a future extension.

## Linux host expectations

- Docker Engine and Compose plugin installed
- System time synchronized (NTP)
- Persistent storage for Docker volumes
- Disk monitoring for backup and log directories

## Environment preparation

1. Clone repository to a stable path (example: `/opt/linux-infra-lab`).
2. Create environment file:
   ```bash
   cp .env.example .env
   ```
3. Tune credentials and host port mappings.

## Start-up sequence

```bash
bash ./scripts/bootstrap.sh
bash ./scripts/healthcheck.sh
```

## Scheduled operations

- Install cron entries from `scripts/cron/maintenance.cron`.
- Set `REPO_ROOT` in the cron file to the deployment path.
- Ensure cron user has permission to execute scripts and write `logs/cron`.

## Data and persistence

- MySQL and PostgreSQL data are persisted via Docker named volumes.
- SQL backups are written to `backups/mysql` and `backups/postgres`.
- Backups should be copied to remote encrypted storage in non-local deployments.

## Hardening checklist for non-local usage

- Restrict Apache status endpoint by IP allowlist.
- Add TLS and redirect HTTP to HTTPS.
- Replace plaintext env secrets with a secret manager.
- Add host firewall rules for database ports.
- Introduce monitoring and alerting for service health and disk pressure.
