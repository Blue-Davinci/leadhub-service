#!/bin/bash

# Health Check Script for CI/CD Pipeline
# Verifies that the deployed service is working correctly

set -e

# Configuration
SERVICE_URL=${1:-http://localhost}
TIMEOUT=${2:-30}
RETRY_COUNT=${3:-10}

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Wait for service to be ready
log_info "Waiting for service at $SERVICE_URL to be ready..."
log_info "Timeout: ${TIMEOUT}s, Max retries: $RETRY_COUNT"

for i in $(seq 1 $RETRY_COUNT); do
    log_info "Health check attempt $i/$RETRY_COUNT..."
    
    # Check if service responds
    if curl -f -s --max-time $TIMEOUT "$SERVICE_URL/v1/health" > /dev/null; then
        log_success "Service is responding"
        break
    fi
    
    if [[ $i -eq $RETRY_COUNT ]]; then
        log_error "Service failed to respond after $RETRY_COUNT attempts"
        exit 1
    fi
    
    log_warning "Service not ready, waiting 10 seconds..."
    sleep 10
done

# Detailed health check
log_info "Running detailed health checks..."

# Check health endpoint response
HEALTH_RESPONSE=$(curl -s "$SERVICE_URL/v1/health")
if echo "$HEALTH_RESPONSE" | grep -q "available"; then
    log_success "Health endpoint returned 'available' status"
else
    log_error "Health endpoint did not return expected status"
    echo "Response: $HEALTH_RESPONSE"
    exit 1
fi

# Check if environment is included in response
if echo "$HEALTH_RESPONSE" | grep -q "environment"; then
    log_success "Environment information present in health response"
else
    log_warning "Environment information missing from health response"
fi

# Check if version is included in response
if echo "$HEALTH_RESPONSE" | grep -q "version"; then
    log_success "Version information present in health response"
else
    log_warning "Version information missing from health response"
fi

# Test metrics endpoint (if available)
if curl -f -s --max-time 10 "$SERVICE_URL/v1/debug/vars" > /dev/null; then
    log_success "Metrics endpoint is accessible"
else
    log_warning "Metrics endpoint not accessible or not enabled"
fi

# Performance check - measure response time
log_info "Measuring response time..."
RESPONSE_TIME=$(curl -o /dev/null -s -w "%{time_total}" "$SERVICE_URL/v1/health")
if (( $(echo "$RESPONSE_TIME < 1.0" | bc -l) )); then
    log_success "Response time is good: ${RESPONSE_TIME}s"
else
    log_warning "Response time is slow: ${RESPONSE_TIME}s"
fi

log_success "All health checks passed!"
echo ""
echo "Service Details:"
echo "  URL: $SERVICE_URL"
echo "  Health: $SERVICE_URL/v1/health"
echo "  Metrics: $SERVICE_URL/v1/debug/vars"
echo "  Response Time: ${RESPONSE_TIME}s"
echo ""
echo "Health Response:"
echo "$HEALTH_RESPONSE" | jq . 2>/dev/null || echo "$HEALTH_RESPONSE"
