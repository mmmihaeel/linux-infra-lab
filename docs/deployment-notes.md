# Deployment Notes

This repository is aimed at a single Linux host, workstation, or homelab VM. The goal is not cloud abstraction. The goal is to keep the local-first operating model intact while making it easy to run the same stack on a persistent host with scheduled maintenance.

## Suitable Deployment Shape

Good fit:

- a personal Linux workstation
- a single VM for demo or interview review
- a small homelab host with Docker and cron

Not the current target:

- clustered environments
- managed cloud service topologies
- externally exposed production workloads

## Host Expectations

| Area | Expectation |
| --- | --- |
| Container runtime | Docker Engine and the Compose plugin are installed |
| Time | System time is synchronized so backup timestamps are trustworthy |
| Storage | There is enough persistent disk for Docker volumes, SQL dumps, and local logs |
| Scheduling | Cron or an equivalent scheduler is available for recurring maintenance |
| Access model | The operator account can run Docker commands and write repository log paths |

## Bring-Up Sequence

```bash
cp .env.example .env
bash ./scripts/bootstrap.sh
bash ./scripts/healthcheck.sh
```

If the repository is deployed to a stable path such as `/opt/linux-infra-lab`, keep the path stable so cron jobs and operational notes do not drift.

## Scheduler and Maintenance Notes

The repository includes `scripts/cron/maintenance.cron` as an example schedule.

Before installing it:

1. Set `REPO_ROOT` to the deployed repository path.
2. Confirm the cron user can execute Docker commands without interaction.
3. Confirm `logs/cron` is writable by that user.

The supplied schedule covers:

- health snapshots every 15 minutes
- nightly PostgreSQL and MySQL backups
- weekly log cleanup

## Data Persistence and Recovery

- MySQL and PostgreSQL persist state in Docker named volumes.
- SQL backups are written into `backups/mysql` and `backups/postgres`.
- Restore scripts read plain `.sql` and `.sql.gz` inputs.
- The restore validation script is the best proof that the deployed host is still producing usable backups.

## Hardening Before Any Shared Environment

| Concern | Recommendation |
| --- | --- |
| Apache status | Restrict `/server-status` by source IP or disable it |
| Transport security | Add TLS termination and HTTP-to-HTTPS redirects |
| Secrets | Replace local `.env` credentials with a secret-management approach |
| Backup handling | Copy SQL dumps to an encrypted off-host destination |
| Exposure | Tighten host firewall rules around the database ports |

## What These Notes Do Not Claim

These deployment notes do not imply:

- high availability
- zero-downtime upgrades
- external load balancing
- multi-tenant hardening
- cloud-native secret or observability stacks

## Related Documents

- [Architecture](architecture.md)
- [Runbooks](runbooks.md)
- [Security](security.md)
