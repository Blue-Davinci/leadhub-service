<p align="center">
  <a href="" rel="noopener">
 <img width=200px height=200px src="https://i.ibb.co/5hCHs54H/lead-hub-high-resolution-logo-modified.png" alt="Project logo"></a>
</p>

<h3 align="center">LeadHub Service</h3>

<div align="center">

[![Status](https://img.shields.io/badge/status-active-success.svg)](https://github.com/Blue-Davinci/leadhub-service)
[![GitHub Issues](https://img.shields.io/github/issues/Blue-Davinci/leadhub-service.svg)](https://github.com/Blue-Davinci/leadhub-service/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/Blue-Davinci/leadhub-service.svg)](https://github.com/Blue-Davinci/leadhub-service/pulls)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)

</div>

---

<p align="center"> An real source african assignment
    <br> 
</p>

## 📝 Table of Contents

- [About](#about)
- [Getting Started](#getting_started)
- [DevOps & Deployment](#deployment)
- [Usage](#usage)
- [API Documentation](#api_docs)
- [Testing](#testing)
- [Built Using](#built_using)
- [Authors](#authors)
- [Documentation](#documentation)

## 🧐 About <a name = "about"></a>

**LeadHub Service** is the foundational backend system for Real Sources Africa’s LeadHub platform. It supports multi-tenancy, secure lead management, and administrative oversight.  
Each tenant (e.g., government agency, investment authority) can create, manage, and view only their trade leads, with strict data isolation.  
An admin interface allows for onboarding new tenants and system-wide statistics reporting.


## 🏁 Getting Started <a name = "getting_started"></a>

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See [deployment](#deployment) for notes on how to deploy the project on a live system.

### Prerequisites

```bash
- Go 1.23+
- Docker & Docker Compose
- PostgreSQL 16+
- GNU Make (optional, for scripted workflows)
```

### Quick Start

The LeadHub Service uses an automated script management system for easy development and deployment:

```bash
# Clone the repository
git clone https://github.com/Blue-Davinci/leadhub-service.git
cd leadhub-service

# View all available commands
./scripts.sh help

# Start development environment
./scripts.sh dev

# Or run individual services
./scripts/development/dev.sh
```

### Installation

1. **Clone and Setup**:
```bash
git clone https://github.com/Blue-Davinci/leadhub-service.git
cd leadhub-service
```

2. **Environment Configuration**:
```bash
# Copy environment templates
cp .env.example .env
cp .env.staging.example .env.staging
cp .env.production.example .env.production
```

3. **Database Schema Management**:
```bash
# Generate Docker initialization files from Goose migrations
./scripts.sh generate

# Or manually run the generator
./scripts/database/generate-docker-init.sh
```

### Development Environment

```bash
# Start development environment with hot reload
./scripts.sh dev

# Reset development environment
./scripts/development/dev.sh --reset

# Run tests
./scripts.sh test

# Validate deployment
./scripts.sh validate
```

## 🔧 Running the tests <a name = "tests"></a>

Explain how to run the automated tests for this system.

### Break down into end to end tests

Run unit tests

```bash
go test ./...
```
_Integration and e2e test instructions coming soon._

### And coding style tests

_coming soon_

```bash
echo "we coming"
```

## 🎈 Usage <a name="usage"></a>

Once running locally:
```bash
API base URL: http://localhost:4000/v1

Health check: GET /v1/health

Trade leads: GET /v1/trade_leads/ (Bearer token required)
```

## 🚀 DevOps & Deployment <a name = "deployment"></a>

### Quick Deployment Commands

```bash
# Generate database schema files
./scripts.sh generate

# Deploy to staging
./scripts.sh deploy staging

# Deploy to production  
./scripts.sh deploy production

# Validate deployment
./scripts.sh validate

# Teardown environment
./scripts.sh teardown staging
```

### Script Management System

The LeadHub Service includes a comprehensive script management system organized by category:

```bash
# View all available scripts
./scripts.sh help

# Deployment scripts
./scripts.sh deploy [staging|production]    # Deploy application
./scripts.sh validate                       # Validate deployment  
./scripts.sh teardown [environment]         # Clean teardown

# Database scripts
./scripts.sh generate                       # Generate Docker init files
./scripts/database/reset-db.sh             # Reset database
./scripts/database/migrate.sh              # Run migrations

# Development scripts
./scripts.sh dev                           # Start dev environment
./scripts.sh test                          # Run test suite

# Maintenance scripts
./scripts/maintenance/quick-fix.sh          # Quick system fixes
```

### Database Schema Management

LeadHub uses an automated **single source of truth** approach for database schema management:

- **Primary Source**: `/internal/sql/schema/` (Goose migration files)
- **Auto-Generated**: `/internal/sql/docker-init/` (Clean Docker initialization files)
- **Automated Workflow**: Docker init files are automatically generated during deployment

```bash
# Edit schema files in /internal/sql/schema/
vim internal/sql/schema/002_create_users.sql

# Deploy automatically generates and uses latest schema
./scripts.sh deploy staging

# Manual generation (optional, for testing)
./scripts.sh generate
```

### Environment Management

- **Development**: Local development with hot reload
- **Staging**: Automated deployment from development branch  
- **Production**: Release-based deployment with health monitoring

### CI/CD Pipeline
- **Automated Testing**: Unit, integration, and security tests
- **Container Security**: Vulnerability scanning with Trivy
- **Multi-environment**: Staging and production environments
- **Health Monitoring**: Automated health checks and rollback
- **Schema Automation**: Automatic Docker init file generation

### Documentation
- **[Complete Deployment Guide](./docs/DEPLOYMENT.md)** - Comprehensive deployment procedures
- **[Database Schema Management](./docs/DATABASE_SCHEMA_MANAGEMENT.md)** - Schema workflow and automation
- **[DevOps Guide](./docs/DEVOPS.md)** - Infrastructure and operational procedures  
- **[Script Organization](./docs/SCRIPT_ORGANIZATION.md)** - Script management documentation

## 🧪 Testing <a name = "testing"></a>

### Automated Testing

```bash
# Run all tests with coverage
./scripts.sh test

# Individual test categories
./scripts/testing/test.sh                    # Full test suite
./scripts/testing/test-db-connection.sh      # Database connectivity
./scripts/testing/test-complete-setup.sh    # End-to-end setup testing

# Manual testing commands
go test ./...                               # Basic unit tests
go test -race ./...                         # Race condition detection
go test -cover ./...                        # Coverage report
```

### Testing Features

**Test Coverage:**
- Multi-tenant security validation
- Authentication and authorization  
- Rate limiting and panic recovery
- Business logic validation
- Database schema validation
- Deployment validation
- Container health checks

**Database Testing:**
- Schema integrity validation
- Migration testing (up/down)
- Multi-tenant data isolation
- Connection pooling and performance

**Integration Testing:**
- API endpoint testing
- Container orchestration
- Health check validation
- Load balancing verification

## 📚 API Documentation <a name = "api_docs"></a>

### Authentication
```bash
# Create user
POST /v1/api/
{
  "name": "John Doe",
  "email": "john@company.com", 
  "password": "securepassword"
}

# Get API token
POST /v1/api/authentication
{
  "email": "john@company.com",
  "password": "securepassword"
}
```

### Trade Leads Management
```bash
# Create trade lead (authenticated)
POST /v1/trade_leads/
Authorization: Bearer <token>
{
  "title": "Software Development Project",
  "description": "Mobile app development",
  "value": 50000.00
}

# Get tenant's trade leads
GET /v1/trade_leads/
Authorization: Bearer <token>
```

## ⛏️ Built Using <a name = "built_using"></a>

- **[Go 1.23](https://golang.org)** – Backend language with robust concurrency
- **[PostgreSQL 16](https://postgresql.org)** – Relational database with JSON support
- **[NGINX](https://nginx.org)** – Reverse proxy and load balancer
- **[Docker](https://docker.com)** – Containerization platform
- **[GitHub Actions](https://github.com/features/actions)** – CI/CD automation
- **[Goose](https://github.com/pressly/goose)** – Database migration tool
- **[Adminer](https://www.adminer.org/)** – Database administration interface
- **[Prometheus](https://prometheus.io/)** – Monitoring and alerting toolkit
- **[Grafana](https://grafana.com/)** – Analytics and monitoring platform

## ✍️ Authors <a name = "authors"></a>

- [@blue-davinci](https://github.com/Blue-Davinci) - Lead Developer & DevOps Engineer

## 📖 Documentation <a name = "documentation"></a>

### Core Documentation
- **[Deployment Guide](./docs/DEPLOYMENT.md)** - Complete deployment procedures and architecture
- **[Database Schema Management](./docs/DATABASE_SCHEMA_MANAGEMENT.md)** - Automated schema workflow
- **[DevOps Guide](./docs/DEVOPS.md)** - Infrastructure management and best practices
- **[Implementation Summary](./IMPLEMENTATION_SUMMARY.md)** - Technical overview and decisions

### Development & Operations
- **[Script Organization](./docs/SCRIPT_ORGANIZATION.md)** - Script management and organization
- **[Adminer Guide](./docs/ADMINER_GUIDE.md)** - Database administration interface
- **[Security Guide](./docs/SECURITY.md)** - Security implementation and best practices

### Scripts & Automation
- **[Script Manager](./scripts.sh)** - Central script management system
- **[Database Scripts](./scripts/database/)** - Schema and migration automation
- **[Deployment Scripts](./scripts/deployment/)** - Deployment and validation automation
- **[Testing Scripts](./scripts/testing/)** - Automated testing procedures

### Configuration
- **[Environment Configs](./configs/)** - Environment-specific configurations
- **[Docker Compose Files](./docker-compose*.yml)** - Container orchestration
- **[NGINX Configurations](./nginx/)** - Reverse proxy and load balancing

### Security & Compliance
- **Multi-tenant data isolation** at application and database level
- **Bearer token authentication** with API key support
- **Rate limiting and input validation** with comprehensive middleware
- **Container security** with vulnerability scanning and secure configurations
- **Automated schema management** preventing migration conflicts
- **Environment separation** with staging and production isolation
