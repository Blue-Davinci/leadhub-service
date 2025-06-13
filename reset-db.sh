#!/bin/bash
# LeadHub Database Reset Script
# Completely resets the PostgreSQL container and database to clean state

echo "🔄 Resetting LeadHub Database to Clean State..."

# Stop the API if running
echo "Stopping API..."
pkill -f "go run ./cmd/api" 2>/dev/null || true

# Stop and remove containers with volumes (this removes all data)
echo "Stopping and removing PostgreSQL container with data..."
docker-compose down -v

# Remove any orphaned volumes
echo "Cleaning up any orphaned volumes..."
docker volume prune -f

# Start fresh PostgreSQL container
echo "Starting fresh PostgreSQL container..."
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 5

# Run migrations to set up fresh schema
echo "Setting up fresh database schema..."
make migrate/up

# Insert default tenant again
echo "Inserting default tenant..."
docker exec -it leadhub-postgres psql -U leadhub -d leadhub -c "INSERT INTO tenants (name, contact_email, description) VALUES ('TradeHub KE', 'admin@tradehub.co.ke', 'The center of anything trading, Kenya!');" 2>/dev/null || echo "Default tenant may already exist"

echo "✅ Database reset complete!"
echo "📋 Database now contains:"
echo "   - Fresh schema (all tables)"
echo "   - Default tenant (TradeHub KE)"
echo "   - No users or trade leads"
echo ""
echo "🚀 Ready to start development with: ./dev.sh"
