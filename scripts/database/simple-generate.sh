#!/bin/bash

# Simple script to generate Docker init files from Goose migrations
cd "$(dirname "$0")/../.."

SCHEMA_DIR="internal/sql/schema"
DOCKER_INIT_DIR="internal/sql/docker-init"

echo "🔄 Generating Docker initialization files..."

# Create directory
mkdir -p "$DOCKER_INIT_DIR"

# Clean existing files
rm -f "$DOCKER_INIT_DIR"/*.sql

# Process each file
for file in "$SCHEMA_DIR"/*.sql; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        output="$DOCKER_INIT_DIR/$filename"
        
        echo "Processing $filename..."
        
        # Create header
        cat > "$output" << EOF
-- Docker initialization script for $filename
-- Auto-generated from Goose migration
-- This file contains only the UP migration

EOF
        
        # Extract UP section
        awk '
            /^-- \+goose Up/ { in_up=1; next }
            /^-- \+goose Down/ { in_up=0 }
            in_up { print }
        ' "$file" >> "$output"
        
        echo "✅ Generated $filename"
    fi
done

echo ""
echo "🎉 All files generated in $DOCKER_INIT_DIR"
ls -la "$DOCKER_INIT_DIR"
