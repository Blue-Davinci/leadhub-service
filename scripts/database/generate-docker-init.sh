#!/bin/bash

# Generate Docker initialization files from Goose migration files
# This script extracts only the UP migration parts and creates clean Docker init files

cd "$(dirname "$0")/../.."

SCHEMA_DIR="internal/sql/schema"
DOCKER_INIT_DIR="internal/sql/docker-init"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Show usage if help requested
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: $0"
    echo ""
    echo "This script generates Docker initialization files from Goose migration files."
    echo "It extracts only the UP migration parts, creating clean SQL files for Docker."
    echo ""
    echo "Source: $SCHEMA_DIR"
    echo "Target: $DOCKER_INIT_DIR"
    exit 0
fi

log_info "🔄 Generating Docker initialization files from Goose migrations..."

# Check if schema directory exists
if [[ ! -d "$SCHEMA_DIR" ]]; then
    log_error "Schema directory not found: $SCHEMA_DIR"
    exit 1
fi

# Create docker-init directory if it doesn't exist
mkdir -p "$DOCKER_INIT_DIR"

# Clean existing docker-init files
log_warning "Removing existing docker-init files..."
rm -f "$DOCKER_INIT_DIR"/*.sql

# Process each schema file
count=0
for schema_file in "$SCHEMA_DIR"/*.sql; do
    if [[ -f "$schema_file" ]]; then
        filename=$(basename "$schema_file")
        docker_init_file="$DOCKER_INIT_DIR/$filename"
        
        log_info "Processing $filename..."
        
        # Create header
        cat > "$docker_init_file" << EOF
-- Docker initialization script for $filename
-- Auto-generated from Goose migration
-- This file contains only the UP migration

EOF
        
        # Extract UP section
        awk '
            /^-- \+goose Up/ { in_up=1; next }
            /^-- \+goose Down/ { in_up=0 }
            in_up { print }
        ' "$schema_file" >> "$docker_init_file"
        
        log_success "Generated $filename"
        ((count++))
    fi
done

if [[ $count -eq 0 ]]; then
    log_warning "No schema files found in $SCHEMA_DIR"
    exit 1
fi

log_success "✅ Generated $count Docker initialization files"
log_info "Files created in: $DOCKER_INIT_DIR"

# List generated files
echo ""
log_info "Generated files:"
if ls "$DOCKER_INIT_DIR"/*.sql &>/dev/null; then
    ls -la "$DOCKER_INIT_DIR"/*.sql | while read -r line; do
        echo "  $line"
    done
fi

echo ""
log_success "🎉 Docker initialization files are ready!"
log_info "You can now rebuild your containers to use the updated schema"
log_info "Run: ./scripts/deployment/deploy.sh <environment>"
