# Load environment variables from .env file
ENV_FILE=cmd/api/.env
include $(ENV_FILE)
export

.PHONY: help
help:
	@echo Usage:
	@echo run/api             - run the API application
	@echo db/psql             - connect to the DB using psql
	@echo build/api           - build the cmd/api application for your platform
	@echo build/linux         - build for Linux amd64
	@echo audit               - format, vet, test, staticcheck
	@echo db/migrations/up    - run DB migrations (goose up)
	@echo vendor              - tidy and vendor dependencies

## run/api: run the cmd/api application
.PHONY: run/api
run/api:
	@echo 'Running cmd/api...'
	go run ./cmd/api

## db/psql: connect to the db using psql
.PHONY: db/psql
db/psql:
	@echo 'Connecting to the database using psql...'
	psql "${LEADHUB_DB_DSN}"

## db/migrations/up: run the up migrations using goose
.PHONY: db/migrations/up
db/migrations/up:
	@echo 'Running up migrations...'
	cd internal/sql/schema && goose "${LEADHUB_DB_DSN}" up

## audit: tidy dependencies and format, vet and test all code
.PHONY: audit
audit:
	@echo 'Formatting code...'
	go fmt ./...
	@echo 'Vetting code...'
	go vet ./...
	@echo 'Static analysis...'
	staticcheck ./...
	@echo 'Running tests...'
	go test -race -vet=off ./...

## vendor: tidy and vendor dependencies
.PHONY: vendor
vendor:
	@echo 'Tidying and verifying module dependencies...'
	go mod tidy
	go mod verify
	@echo 'Vendoring dependencies...'
	go mod vendor

## build/api: build the cmd/api application (host platform)
.PHONY: build/api
build/api:
	@echo 'Building cmd/api for host platform...'
	go build -ldflags='-s' -o ./bin/api ./cmd/api

## build/linux: build the cmd/api for linux amd64
.PHONY: build/linux
build/linux:
	@echo 'Building cmd/api for Linux amd64...'
	GOOS=linux GOARCH=amd64 go build -ldflags='-s' -o ./bin/linux_amd64_api ./cmd/api
