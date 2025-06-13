#!/bin/bash

# Add permissions to a user in development
# Usage: ./scripts/add-user-permissions.sh <email> <permission1> [permission2] ...
# Example: ./scripts/add-user-permissions.sh user@example.com admin:read admin:write

set -e

# Configuration
DB_NAME="${LEADHUB_DB_NAME:-leadhub}"
DB_USER="${LEADHUB_DB_USERNAME:-leadhub}"
DB_PASSWORD="${LEADHUB_DB_PASSWORD:-pa55word}"
DB_HOST="${LEADHUB_DB_HOST:-localhost}"
DB_PORT="${LEADHUB_DB_PORT:-5432}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage function
usage() {
    echo -e "${BLUE}Usage: $0 <email> <permission1> [permission2] ...${NC}"
    echo ""
    echo -e "${YELLOW}Available permissions:${NC}"
    echo "  admin:read  - Read admin permissions"
    echo "  admin:write - Write admin permissions"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 admin@example.com admin:read admin:write"
    echo "  $0 user@example.com admin:read"
    echo ""
    echo -e "${YELLOW}Note:${NC} Make sure the database is running before running this script."
    echo "You can start it with: docker-compose -f docker-compose.dev.yml up -d db"
}

# Check if at least 2 arguments provided
if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    usage
    exit 1
fi

EMAIL="$1"
shift
PERMISSIONS=("$@")

echo -e "${BLUE}Adding permissions for user: ${EMAIL}${NC}"
echo -e "${YELLOW}Permissions to add: ${PERMISSIONS[*]}${NC}"
echo ""

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo -e "${RED}Error: psql is not installed. Please install PostgreSQL client.${NC}"
    echo "On Ubuntu/Debian: sudo apt-get install postgresql-client"
    echo "On macOS: brew install postgresql"
    exit 1
fi

# Test database connection
echo -e "${BLUE}Testing database connection...${NC}"
if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${RED}Error: Cannot connect to database${NC}"
    echo "Please check that:"
    echo "1. Database is running: docker-compose -f docker-compose.dev.yml up -d db"
    echo "2. Database credentials are correct"
    echo "3. Database host and port are accessible"
    exit 1
fi

# Function to execute SQL queries
execute_sql() {
    local query="$1"
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$query" 2>/dev/null
}

# Check if user exists
echo -e "${BLUE}Checking if user exists...${NC}"
USER_ID=$(execute_sql "SELECT id FROM users WHERE email = '$EMAIL';")

if [ -z "$USER_ID" ]; then
    echo -e "${RED}Error: User with email '$EMAIL' not found${NC}"
    echo ""
    echo -e "${YELLOW}Available users:${NC}"
    execute_sql "SELECT id, name, email, activated FROM users;" | while IFS='|' read -r id name email activated; do
        if [ -n "$id" ]; then
            status="inactive"
            if [ "$activated" = "t" ]; then
                status="active"
            fi
            echo "  ID: $id, Name: $name, Email: $email, Status: $status"
        fi
    done
    exit 1
fi

echo -e "${GREEN}User found: ID $USER_ID${NC}"

# Check current permissions
echo -e "${BLUE}Current permissions for user:${NC}"
CURRENT_PERMS=$(execute_sql "SELECT p.code FROM permissions p INNER JOIN users_permissions up ON p.id = up.permission_id WHERE up.user_id = $USER_ID;")
if [ -n "$CURRENT_PERMS" ]; then
    echo "$CURRENT_PERMS" | while read -r perm; do
        if [ -n "$perm" ]; then
            echo -e "  ${GREEN}✓${NC} $perm"
        fi
    done
else
    echo -e "  ${YELLOW}No permissions currently assigned${NC}"
fi
echo ""

# Add each permission
for permission in "${PERMISSIONS[@]}"; do
    echo -e "${BLUE}Adding permission: $permission${NC}"
    
    # Check if permission exists
    PERM_ID=$(execute_sql "SELECT id FROM permissions WHERE code = '$permission';")
    if [ -z "$PERM_ID" ]; then
        echo -e "  ${RED}✗ Permission '$permission' does not exist${NC}"
        continue
    fi
    
    # Check if user already has this permission
    EXISTING=$(execute_sql "SELECT 1 FROM users_permissions WHERE user_id = $USER_ID AND permission_id = $PERM_ID;")
    if [ -n "$EXISTING" ]; then
        echo -e "  ${YELLOW}⚠ User already has permission '$permission'${NC}"
        continue
    fi
    
    # Add the permission
    if execute_sql "INSERT INTO users_permissions (user_id, permission_id) VALUES ($USER_ID, $PERM_ID);" > /dev/null; then
        echo -e "  ${GREEN}✓ Successfully added permission '$permission'${NC}"
    else
        echo -e "  ${RED}✗ Failed to add permission '$permission'${NC}"
    fi
done

echo ""
echo -e "${BLUE}Final permissions for user:${NC}"
FINAL_PERMS=$(execute_sql "SELECT p.code FROM permissions p INNER JOIN users_permissions up ON p.id = up.permission_id WHERE up.user_id = $USER_ID;")
if [ -n "$FINAL_PERMS" ]; then
    echo "$FINAL_PERMS" | while read -r perm; do
        if [ -n "$perm" ]; then
            echo -e "  ${GREEN}✓${NC} $perm"
        fi
    done
else
    echo -e "  ${YELLOW}No permissions assigned${NC}"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
