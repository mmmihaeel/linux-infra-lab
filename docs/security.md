# Security

## Scope boundaries

- The current setup is designed for local infrastructure workflows and controlled lab environments.
- TLS termination and centralized secret management are intentionally outside the scope of this iteration.
- Backup retention is currently implemented as a local filesystem policy, with remote archival left as a future extension.

## Security controls in this lab

- Services are isolated on a Docker bridge network (`infra-net`).
- Apache only proxies required routes and sets basic defensive headers.
- Bash scripts enforce strict mode and input validation to reduce operator errors.
- Backup files are timestamped and stored in dedicated directories.
- Demo services run as non-root users in containers.

## Security-sensitive artifacts

- `.env` contains credentials and should never be committed.
- `backups/` can contain sensitive SQL data.
- `logs/` may contain request metadata and operational details.

## Safe operating practices

1. Treat all backup files as sensitive.
2. Rotate or delete old logs and backups (`scripts/log-cleanup.sh`).
3. Restrict Apache `/server-status` if exposed beyond local development.
4. Do not reuse local credentials in any shared environment.
5. Use read-only bind mounts where possible (already applied for static configs).

## Production hardening recommendations

- Move credentials to secret management (Vault, SOPS, cloud secret stores).
- Restrict inbound network exposure and add firewall policy.
- Terminate TLS and enforce secure headers for internet-facing deployments.
- Add centralized log shipping with access controls.
- Add vulnerability scanning in CI for container images and dependencies.
