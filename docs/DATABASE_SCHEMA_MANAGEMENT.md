# Database Schema Management

This document explains how database schemas are managed in the LeadHub Service project.

## Overview

The project uses a **single source of truth** approach for database schemas with automatic generation for Docker initialization.

## Directory Structure

```
internal/sql/
├── schema/          # Goose migration files (PRIMARY SOURCE)
│   ├── 001_create_table_tenants.sql
│   ├── 002_create_users.sql
│   └── ...
├── docker-init/     # Auto-generated Docker init files
│   ├── 001_create_table_tenants.sql
│   ├── 002_create_users.sql
│   └── ...
└── queries/         # SQLC query files
    ├── tenant_queries.sql
    ├── user_queries.sql
    └── ...
```

## How It Works

### 1. Schema Source (Primary)
- **Location**: `/internal/sql/schema/`
- **Format**: Goose migration files with both UP and DOWN sections
- **Purpose**: 
  - Runtime database migrations using Goose
  - Single source of truth for schema changes
  - Version control for database changes

### 2. Docker Initialization (Auto-generated)
- **Location**: `/internal/sql/docker-init/`
- **Format**: Clean SQL files with only CREATE statements
- **Purpose**: 
  - PostgreSQL container initialization
  - Fast startup without migration overhead
  - Production deployments

## Workflow

### Making Schema Changes

1. **Modify the Goose migration files** in `/internal/sql/schema/`
   ```bash
   # Edit the appropriate migration file
   vim internal/sql/schema/002_create_users.sql
   ```

2. **Deploy the changes** (Docker init files are auto-generated):
   ```bash
   ./scripts.sh deploy staging
   ```

   The deployment process automatically:
   - Generates Docker init files from updated schema
   - Deploys with the latest schema changes
   - Initializes containers with correct database structure

3. **Manual generation** (optional, for testing):
   ```bash
   # Generate Docker init files manually if needed
   ./scripts.sh generate
   ```

### File Generation Script

The `generate-docker-init.sh` script:
- Reads all files from `/internal/sql/schema/`
- Extracts only the `-- +goose Up` sections
- Creates clean SQL files in `/internal/sql/docker-init/`
- Removes Goose directives and DOWN migrations

## Benefits

- **Single Source of Truth**: Only edit schema files in one place  
- **No Duplication**: Docker init files are auto-generated  
- **Version Control**: All changes tracked in Goose migrations  
- **Fast Deployment**: Docker init avoids migration overhead  
- **Development Flexibility**: Use Goose for local development  
- **Production Ready**: Clean initialization for containers  

## Commands

| Command | Purpose |
|---------|---------|
| `./scripts.sh generate` | Generate Docker init files manually (optional) |
| `./scripts.sh deploy <env>` | Deploy with auto-generated schema |
| `goose up` | Run migrations locally |
| `goose down` | Rollback migrations locally |

> **Note**: The `./scripts.sh deploy` command automatically generates Docker init files, so manual generation is typically not required.

## Best Practices

1. **Edit only schema files** - The docker-init files are auto-generated
2. **Use deployment script** - `./scripts.sh deploy` handles generation automatically
3. **Test locally** with Goose before deploying
4. **Commit only schema files** to version control (docker-init files are gitignored)
5. **Use meaningful migration names** and version numbers
6. **Add proper comments** in migration files

## Example: Adding a New Table

1. Create migration file:
   ```sql
   -- internal/sql/schema/006_create_orders.sql
   -- +goose Up
   CREATE TABLE orders (
       id BIGSERIAL PRIMARY KEY,
       tenant_id BIGINT NOT NULL REFERENCES tenants ON DELETE CASCADE,
       -- ... other fields
   );
   
   -- +goose Down
   DROP TABLE IF EXISTS orders;
   ```

2. Deploy (auto-generates Docker init files):
   ```bash
   ./scripts.sh deploy staging
   ```

The Docker init file will be automatically created during deployment with only the CREATE TABLE statement, ready for container initialization.
