#!/bin/bash

# Database Migration Script using Goose
# This script manages database migrations for the LeadHub service

set -e

# Configuration
ENVIRONMENT=${1:-development}
ACTION=${2:-up}
MIGRATION_DIR="internal/sql/schema"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Install goose if not present
if ! command -v goose &> /dev/null; then
    log_info "Installing goose..."
    go install github.com/pressly/goose/v3/cmd/goose@latest
fi

# Set database connection based on environment
case $ENVIRONMENT in
    "production")
        DB_HOST=${DB_HOST:-localhost}
        DB_PORT=${DB_PORT:-5432}
        DB_USER=${DB_USER:-leadhub}
        DB_PASSWORD=${DB_PASSWORD:-}
        DB_NAME=${DB_NAME:-leadhub}
        ;;
    "staging")
        DB_HOST=${DB_HOST:-localhost}
        DB_PORT=${DB_PORT:-5432}
        DB_USER=${DB_USER:-leadhub}
        DB_PASSWORD=${DB_PASSWORD:-password}
        DB_NAME=${DB_NAME:-leadhub_staging}
        ;;
    *)
        DB_HOST=${DB_HOST:-localhost}
        DB_PORT=${DB_PORT:-5432}
        DB_USER=${DB_USER:-leadhub}
        DB_PASSWORD=${DB_PASSWORD:-password}
        DB_NAME=${DB_NAME:-leadhub}
        ;;
esac

# Construct database URL
DB_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable"

log_info "Running goose migration: $ACTION on $ENVIRONMENT"
log_info "Database: $DB_NAME"
log_info "Migration directory: $MIGRATION_DIR"

# Change to migration directory
cd $MIGRATION_DIR

# Run goose command
case $ACTION in
    "up")
        log_info "Applying all pending migrations..."
        goose postgres "$DB_URL" up
        ;;
    "down")
        log_info "Rolling back one migration..."
        goose postgres "$DB_URL" down
        ;;
    "status")
        log_info "Checking migration status..."
        goose postgres "$DB_URL" status
        ;;
    "version")
        log_info "Checking current version..."
        goose postgres "$DB_URL" version
        ;;
    "create")
        MIGRATION_NAME=${3:-new_migration}
        log_info "Creating new migration: $MIGRATION_NAME"
        goose postgres "$DB_URL" create "$MIGRATION_NAME" sql
        ;;
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage: $0 [environment] [action] [migration_name]"
        echo "Environments: development, staging, production"
        echo "Actions: up, down, status, version, create"
        exit 1
        ;;
esac

# Return to original directory
cd - > /dev/null

log_success "Migration completed successfully!"

# Show current status
log_info "Current migration status:"
cd $MIGRATION_DIR
goose postgres "$DB_URL" status
cd - > /dev/null
