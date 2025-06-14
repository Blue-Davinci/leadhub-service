# 📁 LeadHub Service - Script Organization Guide

## 🗂️ **New Organized Structure**

All scripts have been reorganized into logical categories for better management:

```
scripts/
├── deployment/           # Deployment & Infrastructure
├── development/         # Development Environment
├── database/           # Database Management
├── testing/            # Testing & Validation
└── maintenance/        # System Maintenance
```

## 📋 **Script Categories & Purposes**

### 🚀 **Deployment Scripts** (`scripts/deployment/`)

| Script | Purpose | Usage |
|--------|---------|-------|
| `deploy.sh` | **Master deployment script**<br/>- Handles staging/production deployment<br/>- Loads correct `.env` files<br/>- Manages Docker containers | `./scripts/deployment/deploy.sh [staging\|production]` |
| `validate-deployment.sh` | **Deployment validation**<br/>- Tests all service endpoints<br/>- Validates container health<br/>- Comprehensive status report | `./scripts/deployment/validate-deployment.sh` |
| `teardown.sh` | **Environment cleanup**<br/>- Complete environment removal<br/>- Cleans containers, volumes, networks<br/>- Optional image cleanup | `./scripts/deployment/teardown.sh [staging\|production]` |

### 💻 **Development Scripts** (`scripts/development/`)

| Script | Purpose | Usage |
|--------|---------|-------|
| `dev.sh` | **Development environment**<br/>- Starts local API + containerized DB<br/>- Supports database reset<br/>- Hot-reload development | `./scripts/development/dev.sh [--reset]` |

### 🗄️ **Database Scripts** (`scripts/database/`)

| Script | Purpose | Usage |
|--------|---------|-------|
| `reset-db.sh` | **Database reset**<br/>- Complete database wipe<br/>- Fresh container creation<br/>- Clean state restoration | `./scripts/database/reset-db.sh` |
| `migrate.sh` | **Database migrations**<br/>- Run schema migrations<br/>- Update database structure | `./scripts/database/migrate.sh` |
| `add-user-permissions.sh` | **User management**<br/>- Add user permissions<br/>- Manage access rights | `./scripts/database/add-user-permissions.sh` |
| `generate-docker-init.sh` | **Schema automation**<br/>- Generate Docker init files from migrations<br/>- Single source of truth workflow<br/>- Auto-extract UP sections only | `./scripts/database/generate-docker-init.sh` |

### 🧪 **Testing Scripts** (`scripts/testing/`)

| Script | Purpose | Usage |
|--------|---------|-------|
| `test.sh` | **Full test suite**<br/>- Comprehensive testing<br/>- Coverage reports<br/>- Professional test output | `./scripts/testing/test.sh` |
| `test-db-connection.sh` | **Database connectivity test**<br/>- Tests DB connection for environment<br/>- Validates credentials<br/>- Network troubleshooting | `./scripts/testing/test-db-connection.sh [staging\|production]` |
| `test-complete-setup.sh` | **Integration testing**<br/>- Tests complete setup<br/>- End-to-end validation | `./scripts/testing/test-complete-setup.sh` |
| `test-deployment.sh` | **Deployment testing**<br/>- Post-deployment validation<br/>- Service integration tests | `./scripts/testing/test-deployment.sh` |

### 🔧 **Maintenance Scripts** (`scripts/maintenance/`)

| Script | Purpose | Usage |
|--------|---------|-------|
| `quick-fix.sh` | **Emergency fixes**<br/>- Resolves common Docker issues<br/>- Network/connectivity problems<br/>- Environment setup fixes | `./scripts/maintenance/quick-fix.sh [environment]` |
| `healthcheck.sh` | **System health monitoring**<br/>- Comprehensive health checks<br/>- Service status monitoring<br/>- Performance diagnostics | `./scripts/maintenance/healthcheck.sh` |

## 🎯 **Master Script Manager**

Use the main `scripts.sh` for easy access to all scripts:

```bash
# Show all available scripts
./scripts.sh help

# Quick commands
./scripts.sh dev              # Start development
./scripts.sh deploy staging   # Deploy to staging
./scripts.sh test             # Run tests
./scripts.sh generate         # Generate Docker init files
./scripts.sh validate         # Validate deployment
./scripts.sh teardown staging # Teardown staging
```

## 📋 **Script Purposes Explained**

### **Quick-Fix Script** (`scripts/maintenance/quick-fix.sh`)
**Purpose**: Emergency troubleshooting for common Docker deployment issues
- ✅ Cleans up orphaned containers and networks
- ✅ Recreates environment files if missing
- ✅ Fixes permission issues
- ✅ Resolves Docker networking conflicts
- ✅ Automated problem resolution

### **Test-DB-Connection Script** (`scripts/testing/test-db-connection.sh`)
**Purpose**: Database connectivity troubleshooting
- ✅ Tests PostgreSQL connection for specific environment
- ✅ Validates database credentials
- ✅ Checks network connectivity
- ✅ Diagnoses connection failures
- ✅ Environment-specific testing

## 🚀 **Common Workflows**

### **Complete Development Setup**
```bash
# Start development environment
./scripts.sh dev

# Or manually
./scripts/development/dev.sh
```

### **Staging Deployment Lifecycle**
```bash
# Deploy to staging
./scripts/deployment/deploy.sh staging

# Validate deployment
./scripts/deployment/validate-deployment.sh

# If issues occur
./scripts/maintenance/quick-fix.sh staging

# Teardown when done
./scripts/deployment/teardown.sh staging
```

### **Testing & Validation**
```bash
# Run full test suite
./scripts/testing/test.sh

# Test database connectivity
./scripts/testing/test-db-connection.sh staging

# Validate deployment
./scripts/deployment/validate-deployment.sh
```

### **Emergency Troubleshooting**
```bash
# Quick fix for common issues
./scripts/maintenance/quick-fix.sh

# Check system health
./scripts/maintenance/healthcheck.sh

# Reset database if corrupted
./scripts/database/reset-db.sh
```

## 📖 **Migration from Old Structure**

### **Old vs New Paths**
| Old Location | New Location | Category |
|--------------|--------------|----------|
| `./dev.sh` | `./scripts/development/dev.sh` | Development |
| `./test.sh` | `./scripts/testing/test.sh` | Testing |
| `./reset-db.sh` | `./scripts/database/reset-db.sh` | Database |
| `./scripts/deploy.sh` | `./scripts/deployment/deploy.sh` | Deployment |

### **Backward Compatibility**
Use the master script manager for universal access:
```bash
./scripts.sh dev        # Instead of ./dev.sh
./scripts.sh test       # Instead of ./test.sh
./scripts.sh deploy     # Instead of ./scripts/deploy.sh
```

This organization makes the project more maintainable and easier to navigate! 🎉

## **Database Management**
```bash
# Generate Docker init files from schema
./scripts/database/generate-docker-init.sh
# Or use the master script
./scripts.sh generate

# Reset database to clean state
./scripts/database/reset-db.sh

# Run database migrations
./scripts/database/migrate.sh
```
