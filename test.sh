#!/bin/bash

# Test runner script for LeadHUb Service
# This script runs all tests with coverage and provides a professional test report

set -e

echo "🔧 LeadHub Service - Test Suite"
echo "================================"
echo ""

# CoOors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Check if Go is installed
if ! command -v go &> /dev/null; then
    print_error "Go is not installed or not in PATH"
    exit 1
fi

print_status "Go version: $(go version)"
echo ""

# Clean test cache
print_status "Cleaning test cache..."
go clean -testcache

# Run tests with coverage
print_status "Running tests with coverage..."
echo ""

# Test individul packages
packages=(
    "./cmd/api"
    "./internal/data"
)

overall_success=true

for package in "${packages[@]}"; do
    print_status "Testing package: $package"
    
    if go test -v -race -cover "$package"; then
        print_success "Package $package tests passed"
    else
        print_error "Package $package tests failed"
        overall_success=false
    fi
    echo ""
done

# Run tests with coverage report
print_status "Generating coverage report..."
go test -coverprofile=coverage.out ./cmd/api ./internal/data
go tool cover -html=coverage.out -o coverage.html

print_status "Coverage report generated: coverage.html"
echo ""

# Summary
echo "> Test Summary"
echo "==============="

if [ "$overall_success" = true ]; then
    print_success "All tests passed!!!"
    echo ""
    echo "Key Test Coverage:"
    echo "- Health Check Endpoint"
    echo "- Multi-Tenant Security (Prevents data leakage)"
    echo "- Authentication & Authorization"
    echo "- Rate Limiting Protection"
    echo "- Input Validation & Data Integrity"
    echo "- Panic Recovery & Error Handling"
    echo "- Financial Precision (Decimal handling)"
    echo ""
    echo "hese tests demonstrate production-ready security and reliability!"
    exit 0
else
    print_error "Some tests failed!!"
    exit 1
fi
