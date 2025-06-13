#!/bin/bash

# LeadHub Service Deployment Script
# This script handles deployment to staging and production environments

set -e

# Configuration
ENVIRONMENT=${1:-staging}
IMAGE_TAG=${2:-latest}
COMPOSE_FILE="docker-compose.prod.yml"

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    log_error "Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

log_info "Starting deployment to $ENVIRONMENT environment..."

# Check if required files exist
if [[ ! -f "$COMPOSE_FILE" ]]; then
    log_error "Docker compose file not found: $COMPOSE_FILE"
    exit 1
fi

# Install goose if not present
if ! command -v goose &> /dev/null; then
    log_info "Installing goose for database migrations..."
    go install github.com/pressly/goose/v3/cmd/goose@latest
fi

# Run database migrations
log_info "Running database migrations with goose..."
if [[ "$ENVIRONMENT" == "production" ]]; then
    # Production database connection
    export GOOSE_DRIVER="postgres"
    export GOOSE_DBSTRING="postgres://leadhub:${DB_PASSWORD}@db:5432/leadhub?sslmode=disable"
else
    # Staging database connection
    export GOOSE_DRIVER="postgres" 
    export GOOSE_DBSTRING="postgres://leadhub:password@db:5432/leadhub?sslmode=disable"
fi

# Run migrations
cd internal/sql/schema
goose up
cd ../../..

log_success "Database migrations completed"

# Pull latest images
log_info "Pulling latest Docker images..."
docker-compose -f $COMPOSE_FILE pull

# Stop existing services gracefully
log_info "Stopping existing services..."
docker-compose -f $COMPOSE_FILE down --timeout 30

# Start services with new images
log_info "Starting services with image tag: $IMAGE_TAG..."
export IMAGE_TAG=$IMAGE_TAG
docker-compose -f $COMPOSE_FILE up -d

# Wait for services to be ready
log_info "Waiting for services to be ready..."
sleep 30

# Health check
log_info "Running health checks..."
for i in {1..10}; do
    if curl -f http://localhost/v1/health > /dev/null 2>&1; then
        log_success "Health check passed"
        break
    fi
    if [[ $i -eq 10 ]]; then
        log_error "Health check failed after 10 attempts"
        # Show logs for debugging
        docker-compose -f $COMPOSE_FILE logs --tail=50
        exit 1
    fi
    log_info "Health check attempt $i failed, retrying in 10 seconds..."
    sleep 10
done

# Show service status
log_info "Service status:"
docker-compose -f $COMPOSE_FILE ps

log_success "Deployment to $ENVIRONMENT completed successfully!"

# Show useful information
echo ""
echo "Access your application at:"
if [[ "$ENVIRONMENT" == "production" ]]; then
    echo "  - Production: https://leadhub.example.com"
else
    echo "  - Staging: https://staging.leadhub.example.com"
fi
echo "  - Health Check: /v1/health"
echo "  - Metrics: /v1/debug/vars"
echo ""
echo "To view logs:"
echo "  docker-compose -f $COMPOSE_FILE logs -f"
echo ""
echo "To stop services:"
echo "  docker-compose -f $COMPOSE_FILE down"
