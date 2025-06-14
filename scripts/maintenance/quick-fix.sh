#!/bin/bash

# Quick fix for Docker networking issues in LeadHub Service
# This script addresses the common Docker deployment problems

set -e

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

ENVIRONMENT=${1:-staging}

log_info "🔧 Quick fix for Docker networking issues - $ENVIRONMENT environment"

# 1. Clean up existing containers and networks
log_info "1. Cleaning up existing containers and networks..."
docker-compose -f docker-compose.staging.yml down --volumes --remove-orphans 2>/dev/null || true
docker-compose -f docker-compose.prod.yml down --volumes --remove-orphans 2>/dev/null || true
docker system prune -f --volumes

# 2. Create environment file if it doesn't exist
log_info "2. Setting up environment configuration..."
if [[ ! -f ".env.${ENVIRONMENT}" ]]; then
    log_warning "Creating default .env.${ENVIRONMENT} file"
    if [[ "$ENVIRONMENT" == "staging" ]]; then
        cat > .env.${ENVIRONMENT} << EOF
POSTGRES_PASSWORD=leadhub_staging_password
GRAFANA_PASSWORD=admin_staging
SMTP_HOST=sandbox.smtp.mailtrap.io
SMTP_USERNAME=your_smtp_username
SMTP_PASSWORD=your_smtp_password
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
EOF
    else
        cat > .env.${ENVIRONMENT} << EOF
POSTGRES_PASSWORD=your_secure_production_password
GRAFANA_PASSWORD=your_secure_grafana_password
SMTP_HOST=your.smtp.server.com
SMTP_USERNAME=your_smtp_username
SMTP_PASSWORD=your_smtp_password
CORS_ORIGINS=https://leadhub.tech,https://app.leadhub.tech
EOF
    fi
    log_success "Environment file created: .env.${ENVIRONMENT}"
    log_warning "Please update the SMTP settings in .env.${ENVIRONMENT}"
fi

# 3. Load environment variables
if [[ -f ".env.${ENVIRONMENT}" ]]; then
    log_info "Loading environment variables from .env.${ENVIRONMENT}"
    export $(cat .env.${ENVIRONMENT} | grep -v '^#' | xargs)
fi

# 4. Set compose file
if [[ "$ENVIRONMENT" == "staging" ]]; then
    COMPOSE_FILE="docker-compose.staging.yml"
else
    COMPOSE_FILE="docker-compose.prod.yml"
fi

# 5. Build and start services
log_info "3. Building and starting services..."
docker-compose -f $COMPOSE_FILE build --no-cache
docker-compose -f $COMPOSE_FILE up -d

# 6. Wait for database to be ready
log_info "4. Waiting for database to be ready..."
sleep 15

# 7. Test database connection
log_info "5. Testing database connection..."
if [[ "$ENVIRONMENT" == "staging" ]]; then
    NETWORK_NAME="leadhub-backend-staging"
else
    NETWORK_NAME="leadhub-backend"
fi

# Try to connect to database
for i in {1..5}; do
    if docker run --rm --network $NETWORK_NAME postgres:16-alpine \
        psql "postgres://leadhub:${POSTGRES_PASSWORD}@postgres:5432/leadhub?sslmode=disable" \
        -c "SELECT 1;" > /dev/null 2>&1; then
        log_success "Database connection successful!"
        break
    fi
    if [[ $i -eq 5 ]]; then
        log_error "Database connection failed after 5 attempts"
        log_info "Showing database logs:"
        docker-compose -f $COMPOSE_FILE logs postgres
        exit 1
    fi
    log_info "Database connection attempt $i failed, retrying..."
    sleep 5
done

# 8. Test API health
log_info "6. Testing API health..."
sleep 10
for i in {1..5}; do
    if [[ "$ENVIRONMENT" == "staging" ]]; then
        if curl -f http://localhost/v1/health > /dev/null 2>&1 || \
           docker exec leadhub-api-staging curl -f http://localhost:4000/v1/health > /dev/null 2>&1; then
            log_success "API health check passed!"
            break
        fi
    else
        if curl -f http://localhost/v1/health > /dev/null 2>&1; then
            log_success "API health check passed!"
            break
        fi
    fi
    if [[ $i -eq 5 ]]; then
        log_error "API health check failed"
        log_info "Showing API logs:"
        docker-compose -f $COMPOSE_FILE logs api-1
        exit 1
    fi
    log_info "API health check attempt $i failed, retrying..."
    sleep 10
done

log_success "🎉 Quick fix completed successfully!"
log_info "Services are running. You can now access:"
if [[ "$ENVIRONMENT" == "staging" ]]; then
    echo "  - API: http://localhost/v1/health"
    echo "  - Database (direct): localhost:5432"
    echo "  - Adminer: http://localhost:8080"
    echo "  - Grafana: http://localhost:3000 (admin/admin_staging)"
    echo "  - Prometheus: http://localhost:9090"
else
    echo "  - API: http://localhost/v1/health"
    echo "  - Grafana: http://localhost:3000"
    echo "  - Prometheus: http://localhost:9090"
fi

echo ""
log_info "To view logs: docker-compose -f $COMPOSE_FILE logs -f"
log_info "To stop: docker-compose -f $COMPOSE_FILE down"
