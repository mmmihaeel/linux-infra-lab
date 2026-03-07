SHELL := /usr/bin/env bash

.PHONY: bootstrap up down health smoke lint logs backup backup-restore reset

bootstrap:
	bash ./scripts/bootstrap.sh

up:
	docker compose up -d --build

down:
	docker compose down

health:
	bash ./scripts/healthcheck.sh

smoke:
	bash ./scripts/smoke-test.sh

lint:
	bash ./scripts/lint.sh

logs:
	bash ./scripts/log-summary.sh --since 30m --tail 80

backup:
	bash ./scripts/backup-postgres.sh
	bash ./scripts/backup-mysql.sh

backup-restore:
	bash ./scripts/test-backup-restore.sh

reset:
	bash ./scripts/reset-env.sh --force
