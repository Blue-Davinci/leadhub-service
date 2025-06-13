#!/bin/bash
# LeadHub Development Script
# Sets up environment for local API + containerized PostgreSQL
# Usage: ./dev.sh [--reset] 

# Check for reset flag
if [[ "$1" == "--reset" ]]; then
    echo "Resetting database to clean state..."
    pkill -f "go run ./cmd/api" 2>/dev/null || true
    docker-compose down -v
    docker volume prune -f
    echo "Database reset complete!"
fi

echo "Starting LeadHub Development Environment..."

# Start PostgreSQL container if not running
echo "Ensuring PostgreSQL container is running..."
docker-compose up -d postgres

# Stop containerized API and NGINX if running (for hybrid development)
echo "Stopping containerized API and NGINX (if running)..."
docker stop leadhub-api leadhub-nginx 2>/dev/null || true

# Set environment variables for local development
echo "🔧 Setting environment variables..."

# Load .env file if it exists
if [ -f "cmd/api/.env" ]; then
    echo "Loading environment variables from cmd/api/.env..."
    set -a  # automatically export all variables
    source cmd/api/.env
    set +a  # stop automatically exporting
fi

# Override DB settings for local development
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
