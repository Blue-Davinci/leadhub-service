.PHONY: help
help:
	@echo "LeadHub Service - Available Commands:"
	@echo ""
	@echo "Development:"
	@echo "  run/api             - run the API application"
	@echo "  test/all            - run complete test suite"
	@echo "  audit               - format, vet, test, staticcheck"
	@echo "  format              - format all Go code"
	@echo "  format/check        - check if code is properly formatted"
	@echo ""
	@echo "Database:"
	@echo "  migrate/up          - run database migrations up"
	@echo "  migrate/status      - check migration status"
	@echo ""
	@echo "Docker & Deployment:"
	@echo "  docker/build        - build docker image"
	@echo "  docker/dev          - start development environment"
	@echo "  docker/prod         - start production environment"
	@echo "  deploy/staging      - deploy to staging environment"
	@echo "  deploy/production   - deploy to production environment"
	@echo ""
	@echo "Operations:"
	@echo "  health/check        - run health check"
	@echo "  build/api           - build the cmd/api application"
	@echo "  build/linux         - build for Linux amd64"
	@echo "  vendor              - tidy and vendor dependencies"

## run/api: run the cmd/api application
.PHONY: run/api
run/api:
	@echo 'Running cmd/api...'
	go run ./cmd/api

## audit: tidy dependencies and format, vet and test all code
.PHONY: audit
audit:
	@echo 'Formatting code...'
	go fmt ./...
	@echo 'Vetting code...'
	go vet ./...
	@echo 'Running tests...'
	go test -race -vet=off ./...

## format: format all Go code
.PHONY: format
format:
	@echo 'Formatting all Go code...'
	go fmt ./...
	@echo 'Code formatting complete!'

## format/check: check if code is properly formatted
.PHONY: format/check
format/check:
	@echo 'Checking code formatting...'
	@if [ "$$(gofmt -l . | wc -l)" -gt 0 ]; then \
		echo "Code iis not properly formatted. Run 'make format' to fix:"; \
		gofmt -l .; \
		exit 1; \
	else \
		echo "All code is properly formated!"; \
	fi

## vendor: tidy and vendor dependencies
.PHONY: vendor
vendor:
	@echo 'Tidying and verifying module dependencies...'
	go mod tidy
	go mod verify
	@echo 'Vendoring dependencies...'
	go mod vendor

## build/api: build the cmd/api application
.PHONY: build/api
build/api:
	@echo 'Building cmd/api for host platform...'
	go build -ldflags='-s' -o ./bin/api ./cmd/api

## build/linux: build the cmd/api for linux amd64
.PHONY: build/linux
build/linux:
	@echo 'Building cmd/api for Linux amd64...'
	GOOS=linux GOARCH=amd64 go build -ldflags='-s' -o ./bin/linux_amd64_api ./cmd/api

## docker/build: build docker image
.PHONY: docker/build
docker/build:
	@echo 'Building Docker image...'
	docker build -t leadhub-service:latest .

## docker/dev: start development environment
.PHONY: docker/dev
docker/dev:
	@echo 'Starting development environment...'
	docker-compose up -d
	@echo 'Services started. Access at http://localhost:4000'

## docker/prod: start production environment
.PHONY: docker/prod
docker/prod:
	@echo 'Starting production environment...'
	docker-compose -f docker-compose.prod.yml up -d
	@echo 'Production services started'

## deploy/staging: deploy to staging environment
.PHONY: deploy/staging
deploy/staging:
	@echo 'Deploying to staging...'
	./scripts/deploy.sh staging

## deploy/production: deploy to production environment
.PHONY: deploy/production
deploy/production:
	@echo 'Deploying to production...'
	./scripts/deploy.sh production

## test/all: run complete test suite
.PHONY: test/all
test/all:
	@echo 'Running complete test suite...'
	./test.sh

## health/check: run health check
.PHONY: health/check
health/check:
	@echo 'Running health check...'
	./scripts/healthcheck.sh http://localhost

## migrate/up: run database migrations up
.PHONY: migrate/up
migrate/up:
	@echo 'Running database migrations...'
	./scripts/database/migrate.sh development up

## migrate/status: check migration status
.PHONY: migrate/status
migrate/status:
	@echo 'Checking migration status...'
	./scripts/database/migrate.sh development status
