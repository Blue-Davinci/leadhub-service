#!/bin/bash

# LeadHub Service Deployment Script
# This script handles deployment to staging and production environments

set -e

# Configuration
ENVIRONMENT=${1:-staging}
IMAGE_TAG=${2:-latest}

# Set compose file based on environment
if [[ "$ENVIRONMENT" == "staging" ]]; then
    COMPOSE_FILE="docker-compose.staging.yml"
else
    COMPOSE_FILE="docker-compose.prod.yml"
fi

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

# Load environment variables based on environment
if [[ -f ".env.${ENVIRONMENT}" ]]; then
    log_info "Loading environment variables from .env.${ENVIRONMENT}"
    export $(cat .env.${ENVIRONMENT} | grep -v '^#' | xargs)
elif [[ -f ".env" ]]; then
    log_info "Loading environment variables from .env"
    export $(cat .env | grep -v '^#' | xargs)
else
    log_warning "No environment file found. Using default values."
fi

# Check if required files exist
if [[ ! -f "$COMPOSE_FILE" ]]; then
    log_error "Docker compose file not found: $COMPOSE_FILE"
    exit 1
fi

# Set environment file parameter
ENV_FILE_PARAM=""
if [[ -f ".env.${ENVIRONMENT}" ]]; then
    ENV_FILE_PARAM="--env-file .env.${ENVIRONMENT}"
fi

# Pull latest images
log_info "Pulling latest Docker images..."
docker-compose -f $COMPOSE_FILE $ENV_FILE_PARAM pull

# Stop existing services gracefully
log_info "Stopping existing services..."
docker-compose -f $COMPOSE_FILE $ENV_FILE_PARAM down --timeout 30

# Start services with new images
log_info "Starting services with image tag: $IMAGE_TAG..."
export IMAGE_TAG=$IMAGE_TAG
docker-compose -f $COMPOSE_FILE $ENV_FILE_PARAM up -d

# Wait for services to be ready
log_info "Waiting for services to be ready..."
sleep 30

# Run database migrations
log_info "Running database migrations..."

# Set default password for staging if not provided
if [[ "$ENVIRONMENT" == "staging" ]]; then
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-leadhub_staging_password}
    NETWORK_NAME="leadhub-backend-staging"
else
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)}
    NETWORK_NAME="leadhub-backend"
fi

# Check if we have a migration tool or use psql directly
if command -v migrate &> /dev/null; then
    log_info "Using migrate tool for database migrations..."
    docker run --rm --network $NETWORK_NAME \
        -v $(pwd)/internal/sql/schema:/migrations \
        migrate/migrate:latest \
        -path=/migrations \
        -database="postgres://leadhub:${POSTGRES_PASSWORD}@postgres:5432/leadhub?sslmode=disable" up
else
    log_info "Using psql for database schema setup..."
    # Apply schema files directly using psql
    for schema_file in $(ls internal/sql/schema/*.sql | sort); do
        log_info "Applying schema: $(basename $schema_file)"
        docker run --rm --network $NETWORK_NAME \
            -v $(pwd)/internal/sql/schema:/sql \
            postgres:16-alpine \
            psql "postgres://leadhub:${POSTGRES_PASSWORD}@postgres:5432/leadhub?sslmode=disable" \
            -f "/sql/$(basename $schema_file)"
    done
fi

log_success "Database migrations completed"

# Health check
log_info "Running health checks..."

# Set health check URL based on environment
if [[ "$ENVIRONMENT" == "staging" ]]; then
    HEALTH_URL="http://localhost/v1/health"
else
    HEALTH_URL="http://localhost/v1/health"
fi

for i in {1..10}; do
    if curl -f $HEALTH_URL > /dev/null 2>&1; then
        log_success "Health check passed"
        break
    fi
    if [[ $i -eq 10 ]]; then
        log_error "Health check failed after 10 attempts"
        log_info "Checking service logs for debugging..."
        docker-compose -f $COMPOSE_FILE logs --tail=50 api-1
        log_info "Checking if API is running on port 4000 directly..."
        if [[ "$ENVIRONMENT" == "staging" ]]; then
            docker exec leadhub-api-staging curl -f http://localhost:4000/v1/health 2>/dev/null || log_error "API not responding on port 4000"
        fi
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
