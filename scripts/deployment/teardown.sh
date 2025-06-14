#!/bin/bash

# ===============================================
# LeadHub Service - Environment Teardown Script
# ===============================================
# This script tears down a specific environment completely

set -e

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

# Set compose file based on environment
if [[ "$ENVIRONMENT" == "staging" ]]; then
    COMPOSE_FILE="docker-compose.staging.yml"
    ENV_FILE=".env.staging"
else
    COMPOSE_FILE="docker-compose.prod.yml"
    ENV_FILE=".env.production"
fi

log_warning "🗑️  Tearing down $ENVIRONMENT environment..."
log_warning "This will stop and remove all containers, networks, and volumes for $ENVIRONMENT"

# Ask for confirmation
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Teardown cancelled."
    exit 0
fi

# Set environment file parameter if it exists
ENV_FILE_PARAM=""
if [[ -f "$ENV_FILE" ]]; then
    ENV_FILE_PARAM="--env-file $ENV_FILE"
    log_info "Using environment file: $ENV_FILE"
fi

# Stop and remove containers, networks, and volumes
log_info "Stopping all services..."
docker-compose -f $COMPOSE_FILE $ENV_FILE_PARAM down --volumes --remove-orphans --timeout 30

# Remove any dangling images from this project
log_info "Cleaning up dangling images..."
docker image prune -f --filter "label=org.opencontainers.image.title=LeadHub Service"

# Remove project-specific volumes (optional - uncomment if needed)
# log_warning "Removing persistent volumes..."
# docker volume rm leadhub-postgres-${ENVIRONMENT} 2>/dev/null || true
# docker volume rm leadhub-grafana-${ENVIRONMENT} 2>/dev/null || true
# docker volume rm leadhub-prometheus-${ENVIRONMENT} 2>/dev/null || true

log_success "✅ $ENVIRONMENT environment has been completely torn down"
log_info "To redeploy, run: ./scripts/deploy.sh $ENVIRONMENT"
