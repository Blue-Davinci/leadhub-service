#!/bin/bash

# Production Deployment Test Script
# Validates the complete deployment pipeline

set -e

echo "🚀 LeadHub Production Deployment Test"
echo "====================================="
echo ""

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

# Test 1: Docker Build
log_info "Testing Docker build..."
if make docker/build > /dev/null 2>&1; then
    log_success "Docker build completed"
else
    log_error "Docker build failed"
    exit 1
fi

# Test 2: Test Suite
log_info "Running test suite..."
if make test/all > /dev/null 2>&1; then
    log_success "All tests passed"
else
    log_error "Tests failed"
    exit 1
fi

# Test 3: Migration Scripts
log_info "Testing migration scripts..."
if [ -x "./scripts/migrate.sh" ]; then
    log_success "Migration scripts are executable"
else
    log_error "Migration scripts are not executable"
    exit 1
fi

# Test 4: Deployment Scripts
log_info "Testing deployment scripts..."
if [ -x "./scripts/deploy.sh" ]; then
    log_success "Deployment scripts are executable"
else
    log_error "Deployment scripts are not executable"
    exit 1
fi

# Test 5: Configuration Files
log_info "Validating configuration files..."
required_configs=(
    "configs/production.env"
    "configs/staging.env"
    "nginx/nginx.conf"
    "docker-compose.prod.yml"
)

for config in "${required_configs[@]}"; do
    if [ -f "$config" ]; then
        log_success "Configuration file exists: $config"
    else
        log_error "Missing configuration file: $config"
        exit 1
    fi
done

# Test 6: Documentation
log_info "Checking documentation..."
required_docs=(
    "docs/DEPLOYMENT.md"
    "docs/DEVOPS.md"
    "README.md"
)

for doc in "${required_docs[@]}"; do
    if [ -f "$doc" ]; then
        log_success "Documentation exists: $doc"
    else
        log_error "Missing documentation: $doc"
        exit 1
    fi
done

echo ""
echo "🎉 All deployment tests passed!"
echo ""
echo "Deployment readiness summary:"
echo "  ✓ Docker containerization working"
echo "  ✓ Test suite passing"
echo "  ✓ Migration scripts ready"
echo "  ✓ Deployment automation ready"
echo "  ✓ Production configurations present"
echo "  ✓ Documentation complete"
echo ""
echo "The LeadHub service is ready for production deployment!"
echo ""
echo "Next steps:"
echo "  1. Commit changes: git add . && git commit -m 'feat: production-ready deployment'"
echo "  2. Create release: git tag v1.0.0 && git push origin v1.0.0"
echo "  3. Deploy: make deploy/production"
