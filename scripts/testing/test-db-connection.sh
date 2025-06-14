#!/bin/bash

# Test database connectivity for LeadHub Service
# Usage: ./test-db-connection.sh [staging|production]

ENVIRONMENT=${1:-staging}

# Colors for output
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

# Load environment variables
if [[ -f ".env.${ENVIRONMENT}" ]]; then
    log_info "Loading environment variables from .env.${ENVIRONMENT}"
    export $(cat .env.${ENVIRONMENT} | grep -v '^#' | xargs)
fi

# Set default password for staging if not provided
if [[ "$ENVIRONMENT" == "staging" ]]; then
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-leadhub_staging_password}
    NETWORK_NAME="leadhub-backend-staging"
    CONTAINER_NAME="leadhub-postgres-staging"
else
    NETWORK_NAME="leadhub-backend"
    CONTAINER_NAME="leadhub-postgres-prod"
fi

log_info "Testing database connection for $ENVIRONMENT environment..."
log_info "Network: $NETWORK_NAME"
log_info "Container: $CONTAINER_NAME"

# Test if postgres container is running
if docker ps | grep -q $CONTAINER_NAME; then
    log_success "PostgreSQL container is running"
else
    log_error "PostgreSQL container is not running"
    exit 1
fi

# Test database connection from within the network
log_info "Testing database connection..."
if docker run --rm --network $NETWORK_NAME postgres:16-alpine \
    psql "postgres://leadhub:${POSTGRES_PASSWORD}@postgres:5432/leadhub?sslmode=disable" \
    -c "SELECT version();" > /dev/null 2>&1; then
    log_success "Database connection successful!"
else
    log_error "Database connection failed!"
    log_info "Debugging information:"
    echo "  - Network: $NETWORK_NAME"
    echo "  - Password: ${POSTGRES_PASSWORD:0:3}***"
    echo "  - Container status:"
    docker ps | grep postgres
    exit 1
fi

# Test if API can connect to database
log_info "Testing API database connectivity..."
if [[ "$ENVIRONMENT" == "staging" ]]; then
    API_CONTAINER="leadhub-api-staging"
else
    API_CONTAINER="leadhub-api-1"
fi

if docker ps | grep -q $API_CONTAINER; then
    log_info "API container is running, checking logs for database connection..."
    docker logs $API_CONTAINER --tail=10 | grep -i "database\|postgres\|error" || log_info "No database-related logs found"
else
    log_error "API container is not running"
fi

log_success "Database connectivity test completed!"
