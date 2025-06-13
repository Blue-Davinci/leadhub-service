#!/bin/bash
# LeadHub Development Script
# Sets up environment for local API + containerized PostgreSQL

echo "Starting LeadHub Development Environment..."

# Start PostgreSQL container if not running
echo "Ensuring PostgreSQL container is running..."
docker-compose up -d postgres

# Stop containerized API and NGINX if running (for hybrid development)
echo "Stopping containerized API and NGINX (if running)..."
docker stop leadhub-api leadhub-nginx 2>/dev/null || true

# Set environment variables for local development
echo "🔧 Setting environment variables..."
export DB_PASSWORD=leadhub_dev_password
export DB_USER=leadhub
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=leadhub

# Run database migrations
echo "🗄️ Running database migrations..."
make migrate/up

echo "Environment ready! Starting local API..."
echo "API will be available at: http://localhost:4000"
echo "PostgreSQL running in container on: localhost:5432"
echo ""

# Run the API
make run/api
