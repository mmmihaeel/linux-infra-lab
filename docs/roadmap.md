# Roadmap

This roadmap keeps the project honest. It reflects what is already implemented, what would strengthen the repository next, and which ideas belong later so the current local-first operating model stays clear.

## Current Baseline

| Area | Current state |
| --- | --- |
| Edge routing | Apache reverse proxy with route prefixes, a health alias, and `mod_status` |
| Service orchestration | Docker Compose with six services, health checks, and dependency ordering |
| Automation | Strict Bash script layer for bootstrap, health, logs, backups, restores, cleanup, and reset |
| Recovery | PostgreSQL and MySQL backup plus restore validation using seeded sentinel data |
| Diagnostics | Apache file logs, aggregated container logs, health summaries, and smoke checks |
| Validation | Local linting and GitHub Actions integration workflow |

## Near-Term Improvements

- Add a TLS-ready Apache profile for local HTTPS and a documented certificate workflow.
- Add an optional observability profile that complements the current logs-first diagnostics model.
- Add encrypted off-host backup export as an extension to the current local retention model.
- Add more failure drills around dependency loss and partial recovery timing.

## Later Extensions

- Split the Compose stack into profiles such as `core`, `ops`, and `observability`.
- Add a host-tuning guide for Linux-focused operators.
- Add deeper Apache performance notes around concurrency, timeout strategy, and worker tuning.

## Documentation Follow-Ons

- Expand deployment notes for a long-lived VM or homelab scenario.
- Add more troubleshooting examples built around realistic failure symptoms.
- Add examples of backup review and retention policy tuning.

## Guardrails

The roadmap should not blur the current scope. New additions should reinforce the repository as an infrastructure and operations project, not turn it into an unrelated application showcase.
